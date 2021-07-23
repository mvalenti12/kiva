###########################################################
################  Module importing   ######################
###########################################################

import io
import os
import pandas as pd
import time
import tqdm
import logging
import boto3
import json
import sys
from collections import OrderedDict

###########################################################
################  Path description  #######################
###########################################################

# Opening JSON file
f = open('Config/experiments.json')
  
# returns JSON object as  a dictionary
json_experiment = json.load(f)

experiment_id = sys.argv[1]

if experiment_id not in json_experiment:
  raise Exception('experiment_id should be in experiments.json.')

IMG_DIR = 'img/' + experiment_id
OUTPUT_DIR = 'data/processed/'

###########################################################
################  Logger Initiation  ######################
###########################################################

logging.basicConfig(filename=f'tmp/log_aws_{experiment_id}_{time.strftime("%Y%m%d-%H%M%S")}.txt',
                    level=logging.INFO, 
                    format='%(asctime)s %(levelname)s %(name)s %(message)s')
logger=logging.getLogger(__name__)


###########################################################
################  Authentication    #######################
###########################################################

# Open .json with credentials and store them
with open('secrets/aws_cred.json') as data_file:
    data = json.load(data_file)

AWS_ACCESS_KEY = data['AWS_ACCESS_KEY']
AWS_SECRET_KEY =  data['AWS_SECRET_KEY']
AWS_REGION =  data['AWS_REGION']

client = boto3.client('rekognition',
  aws_access_key_id=AWS_ACCESS_KEY,
  aws_secret_access_key=AWS_SECRET_KEY,
  region_name=AWS_REGION)


###########################################################
################  Images identification    ################
###########################################################

# Retrieve all file_names required
file_names = []

# Gets absolute path of all images in directory
for folder, subs, files in os.walk(IMG_DIR):
  for filename in files:
    file_names.append(os.path.abspath(os.path.join(folder, filename)))

# Gets files of already outputted results
files = os.listdir(OUTPUT_DIR)    
files = list(filter(lambda f: f.endswith('_aws.csv'), files))

# Iterates over files on already outputted results, adding the loan_ids in the files in the processed_ids set
processed_ids = set()
for file in files:
  df_aux = pd.read_csv(f'{OUTPUT_DIR}{file}')
  processed_ids.update(df_aux['loan_id'].astype(str))
  
###########################################################
################  Images identification    ################
###########################################################

def get_emotions_aws(path):
    
    """
    Retrieves the emotions from a local image, based on aws's Computer Vision API.

    Args:
        path: Absolute path of an image.
  
    Returns:
        res: Dictionary with fields loan_id, anger, contempt, disgust, fear, happiness, neutral, sadness, surprise.
    """
    
    # Loads the image into memory
    with io.open(path, 'rb') as image_file:
        content = image_file.read()

    response = client.detect_faces(Image={'Bytes': content}, Attributes=['ALL'])
    
    # Retrieves the loan_id
    res = {'loan_id' : os.path.split(file_name)[1].replace('.jpg','')}
    # Retrieves the emotions and updates the dictionary
    try: 
      emotions_keys = [list(item.values())[0] for item in response['FaceDetails'][0]['Emotions']]
      emotions_values = [list(item.values())[1] for item in response['FaceDetails'][0]['Emotions']]
      emotions_dict = OrderedDict(sorted(dict(zip(emotions_keys, emotions_values)).items()))
      res.update(emotions_dict)
      # Retrieves overall confidence
      res['overall_confidence'] = response['FaceDetails'][0]['Confidence']
      # Retrieves age range
      res['age_range_low'] = response['FaceDetails'][0]['AgeRange']['Low']
      res['age_range_high'] = response['FaceDetails'][0]['AgeRange']['Low']
      # Retrieves Bounding Box
      res.update(response['FaceDetails'][0]['BoundingBox'])
      return res
    except:
      logger.exception('No face detected from image {}'.format(path))
    return None

    
# Creates list for storing results
res = []
for file_name in tqdm.tqdm(file_names):
  loan_id = os.path.split(file_name)[1].replace('.jpg','')
  
  if (str(loan_id) in processed_ids):
    print('Loan ID {} already processed'.format(str(loan_id)))
  else: 
    out = get_emotions_aws(file_name)
    print('Loan ID {} processed correctly'.format(str(loan_id)))
    if out is not None:
        res.append(out)
    else:
        print('Loan ID {} had no results'.format(str(loan_id)))

# Concatenate to DataFrame and write to file  
if len(res)>0:
  df = pd.DataFrame(res)
  filename = OUTPUT_DIR  + experiment_id + '_' + time.strftime("%Y%m%d-%H%M%S") + '_aws.csv'
  df.to_csv(filename)


