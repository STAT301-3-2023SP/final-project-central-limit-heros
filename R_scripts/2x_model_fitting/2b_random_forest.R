########################################################################################################
# Random Forest Fitting ----
########################################################################################################

########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
tidymodels_prefer()
library(tictoc)
#library(doParallel)

load(file = "data/processed/split_data_lasso.rda")

set.seed(702)

#parallel processing
#cl <- makePSOCKcluster(3)
#registerDoParallel(cl)
doMC::registerDoMC(cores = 6)

########################################################################################################
# RECIPE ----
########################################################################################################

rf_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors())

########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

rf_spec <-
  rand_forest(
    mode = "regression",
    trees = tune(),
    mtry = tune(),
    min_n = tune()) %>%
  set_engine("ranger")

#update parameters
rf_params <- hardhat::extract_parameter_set_dials(rf_spec)
#mtry needs to be specified
#there are 108 unique variables, will use maximum mtry 100
rf_params <- rf_params %>% 
  update(mtry = mtry(range = c(1,100)),
         trees = trees(),
         min_n = min_n())

rf_workflow <- workflow() %>% 
  add_model(rf_spec) %>% 
  add_recipe(rf_recipe)

########################################################################################################
# FITTING + TUNING ----
########################################################################################################

rf_grid <- rf_params %>% 
  grid_regular(levels = 2)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("rf")

rf_tuned <- rf_workflow %>%
  tune_grid(
    resamples = folds,
    grid = rf_grid,
    control = ctrl_grid,
    metrics = metrics
  )

toc(log = TRUE)

# save runtime info

rf_time_log <- tic.log(format = FALSE)

elapsed_time <- rf_time_log[[1]]$toc - rf_time_log[[1]]$tic

rf_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "Neural Network", elapsed_time, nrow(rf_grid), 5, 3, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

rf_bayes <- rf_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = rf_tuned,
             control = ctrl_bayes,
             iter = 5,
             param_info = rf_params)

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

rf_time_log <- tic.log(format = FALSE)

elapsed_time <- rf_time_log[[1]]$toc - rf_time_log[[1]]$tic

rf_time_data <- rf_time_data %>%
  mutate(Bayesian_time_s = elapsed_time)

# save time data
save(rf_time_data, file = "results/model_times/rf_time_data.rda")

########################################################################

# Save model objects

save(rf_bayes, file = "results/model_fits/rf_model.rda")

#end parallel processing
#stopCluster(cl)

