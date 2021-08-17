rm(list = ls())
source('src/00_libraries_functions.R')

###########################################################
################  Data importing    #######################
###########################################################
args = commandArgs(trailingOnly=TRUE)


# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  experiment_id = 'Colombia_Sep19'
  #stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  experiment_id = args[1]
}

params_file <- jsonlite::fromJSON('Config/experiments.json')
params <- params_file[[experiment_id]]

IMG_DIR <- glue::glue('img/{experiment_id}')

DATA_DIR <- 'data/processed'


df <- data.table::fread(glue::glue('{DATA_DIR}/loans_subset_enriched_{experiment_id}.csv'))
df <- df %>%
  filter(partner_id == params$partner_id)

df <- df[df$G_confidence >= quantile(df$G_confidence, 0.3),]
df <- df[df$A_confidence >= quantile(df$A_confidence, 0.3),]

df$D_tags_N <- stringr::str_extract_all(df$tags, '\\#') %>% sapply(length)
df$D_tags_N <- df$D_tags_N>0
df$D_tags_N <- df$D_tags_N * 1
df$D_tags_UF <- str_detect(df$tags, 'user_favorite') * 1


df <- df %>%
  # filter(status == 'funded',
  #        partner_id == 145) %>%
  as.data.frame() %>%
  select(-G_anger, -G_surprise, -G_blurred, -A_calm, -A_fear, -A_confused, -A_disgusted, -A_surprised, -A_angry, -G_confidence, -A_confidence) 


df$D_is_married <- df$description_translated %>% str_detect(pattern = 'married')
df$D_is_widow <- df$description_translated %>% str_detect(pattern = 'widow')
df$D_is_single <- df$description_translated %>% str_detect(pattern = 'single')
df$D_age <- df$description_translated %>% str_extract_all(pattern = '([0-9]{2}-year-old)|([0-9]{2} years old)') %>%
  as.vector() %>% str_extract_all(pattern = '[0-9]{2}') %>% as.numeric()

# TODO: get either written age or Name, Age, ....
# df$description_translated[is.na(df$D_age)]

df$D_children_text <- df$description_translated %>% str_extract_all(pattern = '[a-z]{1,10} child') %>%
  as.vector() %>% str_replace_all(pattern = 'child', '')

df$D_children <- df$description_translated %>% str_extract_all(pattern = '[0-9]{1,10} child') %>%
  as.vector() %>% str_replace_all(pattern = 'child', '') %>% as.numeric()

df$D_children[df$D_children_text %>% str_detect('one')] <- 1
df$D_children[df$D_children_text %>% str_detect('two')] <- 2
df$D_children[df$D_children_text %>% str_detect('three')] <- 3
df$D_children[df$D_children_text %>% str_detect('four')] <- 4
df$D_children[df$D_children_text %>% str_detect('five')] <- 5
df$D_children[df$D_children_text %>% str_detect('six')] <- 6
df$D_children[df$D_children_text %>% str_detect('seven')] <- 7
df$D_children[df$D_children_text %>% str_detect('eight')] <- 8
df$D_children[df$D_children_text %>% str_detect('nine')] <- 9
df$D_children[df$D_children_text %>% str_detect('ten')] <- 10
df$D_children[df$D_children_text %>% str_detect('eleven')] <- 11
df$D_children[df$D_children_text %>% str_detect('twelve')] <- 12
df$D_children[is.na(df$D_children)] <- 0

df$D_years_exp <- df$description_translated %>% str_extract_all(pattern = 'business for [0-9]{1,3} years ') %>%
  as.vector() %>% str_extract_all(pattern = '[0-9]{1,3}', '') %>% as.numeric()

df$D_years_exp_text <- df$description_translated %>% str_extract_all(pattern = 'business for [a-z]{1,10} years ')
df$D_years_exp <- 0L
df$D_years_exp[df$D_years_exp_text %>% str_detect('one')] <- 1
df$D_years_exp[df$D_years_exp_text %>% str_detect('two')] <- 2
df$D_years_exp[df$D_years_exp_text %>% str_detect('three')] <- 3
df$D_years_exp[df$D_years_exp_text %>% str_detect('four')] <- 4
df$D_years_exp[df$D_years_exp_text %>% str_detect('five')] <- 5
df$D_years_exp[df$D_years_exp_text %>% str_detect('six')] <- 6
df$D_years_exp[df$D_years_exp_text %>% str_detect('seven')] <- 7
df$D_years_exp[df$D_years_exp_text %>% str_detect('eight')] <- 8
df$D_years_exp[df$D_years_exp_text %>% str_detect('nine')] <- 9
df$D_years_exp[df$D_years_exp_text %>% str_detect('ten')] <- 10
df$D_years_exp[df$D_years_exp_text %>% str_detect('eleven')] <- 11
df$D_years_exp[df$D_years_exp_text %>% str_detect('twelve')] <- 12

df$D_nchar <- df$description_translated %>% nchar()

df$D_age_bin <- '0 - Missing'
df$D_age_bin[between(df$D_age,0,34)] <- '18-34'
df$D_age_bin[between(df$D_age,35,49)] <- '35-49'
df$D_age_bin[between(df$D_age,50,64)] <- '50-64'
df$D_age_bin[between(df$D_age,65,999)] <- '65+'
df$D_age <- NULL

df$day_of_week <- weekdays(as.Date(df$posted_time))


colSums(is.na(df))
df <- df[rowSums(is.na(df))==0,]
emotions_vars <- colnames(df)[startsWith(names(df),"G_")|startsWith(names(df),"A_")|startsWith(names(df),"M_")]

df_emotions <- df[,names(df) %in% emotions_vars]
emotions_var <- sort(apply(df_emotions,2,mean), decreasing = TRUE)[1:10] %>% names()
df_emotions <- df_emotions[names(df_emotions) %in% emotions_var]
df_emotions_scaled <- scale(df_emotions,
                            center = TRUE,
                            scale = TRUE)

prcomp_res <- prcomp(df_emotions,
                     scale = TRUE)
biplot(prcomp_res)

plot(prcomp_res)

res.MFA <- FactoMineR::MFA(base = df_emotions_scaled,
                           group = c(2,8,8),
                           type = rep("s",length(c(2,8,8))),
                           ind.sup = NULL,
                           name.group = c("Google","Microsoft",'Amazon'),
                           num.group.sup = NULL,
                           graph = FALSE)



res.MFA <- stats::factanal(x = df_emotions_scaled,
                           factors = 2,
                           rotation = "varimax",
                           lower = 0.8) 
loadings <- res.MFA$loadings %>%
  unclass() 

res.MFA$loadings

x <- loadings(res.MFA)
vx <- colSums(x^2)

loadings_explained_variance <- rbind(`SS loadings` = vx,
      `Proportion Var` = vx/nrow(x),
      `Cumulative Var` = cumsum(vx/nrow(x)))

loadings_dt <- loadings %>%
  as.data.frame() %>%
  rownames_to_column(var = "factor")

circleFun <- function(center = c(0,0),diameter = 1, npoints = 100){
  r = diameter / 2
  tt <- seq(0,2*pi,length.out = npoints)
  xx <- center[1] + r * cos(tt)
  yy <- center[2] + r * sin(tt)
  return(data.frame(x = xx, y = yy))
}

dt_circle <- circleFun(diameter = 2,npoints = 100)

res.MFA$loadings

p <- ggplot() + 
  geom_text(data = loadings_dt,
            aes (x = Factor1,
                 y = Factor2,
                 label = factor),
            nudge_y = 0.1) +
  geom_segment(data = loadings_dt,
               aes (x = 0,
                    xend = Factor1,
                    y = 0,
                    yend = Factor2),
               size = 0.5,
               arrow = arrow()) +
  scale_x_continuous(limits = c(-1.1,1.1)) + 
  scale_y_continuous(limits = c(-1.1,1.1)) +
  labs(title = "Exploratory Factor Analysis: Loadings",
       x = glue::glue('First Factor ({loadings_explained_variance[rownames(loadings_explained_variance) == "Proportion Var","Factor1"] %>% scales::percent(accuracy = 0.1)})'),
       y = glue::glue('Second Factor ({loadings_explained_variance[rownames(loadings_explained_variance) == "Proportion Var","Factor2"] %>% scales::percent(accuracy = 0.1)})')) + 
  geom_path(data = dt_circle,
            aes(x = x,
                y = y))
p
corrplot::corrplot(cor(df_emotions_scaled), 
                   method = 'color', 
                   addCoef.col="grey",
                   type = 'upper')

first_factor <- res.MFA$loadings[,1] %*% t(df_emotions_scaled) %>% as.vector()
#first_factor <- df$G_joy + df$M_happiness + df$A_happy
second_factor <- res.MFA$loadings[,2] %*% t(df_emotions_scaled) %>% as.vector()

df_emotions_scaled_df <- df_emotions_scaled %>% as.data.frame()
first_factor_manual <- df_emotions_scaled_df$G_joy + df_emotions_scaled_df$M_happiness + df_emotions_scaled_df$A_happy 
second_factor_manual <- df_emotions_scaled_df$G_sorrow + df_emotions_scaled_df$M_sadness + df_emotions_scaled_df$A_sad 


generate_mosaic <- function(loan_ids, output_file){
  img_files <- paste0(IMG_DIR, loan_ids, '.jpg') %>% sample(16)
  magick::image_read(img_files) %>%
    magick::image_montage(tile = '4x4', geometry = '0x100+0+0', shadow = FALSE) %>%
    magick::image_write(
      format = "jpg", path = paste0(IMG_DIR, output_file),
      quality = 100
    )
}

generate_mosaic(df$loan_id[which(first_factor >= sort(first_factor, decreasing = TRUE)[16])],
                'first_factor_top.jpg')
generate_mosaic(df$loan_id[which(first_factor <= sort(first_factor, decreasing = FALSE)[16])],
                'first_factor_bottom.jpg')


hist(df$loan_amount)

df_final <- df %>%
  mutate(first_factor = first_factor,
         second_factor = second_factor) %>%
  filter(status == 'funded') %>%
  select(-status)

df_final %>%
  ggplot(aes(x = as.Date(posted_time),
             group = as.Date(posted_time),
             col = as.factor(day_of_week),
             y = log(time_to_fund))) + 
  geom_boxplot()

ggplot(df_final,
       aes(x = time_to_fund)) + 
  labs(title = 'Time to fund (days)',
       x = 'Days') +
  geom_density()
ggplot(df_final,
       aes(x = log(time_to_fund),
           y = log(loan_amount))) + 
  geom_point() + 
  geom_smooth(method = "lm") 

res_lm <- lm(log(time_to_fund) ~ 
               + log(loan_amount) 
               + first_factor 
               + second_factor 
               + sector_name 
               + day_of_week 
               # D_age_bin + 
               # D_children + 
               + D_is_married
               + D_is_widow 
               + D_is_single 
               # + D_years_exp 
               + D_tags_N 
               + D_tags_UF
             ,data = df_final)
res_lm$aic <- AIC(res_lm)
res_lm$bic <- BIC(res_lm)
summary(res_lm)
plot(res_lm)


