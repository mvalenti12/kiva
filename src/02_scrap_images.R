rm(list = ls())
source('src/00_libraries_functions.R')
print('Running src/02_scrap_images.R')

args = commandArgs(trailingOnly=TRUE)
params_file <- jsonlite::fromJSON('Config/experiments.json')

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  experiment_id = args[1]
  if (!experiment_id %in% names(params_file)){
    valid_names <- paste0(names(params_file), collapse = '\n\t')
    stop(glue::glue("A valid experiment id must be provided. \nPlease provide any of: \n\t{valid_names}"), call.=FALSE)
  }
}


params <- params_file[[experiment_id]]

IMG_DIR <- glue::glue('img/{experiment_id}')
if (!dir.exists(IMG_DIR)){
  dir.create(IMG_DIR)
}


# Data importing
df <- data.table::fread(glue::glue('data/processed/loans_subset_{experiment_id}.csv'))


get_image_link <- function(x){
  url <- paste0("https://www.kiva.org/lend/",x) 
  link <- read_html(url) %>%
    html_nodes(xpath = '//*[@class="borrower-image"]') %>%
    html_attr('srcset') %>%
    str_extract(pattern = "https://.*.jpg")

  if(!identical(link,character(0))){
    download.file(link,
                  glue::glue('{IMG_DIR}/{x}.jpg'), mode = 'wb')
  } else {
    return(NA)
  }
}

# Vector of files to be scrapped
total <- df$loan_id[!df$loan_id %in% (list.files(IMG_DIR, '.jpg') 
                                      %>% str_replace_all('.jpg',''))] 
total <- length(total)

print(glue::glue('Total Number of images to scrap: {total}'))

start_loop <- function(){
  # Creation of progress bar
  pb <- progress_bar$new(
    format = "  downloading [:bar] :percent in :elapsed",
    total = total, clear = FALSE)
  
  ###########################################################
  ################  Image Downloading  ######################
  ###########################################################
  
  for (loan_id in df$loan_id){
    
    if (!loan_id %in% (list.files(IMG_DIR, '.jpg') %>% str_replace_all('.jpg',''))){
      pb$tick()
      get_image_link(loan_id)
      Sys.sleep(5)
    }
  }
  break
}

if (total > 0){
  for (i in 1:10){
    # In case the loop breaks, it will sleep for 60 seconds
    print(i)
    start_loop()
    Sys.sleep(60)
  }
}
beepr::beep(3)


