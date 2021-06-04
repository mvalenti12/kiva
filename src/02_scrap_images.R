source('src/00_libraries_functions.R')

# Data importing
df <- data.table::fread('data/processed/loans_subset.csv')


get_image_link <- function(x){
  url <- paste0("https://www.kiva.org/lend/",x) 
  link <- read_html(url) %>%
    html_nodes(xpath = '//*[@class="borrower-image"]') %>%
    html_attr('srcset') %>%
    str_extract(pattern = "https://.*.jpg")

  if(!identical(link,character(0))){
    download.file(link,
                  glue::glue('img/{x}.jpg'), mode = 'wb')
  } else {
    return(NA)
  }
}

# Vector of files to be scrapped
total <- df$loan_id[!df$loan_id %in% (list.files('img', '.jpg') 
                                      %>% str_replace_all('.jpg',''))] 
total <- length(total)


# Creation of progress bar
pb <- progress_bar$new(
  format = "  downloading [:bar] :percent in :elapsed",
  total = total, clear = FALSE)

###########################################################
################  Image Downloading  ######################
###########################################################

for (loan_id in df$loan_id){
  
  if (!loan_id %in% (list.files('img', '.jpg') %>% str_replace_all('.jpg',''))){
    pb$tick()
    get_image_link(loan_id)
    Sys.sleep(15)
  }
}
close(pb)

