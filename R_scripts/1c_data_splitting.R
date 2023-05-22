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

# split data ----
split <- initial_split(combined_datasets, prop = 0.8, strata = gayborhood_index)

train <- training(split)
test <- testing(split)

# fold data ----
folds <- vfold_cv(train, v = 8, repeats = 5, strata = gayborhood_index)

# save ----
save(folds, split, train, file = "data/processed/split_data.rda")
save(test, file = "data/processed/test_data.rda")
