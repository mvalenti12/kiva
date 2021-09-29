## Overview
This repository is a WIP of the paper <paper_name> by Inés Alegre and Marc Valentí.

## Abstract

## Citation

## Full Reproducibility of the Analysis Results

## Installation

First, start by closing the repository:

```
git clone https://github.com/mvalenti12/kiva.git
```

We recommend to use `virtualenv` for development:

- Start by installing `virtualenv` if you don't have it
```
pip install virtualenv
```

- Once installed access the project folder
```
cd kiva_paper
```

- Create a virtual environment
```
virtualenv venv
```

- Enable the virtual environment
```
source venv/bin/activate
```

- Install the python dependencies on the virtual environment
```
pip install -r requirements.txt
```

## Documentation

After having cloned the repository, you can edit the experiment metadata in [Config/experiments.json](https://github.com/mvalenti12/kiva/blob/master/Config/experiments.json) following the defined structure. After having your experiment parameters, you can run on your CML [src/99_main.sh](https://github.com/mvalenti12/kiva/blob/master/src/99_main.sh), which will triger the folloring scripts:
- [01_data_importing.R](https://github.com/mvalenti12/kiva/blob/master/src/01_data_importing.R): Creates the folder structure required and downloads the data from Kiva and saves it under data/raw. Creates a subset to run the analysis, saved under data/processed/loans_subset_{experiment_id}.csv.
- [02_scrap_images.R](https://github.com/mvalenti12/kiva/blob/master/src/02_scrap_images.R): Downloads the images of the loans belonging of your experiment_id and saves every image on the path img/{experiment_id}/{loan_id}.jpg.
- [03_run_img_apis.R](https://github.com/mvalenti12/kiva/blob/master/src/03_run_img_apis.R): Calls different scripts to collect Face Emotions from different sources. All this scripts require authentication (therefore store your credentials on secrets/{API}_cred.json) and installation; for more information check the individual scripts.
  - [0301_img_azure.py](https://github.com/mvalenti12/kiva/blob/master/src/0301_img_azure.py): Passes the images of the loans to Azure's API. Manages ~ 3.4s / call.
  - [0302_img_google.py](https://github.com/mvalenti12/kiva/blob/master/src/0302_img_google.py): Passes the images of the loans to Google's Computer Vision API. Manages ~ 0.6s / call.
  - [0303_img_amz.py](https://github.com/mvalenti12/kiva/blob/master/src/0303_img_amz.py): Passes the images of the loans to Amazon's Computer Vision API. Manages ~ 0.6s / call.
- [04_dataset_preparation.R](https://github.com/mvalenti12/kiva/blob/master/src/04_dataset_preparation.R): Collects the different outputs of the APIs and creates data/processed/loans_subset_enriched_{experiment_id}.csv
- [05_regression_analysis.R](https://github.com/mvalenti12/kiva/blob/master/src/05_regression_analysis.R): Generates additional features, performs Factor Analysis on the FaceExpressions and runs the regression.
- [06_anotate_image.R](https://github.com/mvalenti12/kiva/blob/master/src/06_anotate_image.R): Anotates the different images.
