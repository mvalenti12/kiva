rm(list = ls())
source('src/00_libraries_functions.R')
library(magick)

###########################################################
################  Data importing    #######################
###########################################################

DATA_DIR <- 'data/processed'
experiment_id <- 'Colombia_Sep19'
IMG_DIR <- glue::glue('img/{experiment_id}/')

df <- data.table::fread(glue::glue('{DATA_DIR}/loans_emotions_scaled_{experiment_id}.csv')) %>%
  as.data.frame()

for (colname in colnames(df)){
  if (colname != 'loan_id'){
    ecdf_col <- ecdf(df[,colname])
    df[, glue::glue('{colname}')] <- paste0(round(df[, colname],2),
                                                  '\t(',
                                                  scales::percent(ecdf_col(df[, colname])),
                                                  ')')
  }
}

df <- df[,c('loan_id', 
            sort(colnames(df)[!colnames(df) %in% 
                                           c('loan_id', 'first_factor', 'first_factor_manual', 'second_factor', 'second_factor_manual')]),
            c('first_factor', 'first_factor_manual', 'second_factor', 'second_factor_manual'))]

colnames(df) <- str_replace_all(colnames(df), 'first_factor', 'FA1')
colnames(df) <- str_replace_all(colnames(df), 'second_factor', 'FA2')

annotate_image <- function(loan_id, overwrite = FALSE){
  if (file.exists('{IMG_DIR}/{loan_id}_annotated.jpg')&&(overwrite=FALSE)){
    break
    print('returning nothing')
  } else {
    filename <- glue::glue('{IMG_DIR}/{loan_id}.jpg')
    img <- image_read(filename)
    
    obj <- image_draw(img)
    rect(0, 0, 220, 300, border = "black", col = 'white', lwd = 5)
    obj <- image_annotate(obj, 
                          paste0(colnames(df), ':', collapse = '\n'),
                          location = geometry_point(5, 0), 
                          size = 15)
    obj <- image_annotate(obj, 
                          paste0(df[df$loan_id == loan_id,], collapse = '\n'),
                          location = geometry_point(110, 0), 
                          size = 15)
    image_write(obj, 
                path = glue::glue('{IMG_DIR}/{loan_id}_annotated.jpg'),
                format = 'jpg')
    dev.off()
  }
}
for (loan_id in df$loan_id){
  print(loan_id)
  annotate_image(loan_id, overwrite = FALSE)
}
