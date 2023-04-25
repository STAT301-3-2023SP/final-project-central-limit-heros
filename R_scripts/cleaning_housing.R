# load pacakges
library(tidyverse)
library(tidymodels)
library(zipcodeR)

# handle common conflicts
tidymodels_prefer()

# load outcome variable
outcome <- read_csv("data/raw/gay-ta.csv") %>% 
  janitor::clean_names() %>% 
  transmute(zip_code = as.numeric(geoid10), index = totindex)

# load predictor variables
predictors <- read_csv("data/raw/ACSDP5Y2021.DP04-Data.csv", na = c("", "-", "NA", "null")) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_sub(name, 7, 100)) %>% 
  mutate(across(where(is.character), as.numeric)) %>% 
  select(-geo_id, -name)

naniar::miss_var_summary(predictors) %>% 
  filter(pct_miss < 100 & pct_miss > 1) %>% 
  View()

# joined data
data <- outcome %>% 
  inner_join(predictors, by = "zip_code")

not_matching <- outcome %>% 
  anti_join(predictors) %>% 
  pull(zip_code)

map_df(not_matching, reverse_zipcode)

# lasso model test
lasso_spec <-
  linear_reg(penalty = 0.05, mixture = 1) %>%
  set_engine('glmnet')

rec <-
  recipe(index ~ ., data = data) %>% 
  update_role(zip_code, new_role = "identifier") %>% 
  step_zv(all_predictors()) %>%
  step_impute_knn(all_predictors()) %>% 
  step_normalize(all_predictors())

lasso_wflow <-
  workflow() %>% 
  add_model(lasso_spec) %>% 
  add_recipe(rec)

lasso_fit <- fit(lasso_wflow, data)

relevant_predictors <- tidy(lasso_fit) %>% 
  filter(estimate != 0 & term != "(Intercept)") %>% 
  pull(term) %>% 
  str_c(collapse = " + ")

# lm test
lm_spec <-
  linear_reg() %>%
  set_engine('lm')

rel_vars_rec <-
  recipe(index ~ dp04_0001m + dp04_0006m + dp04_0007e + dp04_0007m + dp04_0008m + dp04_0013e + dp04_0017e + dp04_0020e + dp04_0021e + dp04_0021m + dp04_0022m + dp04_0026e + dp04_0026m + dp04_0027m + dp04_0029e + dp04_0035m + dp04_0037e + dp04_0037m + dp04_0038m + dp04_0039e + dp04_0042m + dp04_0044e + dp04_0048e + dp04_0056e + dp04_0064e + dp04_0065m + dp04_0066m + dp04_0069e + dp04_0069m + dp04_0071m + dp04_0073e + dp04_0074e + dp04_0078m + dp04_0079e + dp04_0087m + dp04_0088m + dp04_0108e + dp04_0111m + dp04_0112e + dp04_0113e + dp04_0115e + dp04_0116e + dp04_0116m + dp04_0121m + dp04_0124e + dp04_0124m + dp04_0127m + dp04_0128e + dp04_0132e + dp04_0133e + dp04_0140m + dp04_0142e + dp04_0143e + dp04_0010pe + dp04_0011pe + dp04_0012pe + dp04_0020pe + dp04_0022pe + dp04_0026pe + dp04_0029pe + dp04_0040pe + dp04_0044pe + dp04_0051pe + dp04_0060pe + dp04_0061pe + dp04_0065pe + dp04_0068pe + dp04_0070pe + dp04_0079pe + dp04_0084pe + dp04_0085pe + dp04_0088pe + dp04_0091pe + dp04_0092pe + dp04_0095pe + dp04_0103pe + dp04_0104pe + dp04_0104pm + dp04_0111pe + dp04_0113pe + dp04_0113pm + dp04_0115pm + dp04_0118pe + dp04_0121pe + dp04_0124pe + dp04_0124pm + dp04_0130pe + dp04_0138pe + dp04_0141pe, data = data) %>% 
  step_zv(all_predictors()) %>%
  step_impute_knn(all_predictors()) %>% 
  step_normalize(all_predictors())

lm_wflow <-
  workflow() %>% 
  add_model(lm_spec) %>% 
  add_recipe(rel_vars_rec)

lm_fit <- fit(lm_wflow, data) 

data %>% 
  bind_cols(predict(lm_fit, data)) %>% 
  rsq(index, .pred)
