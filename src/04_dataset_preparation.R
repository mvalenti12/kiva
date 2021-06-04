source('src/00_libraries_functions.R')

###########################################################
################  Data importing    #######################
###########################################################

DATA_DIR <- 'data/processed'
files_msft <- list.files(DATA_DIR, pattern = '_msft.csv', full.names = TRUE)
files_google <- list.files(DATA_DIR, pattern = '_google.csv', full.names = TRUE)
df_msft <- rbindlist(lapply(files_msft, fread)) %>% as.data.frame() %>% select(-V1)
df_google <- rbindlist(lapply(files_google, fread)) %>% as.data.frame() %>% select(-V1)

###########################################################
################  Data cleaning : Google    ###############
###########################################################

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

df_google <- df_google %>%
  select(-blurred_likelihood, -headwear_likelihood, -under_exposed_likelihood) %>%
  mutate(loan_id = as.factor(loan_id))

df_google[,endsWith(names(df_google), '_likelihood')] <- apply(df_google[,endsWith(names(df_google), '_likelihood')],
                                                               1:2,
                                                               function(x) google_factor_to_numeric(x))

colnames(df_google)[endsWith(names(df_google), '_likelihood')] <- paste0('G_',
colnames(df_google[,endsWith(names(df_google), '_likelihood')]) %>%
  str_replace_all('_likelihood','')) 

###########################################################
################  Data cleaning : Microsoft    ############
###########################################################

