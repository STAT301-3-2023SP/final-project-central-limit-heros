# load packages ----
library(tidyverse)
library(tidymodels)
library(zipcodeR)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load outcome variable ----
outcome <- read_csv("data/raw/gay-ta.csv") %>% 
  janitor::clean_names() %>% 
  transmute(zip_code = as.numeric(geoid10), index = totindex)

# load predictor variables ----
predictors <- read_csv("data/raw/ACSDP5Y2021.DP04-Data.csv", na = c("", "-", "NA", "null")) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_sub(name, 7, 100)) %>% 
  mutate(across(where(is.character), as.numeric)) %>% 
  select(-geo_id, -name)

# check missingness
naniar::miss_var_summary(predictors) %>% 
  filter(pct_miss < 100 & pct_miss > 1)

# join data ----
data <- outcome %>% 
  inner_join(predictors, by = "zip_code") %>% 
  recipe(index ~ ., data = .) %>% 
  update_role(zip_code, new_role = "identifier") %>% 
  step_zv(all_predictors()) %>% 
  prep() %>% 
  bake(NULL)

# detect missing data
not_matching <- outcome %>% 
  anti_join(predictors) %>% 
  pull(zip_code)

map_df(not_matching, reverse_zipcode)

# lasso model for relevant predictors ----
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

# relevant predictors ----
relevant_predictors_table <- tidy(lasso_fit) %>% 
  filter(estimate != 0 & term != "(Intercept)")

relevant_predictors <- relevant_predictors_table %>% 
  pull(term) %>% 
  str_c(collapse = " + ")

# update data ----
housing_data <- select(data, zip_code, index, relevant_predictors_table$term)

# save data ----
save(housing_data, file = "data/processed/housing_data.rda")
