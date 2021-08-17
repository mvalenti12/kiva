rm(list = ls())
source('src/00_libraries_functions.R')
args = commandArgs(trailingOnly=TRUE)


# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  experiment_id = args[1]
}

params_file <- jsonlite::fromJSON('Config/experiments.json')
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
  close(pb)
}

for (i in 1:10){
  print(i)
  start_loop()
  Sys.sleep(60)
}
beepr::beep(3)


