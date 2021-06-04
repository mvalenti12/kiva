###########################################################
################  Module importing   ######################
###########################################################

import asyncio
import io
import glob
import os
import sys
import time
import uuid
import requests
import tqdm
import pandas as pd
from urllib.parse import urlparse
from io import BytesIO
from PIL import Image, ImageDraw
from azure.cognitiveservices.vision.face import FaceClient
from msrest.authentication import CognitiveServicesCredentials
from azure.cognitiveservices.vision.face.models import TrainingStatusType, Person
import json
import logging

###########################################################
################  Logger Initiation  ######################
###########################################################

logging.basicConfig(filename=f'tmp/log_msft_{time.strftime("%Y%m%d-%H%M%S")}.txt',
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

# Open .json with credentials and store them
with open('secrets/msft_cred.json') as data_file:
    data = json.load(data_file)

KEY = data['KEY']
ENDPOINT =  data['ENDPOINT']

# Create an authenticated FaceClient.
face_client = FaceClient(ENDPOINT, CognitiveServicesCredentials(KEY))

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
files = list(filter(lambda f: f.endswith('_msft.csv'), files))

# Iterates over files on already outputted results, adding the loan_ids in the files in the processed_ids set
processed_ids = set()
for file in files:
  df_aux = pd.read_csv(f'{OUTPUT_DIR}{file}')
  processed_ids.update(df_aux['loan_id'].astype(str))
  
###########################################################
################  Images identification    ################
###########################################################

def get_emotions_msft(path):
  """
  Retrieves the emotions from a local image, based on Microsoft Azure's Computer Vision API.

  Args:
      path: Absolute path of an image.
  
  Returns:
      res: Dictionary with fields loan_id, anger, contempt, disgust, fear, happiness, neutral, sadness, surprise.
  
  """
  time.sleep(3) # it is limited to 20 calls/minute
  # BufferedReader
  image = open(path, 'rb') 
  
  detected_faces = face_client.face.detect_with_stream(image,return_face_attributes=['emotion'])
  
  try:
    detected_faces[0]
  except:
    logger.exception('No face detected from image {}'.format(path))
    return None
      
  if len(detected_faces) > 1:
    logger.exception('More than 2 faces in image {}'.format(path))
    return None
      
  emoObject = detected_faces[0].face_attributes.emotion
  
  res = {'loan_id' : os.path.split(file_name)[1].replace('.jpg',''),
  'anger': emoObject.anger,
  'contempt': emoObject.contempt,
  'disgust': emoObject.disgust,
  'fear': emoObject.fear,
  'happiness': emoObject.happiness,
  'neutral': emoObject.neutral,
  'sadness': emoObject.sadness,
  'surprise' : emoObject.surprise}
  
  return res

# Creates list for storing results
res = []
for file_name in tqdm.tqdm(file_names[0:70]):
  
  # Extracts loan_id from image name
  loan_id = os.path.split(file_name)[1].replace('.jpg','')
  
  if (str(loan_id) in processed_ids):
    logger.info('Loan ID {} already processed'.format(str(loan_id)))
  else: 
      out = get_emotions_msft(file_name)
      if out is not None:
        res.append(out)

# Concatenate to DataFrame and write to file  
if len(res)>0:
  df = pd.DataFrame(res)
  filename = OUTPUT_DIR  + time.strftime("%Y%m%d-%H%M%S") + '_msft.csv'
  df.to_csv(filename)

