source('src/00_libraries_functions.R')

###########################################################
################  Data downloading  #######################
###########################################################

if (!file.exists('data/raw/kiva_ds_csv.zip')){
  data_source <- 'http://s3.kiva.org/snapshots/kiva_ds_csv.zip'
  print('***************************************************')
  print('****************  Downloading data ****************')
  
  system('mkdir data')
  system('mkdir data/raw ')
  
  system(glue('cd data/raw && curl -O {data_source}'))
  system(glue('cd data/raw && unzip kiva_ds_csv.zip'))
  
  print('***************************************************')
  print('**********  Data has been downloaded **************')
  print('***************************************************')
  
  system(glue('ls -l data/raw'))
}

###########################################################
################  Data subsetting   #######################
###########################################################
params_file <- jsonlite::fromJSON('Config/experiments.json')

loans <- fread('data/raw/loans.csv')
colnames(loans) <- unlist(lapply(names(loans), function(x) str_to_lower(x)))
loans$funded <- loans$funded_amount==loans$loan_amount
loans$time_to_fund <- as.numeric(as.POSIXct(loans$raised_time)-as.POSIXct(loans$posted_time))

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  experiment_id = args[1]
  if (!experiment_id %in% names(params_file)){
    stop("A valid experiment id must be provided", call.=FALSE)
  }
}

params <- params_file[[experiment_id]]

df <- loans %>%
  # Country is Philippines
  filter(country_name==params$country
         #, partner_id==145
         # Partner Id is 145
         ) %>%         
  # Posted Date is after 2016-03-01
  filter(to_date(posted_time) >= params$date_start,
         to_date(posted_time) <= params$date_end) %>%
  filter(borrower_genders=="female",  
         # There is only ONE borrower IN THE PICTURE
         borrower_pictured=="true",   
         # The repayment interval is irregular
         repayment_interval=="monthly", 
         # The distribution model is through field partner
         #distribution_model=="field_partner",
         # The sector Name is either Agriculture, Food or Retail
         sector_name%in%c("Agriculture","Food","Retail")) 

data.table::fwrite(df, glue::glue('data/processed/loans_subset_{experiment_id}.csv'))

print('***************************************************')
print(glue::glue('*** Created  data/processed/loans_subset_{experiment_id}.csv ******'))
print('***************************************************')

