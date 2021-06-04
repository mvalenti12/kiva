###########################################################
################  Module importing   ######################
###########################################################

import io
import os
import pandas as pd
import time
import tqdm
import logging
from google.cloud import vision


###########################################################
################  Logger Initiation  ######################
###########################################################

logging.basicConfig(filename=f'tmp/log_google_{time.strftime("%Y%m%d-%H%M%S")}.txt',
                    level=logging.INFO, 
                    format='%(asctime)s %(levelname)s %(name)s %(message)s')
logger=logging.getLogger(__name__)


###########################################################
################  Path description  #######################
###########################################################

IMG_DIR = 'img'
OUTPUT_DIR = 'data/processed/'

###########################################################
################  Authentication    #######################
###########################################################

KEY_PATH = 'secrets/google_cred.json'
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = KEY_PATH

client = vision.ImageAnnotatorClient()


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
files = list(filter(lambda f: f.endswith('_google.csv'), files))

# Iterates over files on already outputted results, adding the loan_ids in the files in the processed_ids set
processed_ids = set()
for file in files:
  df_aux = pd.read_csv(f'{OUTPUT_DIR}{file}')
  processed_ids.update(df_aux['loan_id'].astype(str))
  
###########################################################
################  Images identification    ################
###########################################################

def get_emotions_google(path):
    
    """
    Retrieves the emotions from a local image, based on Google's Computer Vision API.

    Args:
        path: Absolute path of an image.
  
    Returns:
        res: Dictionary with fields loan_id, anger, contempt, disgust, fear, happiness, neutral, sadness, surprise.
    """
    
    # Loads the image into memory
    with io.open(path, 'rb') as image_file:
        content = image_file.read()

    image = vision.Image(content=content)

    response = client.face_detection(image=image)
    
    if response.error.message:
        raise Exception(
            '{}\nFor more info on error messages, check: '
            'https://cloud.google.com/apis/design/errors'.format(
                response.error.message))
                
                
    face = response.face_annotations[0]
    
    # Names of likelihood from google.cloud.vision.enums
    likelihood_name = ('UNKNOWN', 'VERY_UNLIKELY', 'UNLIKELY', 'POSSIBLE',
                       'LIKELY', 'VERY_LIKELY')
  
    res = {'loan_id' : os.path.split(path)[1].replace('.jpg',''),
    'detection_confidence': face.detection_confidence,
    'landmarking_confidence': face.landmarking_confidence,
    'joy_likelihood': format(likelihood_name[face.joy_likelihood]),
    'sorrow_likelihood': format(likelihood_name[face.sorrow_likelihood]),
    'anger_likelihood': format(likelihood_name[face.anger_likelihood]),
    'surprise_likelihood': format(likelihood_name[face.surprise_likelihood]),
    'under_exposed_likelihood': format(likelihood_name[face.under_exposed_likelihood]),
    'blurred_likelihood': format(likelihood_name[face.blurred_likelihood]),
    'headwear_likelihood': format(likelihood_name[face.headwear_likelihood])}
        
    return res

    
# Creates list for storing results
res = []
for file_name in tqdm.tqdm(file_names[0:120]):
  loan_id = os.path.split(file_name)[1].replace('.jpg','')
  
  if (str(loan_id) in processed_ids):
    print('Loan ID {} already processed'.format(str(loan_id)))
  else: 
    out = get_emotions_google(file_name)
    res.append(out)

# Concatenate to DataFrame and write to file  
if len(res)>0:
  df = pd.DataFrame(res)
  filename = OUTPUT_DIR  + time.strftime("%Y%m%d-%H%M%S") + '_google.csv'
  df.to_csv(filename)


