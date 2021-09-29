if (!require('pacman')) install.packages('pacman')

renv::restore()

pacman::p_load(renv,
               jsonlite, 
               readr,
               data.table, 
               tidyverse,
               dplyr, 
               tibble,
               lubridate,
               stringr,
               reshape2,
               glue,
               rvest,
               httr,
               progress,
               ggplot2)


options(scipen = 999)

to_date <- function(x){
  return(as.Date(as.POSIXct(x,origin='1970-01-01')))
}
