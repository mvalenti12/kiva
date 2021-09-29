source('src/00_libraries_functions.R')
print('Running src/01_data_importing.R')
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

args = commandArgs(trailingOnly=TRUE)

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

if (!file.exists(glue::glue('data/processed/loans_subset_{experiment_id}.csv'))){
  print('Loading loans data')
  loans <- fread('data/raw/loans.csv')
  print(glue::glue('Loans data has been loaded. Number of rows = {nrow(loans)}'))
  colnames(loans) <- unlist(lapply(names(loans), function(x) str_to_lower(x)))
  loans$funded <- loans$funded_amount==loans$loan_amount
  loans$time_to_fund <- as.numeric(as.POSIXct(loans$raised_time)-as.POSIXct(loans$posted_time))
  
  params <- params_file[[experiment_id]]
  
  df <- loans
  if (!is.na(params$country)){
    shape_0 <- nrow(df)
    df <- df %>%
      filter(country_name==params$country
             #, partner_id==145
             # Partner Id is 145
      ) 
    shape_1 <- nrow(df)
    print(glue::glue('Number of rows before/after filtering for country: {shape_0} -> {shape_1}'))
  }
  
  if (!is.na(params$date_start)){
    shape_0 <- nrow(df)
    df <- df %>%
      filter(to_date(posted_time) >= params$date_start,
             to_date(posted_time) <= params$date_end)
    shape_1 <- nrow(df)
    print(glue::glue('Number of rows before/after filtering for time period: {shape_0} -> {shape_1}'))
  }
  
  if (!is.na(params$partner_id)){
    shape_0 <- nrow(df)
    df <- df %>%
      filter(partner_id == params$partner_id)
    shape_1 <- nrow(df)
    print(glue::glue('Number of rows before/after filtering for partner_ID: {shape_0} -> {shape_1}'))
  }
  
  if (!is.na(params$sector_name)){
    shape_0 <- nrow(df)
    df <- df %>%
      filter(sector_name%in%params$sector_name[[1]])
    shape_1 <- nrow(df)
    print(glue::glue('Number of rows before/after filtering for sector name: {shape_0} -> {shape_1}'))
  }
  
  shape_0 <- nrow(df)
  df <- df %>%
    filter(borrower_genders=="female",  
           # There is only ONE borrower IN THE PICTURE
           borrower_pictured=="true",   
           # The repayment interval is irregular
           repayment_interval=="monthly") 
  shape_1 <- nrow(df)
  print(glue::glue('Number of rows before/after filtering for single female borrower: {shape_0} -> {shape_1}'))
  
  
  data.table::fwrite(df, glue::glue('data/processed/loans_subset_{experiment_id}.csv'))
  
  print('***************************************************')
  print(glue::glue('*** Created  data/processed/loans_subset_{experiment_id}.csv ******'))
  print(glue::glue('*** Number of rows is {nrow(df)} ******'))
  print('***************************************************')
  
  
  
}
