########################################################################################################
# Elastic Net Fitting ----
########################################################################################################

########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
library(tictoc)
tidymodels_prefer()
doMC::registerDoMC(cores = 8) # Vlad u will have to do the other thing for pcs <3

load(file = "data/processed/split_data.rda")
set.seed(702)

########################################################################################################
# RECIPE ----
########################################################################################################

en_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors())

########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

en_spec <-
  linear_reg(penalty = tune(), mixture = tune()) %>%
  set_engine('glmnet')

en_workflow <- workflow() %>% 
  add_model(en_spec) %>% 
  add_recipe(en_recipe)

########################################################################################################
# FITTING + TUNING ----
########################################################################################################

en_grid <- extract_parameter_set_dials(en_workflow) %>% 
  grid_regular(levels = 2)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("Elastic Net")

en_tuned <- en_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = en_grid,
    control = ctrl_grid,
    metrics = metrics
  )

toc(log = TRUE)

# save runtime info

en_time_log <- tic.log(format = FALSE)

elapsed_time <- en_time_log[[1]]$toc - en_time_log[[1]]$tic

en_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "Elastic Net", elapsed_time, nrow(en_grid), 8, 5, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

en_bayes <- en_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = en_tuned,
             control = ctrl_bayes,
             iter = 15)

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

en_time_log <- tic.log(format = FALSE)

elapsed_time <- en_time_log[[1]]$toc - en_time_log[[1]]$tic

en_time_data <- en_time_data %>%
  mutate(Bayesian_time_s = elapsed_time)

# save time data
save(en_time_data, file = "results/model_times/en_time_data.rda")

########################################################################

# Save model objects

save(en_bayes, file = "results/model_fits/en_model.rda")

