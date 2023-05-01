# load packages ----
library(tidyverse)

# load datasets ----
load("data/processed/demographic_data.rda")
load("data/processed/housing_predictors.rda")
load("data/processed/income_data.rda")
load("data/processed/parks_data.rda")
load("data/processed/commuter_data.rda")

# combine datasets ----
## load outcome variable ----
outcome <- read_csv("data/raw/gay-ta.csv") %>% 
  janitor::clean_names() %>% 
  transmute(zip_code = as.factor(geoid10), gayborhood_index = totindex)

combined_datasets <- outcome %>% 
  inner_join(census_demographic, by = "zip_code") %>% 
  inner_join(housing_predictors, by = "zip_code") %>% 
  inner_join(census_income, by = "zip_code") %>% 
  inner_join(nanda_parks, by = "zip_code") %>% 
  inner_join(census_commuter, by = "zip_code")

# save ----
save(combined_datasets, file = "data/processed/combined_datasets.rda")
