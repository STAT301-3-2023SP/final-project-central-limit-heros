# load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load data ----
load("data/processed/combined_datasets.rda")
load("data/processed/lasso_var_selection_01.rda")

# select lassoed variables ----
relevant_predictors <- relevant_predictors %>% slice(2:nrow(.))

lasso_dataset <- combined_datasets %>% 
  select(zip_code, gayborhood_index, all_of(relevant_predictors$term))

# split data ----
split <- initial_split(lasso_dataset, prop = 0.8, strata = gayborhood_index)

train <- training(split)
test <- testing(split)

# fold data ----
folds <- vfold_cv(train, v = 5, repeats = 3, strata = gayborhood_index)

# save ----
save(folds, split, train, file = "data/processed/split_data_lasso.rda")
save(test, file = "data/processed/test_data_lasso.rda")

# missingness for lasso dataset
naniar::miss_var_summary(lasso_dataset)

save(lasso_dataset, file = "data/processed/lasso_dataset.rda")
