RScript src/01_data_importing.R "$1" && 
RScript src/02_scrap_images.R "$1" && 
sh src/03_run_img_apis.sh "$1" && 
RScript src/04_dataset_preparation.R "$1" &&
RScript src/05_regression_analysis.R "$1"