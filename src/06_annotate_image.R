rm(list = ls())
source('src/00_libraries_functions.R')
library(magick)

###########################################################
################  Data importing    #######################
###########################################################

DATA_DIR <- 'data/processed'
date_subset = '2019-01-18'
country_subset = "Peru"
IMG_DIR <- glue::glue('img/{date_subset}_{country_subset}/')

df <- data.table::fread(glue::glue('{DATA_DIR}/loans_subset_enriched_{date_subset}.csv'))

file <- df$loan_id[1]

filename <- glue::glue('{IMG_DIR}{file}.jpg' )
img <- image_read(filename)
df[df$loan_id == file,]

image_annotate(img, "Some text", location = geometry_point(100, 200), size = 90)

                                            