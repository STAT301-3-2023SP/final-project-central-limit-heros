# load packages ----
library(tidyverse)
library(tidymodels)

# load data ----
load("data/processed/combined_datasets.rda")

# lasso variable selection ----
# impute data
lasso <- recipe(gayborhood_index ~ ., data = combined_datasets) %>% 
  update_role(zip_code, new_role = "id") %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_impute_knn(all_predictors()) %>% 
  step_normalize(all_predictors()) %>% 
  prep() %>% 
  bake(NULL)

# define recipe
lasso_rec <- recipe(gayborhood_index ~ ., data = lasso) %>% 
  update_role(zip_code, new_role = "id")

# model specification
lasso_spec <-
  # can change penalty to be more or less strict
  linear_reg(penalty = 0.05, mixture = 1) %>%
  set_engine('glmnet')

# create workflow
lasso_wflow <- workflow() %>% 
  add_recipe(lasso_rec) %>% 
  add_model(lasso_spec)

lasso_fit <- fit(lasso_wflow, lasso)

relevant_predictors <- tidy(lasso_fit) %>% 
  filter(estimate != 0)

# save data ----
save(lasso_fit, relevant_predictors, file = "data/processed/lasso_var_selection.rda")
