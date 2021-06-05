rm(list = ls())
source('src/00_libraries_functions.R')

###########################################################
################  Data importing    #######################
###########################################################

DATA_DIR <- 'data/processed'

date_subset <- '2020-11-16'

df <- data.table::fread(glue::glue('{DATA_DIR}/loans_subset_enriched_{date_subset}.csv'))

df <- df %>%
  select(-loan_id) %>%
  filter(status == 'funded') %>%
  as.data.frame() %>%
  select(-G_anger, -G_surprise)

df <- df[rowSums(is.na(df))==0,]
emotions_vars <- colnames(df)[startsWith(names(df),"G_")|startsWith(names(df),"A_")|startsWith(names(df),"M_")]

df_emotions <- df[,names(df) %in% emotions_vars]
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
                           lower = 0.3) 
loadings <- res.MFA$loadings %>%
  unclass() 

res.MFA$loadings

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
       x = "First Factor (26.4%)",
       y = "Second Factor (13.4%)") + 
  geom_path(data = dt_circle,
            aes(x = x,
                y = y))
p

first_factor <- res.MFA$loadings[,1] %*% t(df_emotions_scaled) %>% as.vector()
second_factor <- res.MFA$loadings[,2] %*% t(df_emotions_scaled) %>% as.vector()

df_final <- df %>%
  select(loan_amount,
         sector_name,
         status,
         time_to_fund) %>%
  mutate(first_factor = first_factor,
         second_factor = second_factor) %>%
  filter(status == 'funded') %>%
  select(-status)

ggplot(df_final,
       aes(x = time_to_fund)) + 
  geom_density()
ggplot(df_final,
       aes(x = time_to_fund,
           y = loan_amount)) + 
  geom_point() + 
  geom_smooth(method = "lm") + 
  scale_x_log10() + 
  scale_y_log10()

res_lm <- lm(log(time_to_fund) ~ loan_amount^2 + sector_name + first_factor + second_factor,
             data = df_final)
res_lm$aic <- AIC(res_lm)
res_lm$bic <- BIC(res_lm)
summary(res_lm)
plot(res_lm)

