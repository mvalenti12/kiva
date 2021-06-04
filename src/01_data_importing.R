source('src/00_libraries_functions.R')

###########################################################
################  Data downloading  #######################
###########################################################

data_source <- 'http://s3.kiva.org/snapshots/kiva_ds_csv.zip'
print('***************************************************')
print('****************  Downloading data ****************')

system(glue('curl {data_source} -O'))

print('***************************************************')
print('**********  Data has been downloaded **************')
print('***************************************************')

###########################################################
################  Data subsetting   #######################
###########################################################


loans <- fread('data/raw/loans.csv')
colnames(loans) <- unlist(lapply(names(loans), function(x) str_to_lower(x)))
loans$funded <- loans$funded_amount==loans$loan_amount
  
df <- loans %>%
  # Country is Philippines
  filter(country_name=="Philippines"
         #, partner_id==145
         # Partner Id is 145
         ) %>%         
  # Posted Date is after 2016-03-01
  filter(to_date(posted_time)=='2021-02-26') %>%
  filter(borrower_genders=="female",  
         # There is only ONE borrower IN THE PICTURE
         borrower_pictured=="true",   
         # The repayment interval is irregular
         repayment_interval=="monthly", 
         # The distribution model is through field partner
         distribution_model=="field_partner",
         # The sector Name is either Agriculture, Food or Retail
         sector_name%in%c("Agriculture","Food","Retail")) 

data.table::fwrite(df, 'data/processed/loans_subset.csv')

print('***************************************************')
print('*** Created  data/processed/loans_subset.csv ******')
print('***************************************************')