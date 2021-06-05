rm(list = ls())
source('src/00_libraries_functions.R')

###########################################################
################  Data importing    #######################
###########################################################

DATA_DIR <- 'data/processed'

date_subset <- '2020-11-16'

import_data <- function(source, confidence_cutoff = 0){
  if (!source %in% c('aws','google','msft')){
    stop("Source must be either 'aws', 'google' or 'msft'.")
  }
  files <- list.files(DATA_DIR, pattern = glue::glue('_{source}.csv'), full.names = TRUE)
  df <- rbindlist(lapply(files, fread)) %>% as.data.frame() %>% select(-V1)
  
  if (source == 'aws'){
    df <- janitor::clean_names(df)
    v_emotions <- c('happy', 'fear', 'confused', 'disgusted', 'surprised', 'angry', 'calm', 'sad')
    dim1 <- nrow(df)
    df <- df %>%
      mutate(loan_id = as.factor(loan_id)) %>%
      filter(overall_confidence > confidence_cutoff) %>%
      select(loan_id, v_emotions)
    dim2 <- nrow(df)
    print(glue::glue('{dim1 - dim2} ({dim1} to {dim2}) rows eliminated due to confidence lower than {confidence_cutoff}'))
    df[, v_emotions] <- df[, v_emotions]/100
    colnames(df)[colnames(df) %in% v_emotions] <- paste0('A_', colnames(df)[colnames(df) %in% v_emotions])
  } 
  else if (source == 'google') {
    df <- janitor::clean_names(df)
    
    google_factor_to_numeric <- function(x){
      if (is.na(x)){
        return(NA)
      } else if (x=="VERY_UNLIKELY") {
        return(0)
      } else if (x=="UNLIKELY") {
        return(0.25)
      } else if (x=="POSSIBLE") {
        return(0.5)
      } else if (x=="LIKELY") {
        return(0.75)
      } else if (x=="VERY_LIKELY") {
        return(1)
      } else {
        return(NA)
      }
    }
    dim1 <- nrow(df)
    df <- df %>%
      select(-blurred_likelihood, -headwear_likelihood, -under_exposed_likelihood) %>%
      mutate(loan_id = as.factor(loan_id)) %>%
      filter(detection_confidence > confidence_cutoff) %>%
      select(-detection_confidence, -landmarking_confidence)
    dim2 <- nrow(df)
    print(glue::glue('{dim1 - dim2} ({dim1} to {dim2}) rows eliminated due to confidence lower than {confidence_cutoff}'))
    
    df[,endsWith(names(df), '_likelihood')] <- apply(df[,endsWith(names(df), '_likelihood')],
                                                                   1:2,
                                                                   function(x) google_factor_to_numeric(x))
    
    colnames(df)[endsWith(names(df), '_likelihood')] <- paste0('G_',
                                                               colnames(df[,endsWith(names(df), '_likelihood')]) %>%
                                                                 str_replace_all('_likelihood','')) 
    
  }
  else if (source == 'msft'){
    df <- df %>%
      mutate(loan_id = as.factor(loan_id))
    colnames(df)[names(df) != 'loan_id'] <- paste0('M_',
                                                   colnames(df)[names(df) != 'loan_id'])
    
  }
  return(df)
}

df_google <- import_data('google')
df_msft <- import_data('msft')
df_aws <- import_data('aws')


df <- data.table::fread(glue::glue('{DATA_DIR}/loans_subset_{date_subset}.csv')) %>%
  mutate(loan_id = as.factor(loan_id)) %>%
  select(loan_id, funded_amount, loan_amount, status, num_lenders_total, activity_name, sector_name, posted_time, raised_time, tags)
df$time_to_fund <- as.numeric(as.POSIXct(df$raised_time)-as.POSIXct(df$posted_time))

df <- df %>%
  left_join(df_google, by = 'loan_id') %>%
  left_join(df_msft, by = 'loan_id') %>%
  left_join(df_aws, by = 'loan_id')



data.table::fwrite(df, file = glue::glue('{DATA_DIR}/loans_subset_enriched_{date_subset}.csv'))
