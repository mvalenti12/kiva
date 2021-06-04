#required libraries
#data importing
library(jsonlite) 
library(readr) 
library(data.table)
#data manipulation
library(dplyr) 
library(tibble) #rownames_to_column
library(lubridate)
library(stringr)
library(reshape2)
library(glue)
#web scrapping
library(rvest)
library(tidyverse)
library(httr)

library(progress)


options(scipen = 999)

to_date <- function(x){
  return(as.Date(as.POSIXct(x,origin='1970-01-01')))
}
