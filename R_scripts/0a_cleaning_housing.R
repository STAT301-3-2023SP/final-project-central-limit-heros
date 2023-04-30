# part 1 ----
## load packages ----
library(tidyverse)
library(tidymodels)
library(zipcodeR)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

## load outcome variable ----
outcome <- read_csv("data/raw/gay-ta.csv") %>% 
  janitor::clean_names() %>% 
  transmute(zip_code = as.factor(geoid10), index = totindex)

## load predictor variables ----
housing_predictors <- read_csv("data/raw/ACSDP5Y2021.DP04-Data.csv", na = c("", "-", "NA", "null"))
#change name of the columns to be 2nd row in CSV
names(housing_predictors) <- housing_predictors[1,]
housing_predictors <- housing_predictors[-1,] %>% 
  janitor::clean_names()

##selecting necessary columns ----
housing_predictors <- housing_predictors %>% 
  #select only estimate columns, remove any annotation columns
  select(geographic_area_name, contains("estimate_") & !contains("annotation")) %>%
  #add variable with zip code
  mutate(zip_code = str_sub(geographic_area_name, 7, 100)) %>% 
  select(zip_code, everything(), -geographic_area_name) %>% 
  #change everything to numeric (except zip code)
  mutate(zip_code = factor(zip_code),
         across(where(is.character), as.numeric))

## check missingness ----
naniar::miss_var_summary(housing_predictors) %>% 
  filter(pct_miss > 1)
#gross rent occupied units paying rent median dollars has more than 20% missing, should not be imputed, just removed
housing_predictors <- housing_predictors %>% 
  select(everything(), -estimate_gross_rent_occupied_units_paying_rent_median_dollars)

## save cleaned dataset ----
save(housing_predictors, file = "data/processed/housing_predictors.rda")

# part 2 models ----

# join data ----
data <- outcome %>% 
  inner_join(housing_predictors, by = "zip_code") %>% 
  recipe(index ~ ., data = .) %>% 
  update_role(zip_code, new_role = "identifier") %>% 
  step_zv(all_predictors()) %>% 
  prep() %>% 
  bake(NULL)

# detect missing data
not_matching <- outcome %>% 
  anti_join(housing_predictors) %>% 
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

# how much of the variation is captured?
housing_data %>% 
  select(-zip_code) %>% 
  lm(index ~ ., data = .) %>% 
  summary()

# update data ----
housing_data <- select(data, zip_code, index, relevant_predictors_table$term)

# save data ----
save(housing_data, file = "data/processed/housing_data.rda")
