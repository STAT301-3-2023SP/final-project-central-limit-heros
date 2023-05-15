# load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load data ----
load("data/processed/combined_datasets.rda")

# log10 transform ----

combined_datasets_wlog <- combined_datasets %>%
  mutate(log_gbdex = log10(gayborhood_index)) %>%
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
