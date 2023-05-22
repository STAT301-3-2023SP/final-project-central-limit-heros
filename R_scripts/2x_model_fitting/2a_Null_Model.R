########################################################################################################
# Null Model Fitting ----
########################################################################################################

# what happens when we literally don't do anything? hopefully nothing bad

########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
library(stacks)
tidymodels_prefer()
doMC::registerDoMC(cores = 6) # Vlad u will have to do the other thing for pcs <3

load(file = "data/processed/split_data.rda")
set.seed(702)

########################################################################################################
# RECIPE ----
########################################################################################################


null_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  update_role(zip_code, new_role = "id") %>%
  step_dummy(all_nominal_predictors()) %>%
  step_impute_median(all_predictors()) %>% # Median imputation -> probably not best
  step_normalize(all_numeric_predictors())

########################################################################################################
# Workflow Specs ----
########################################################################################################


null_mod <- null_model() %>% 
  set_engine("parsnip") %>% 
  set_mode("regression")

null_workflow <- workflow() %>% 
  add_model(null_mod) %>% 
  add_recipe(null_recipe)

ctrl_res <- control_stack_resamples()

metrics <- metric_set(rmse, ccc)

########################################################################################################
# Fitting + Assessment ----
########################################################################################################


null_fit <- fit_resamples(null_workflow, 
                          resamples = folds,
                          control = ctrl_res)

baseline <- null_fit %>% 
  collect_metrics() %>% 
  filter(.metric == "rmse") %>% 
  mutate(wflow_id = "null")

baseline

########################################################################################################
# Save Results ----
########################################################################################################
save(null_fit, baseline, file = "results/null_model.rda")

