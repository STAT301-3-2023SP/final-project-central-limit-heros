# load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load data ----
load("data/processed/combined_datasets.rda")
load("data/processed/lasso_var_selection.rda")

# log10 transform and select relevant variables ----

combined_datasets_wlog <- combined_datasets %>%
  # i read this as without loss of generality! too much math/econ for me oops
  select(zip_code, gayborhood_index, relevant_predictors$term[-1]) %>% 
  mutate(log_gbdex = log10(gayborhood_index),
         log_gbdex = case_when(
           log_gbdex == -Inf ~ -2,
           TRUE ~ log_gbdex
         )) %>%
  select(!gayborhood_index) 

# split data ----
split <- initial_split(combined_datasets_wlog, prop = 0.8, strata = log_gbdex)

train <- training(split)
test <- testing(split)

# fold data ----
folds <- vfold_cv(train, v = 8, repeats = 5, strata = log_gbdex)

# save ----
save(folds, split, train, file = "data/processed/split_data.rda")
save(test, file = "data/processed/test_data.rda")
