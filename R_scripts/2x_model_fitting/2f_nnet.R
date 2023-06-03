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

nnet_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors())

########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

nnet_spec <-
  mlp(hidden_units = tune(), penalty = tune(), epochs = tune()) %>%
  set_engine('nnet', MaxNWts = 5700) %>%
  set_mode('regression')

nnet_workflow <- workflow() %>% 
  add_model(nnet_spec) %>% 
  add_recipe(nnet_recipe)

########################################################################################################
# FITTING + TUNING ----
########################################################################################################

nnet_grid <- extract_parameter_set_dials(nnet_workflow) %>% 
  grid_regular(levels = 2)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("Elastic Net")

nnet_tuned <- nnet_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = nnet_grid,
    control = ctrl_grid,
    metrics = metrics
  )

toc(log = TRUE)

# save runtime info

nnet_time_log <- tic.log(format = FALSE)

elapsed_time <- nnet_time_log[[1]]$toc - nnet_time_log[[1]]$tic

nnet_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "Neural Network", elapsed_time, nrow(nnet_grid), 8, 5, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

nnet_bayes <- nnet_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = nnet_tuned,
             control = ctrl_bayes,
             iter = 15)

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

nnet_time_log <- tic.log(format = FALSE)

elapsed_time <- nnet_time_log[[1]]$toc - nnet_time_log[[1]]$tic

nnet_time_data <- nnet_time_data %>%
  mutate(Bayesian_time_s = elapsed_time)

# save time data
save(nnet_time_data, file = "results/model_times/nnet_time_data.rda")

########################################################################

# Save model objects

save(nnet_bayes, file = "results/model_fits/nnet_model.rda")

