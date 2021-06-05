source('src/00_libraries_functions.R')

###########################################################
################  Data downloading  #######################
###########################################################

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

###########################################################
################  Data subsetting   #######################
###########################################################


loans <- fread('data/raw/loans.csv')
colnames(loans) <- unlist(lapply(names(loans), function(x) str_to_lower(x)))
loans$funded <- loans$funded_amount==loans$loan_amount
loans$time_to_fund <- as.numeric(as.POSIXct(loans$raised_time)-as.POSIXct(loans$posted_time))

date_subset <- '2020-11-16'
  
df <- loans %>%
  # Country is Philippines
  filter(country_name=="Philippines"
         #, partner_id==145
         # Partner Id is 145
         ) %>%         
  # Posted Date is after 2016-03-01
  filter(to_date(posted_time)==date_subset) %>%
  filter(borrower_genders=="female",  
         # There is only ONE borrower IN THE PICTURE
         borrower_pictured=="true",   
         # The repayment interval is irregular
         repayment_interval=="monthly", 
         # The distribution model is through field partner
         distribution_model=="field_partner",
         # The sector Name is either Agriculture, Food or Retail
         sector_name%in%c("Agriculture","Food","Retail")) 

data.table::fwrite(df, glue::glue('data/processed/loans_subset_{date_subset}.csv'))

print('***************************************************')
print(glue::glue('*** Created  data/processed/loans_subset_{date_subset}.csv ******'))
print('***************************************************')

