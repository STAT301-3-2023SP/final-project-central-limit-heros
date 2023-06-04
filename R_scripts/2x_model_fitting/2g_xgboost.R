########################################################################################################
# Boosted Tree (XGBoost) Fitting ----
########################################################################################################

########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
library(tictoc)
tidymodels_prefer()
doMC::registerDoMC(cores = 8) # Vlad u will have to do the other thing for pcs <3

load(file = "data/processed/split_data_lasso.rda")
set.seed(702)

########################################################################################################
# RECIPE ----
########################################################################################################

xgboost_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors())

########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

xgboost_spec <-
  boost_tree(learn_rate = tune(), min_n = tune(), loss_reduction = tune()) %>%
  set_engine('xgboost') %>%
  set_mode('regression')

xgboost_workflow <- workflow() %>% 
  add_model(xgboost_spec) %>% 
  add_recipe(xgboost_recipe)

########################################################################################################
# FITTING + TUNING ----
########################################################################################################

xgboost_grid <- extract_parameter_set_dials(xgboost_workflow) %>% 
  grid_regular(levels = 2)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("XGBoost")

xgboost_tuned <- xgboost_workflow %>%
  tune_grid(
    resamples = folds,
    grid = xgboost_grid,
    control = ctrl_grid,
    metrics = metrics
  )

toc(log = TRUE)

# save runtime info

xgboost_time_log <- tic.log(format = FALSE)

elapsed_time <- xgboost_time_log[[1]]$toc - xgboost_time_log[[1]]$tic

xgboost_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "Neural Network", elapsed_time, nrow(xgboost_grid), 5, 3, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

xgboost_bayes <- xgboost_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = xgboost_tuned,
             control = ctrl_bayes,
             iter = 15)

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

xgboost_time_log <- tic.log(format = FALSE)

elapsed_time <- xgboost_time_log[[1]]$toc - xgboost_time_log[[1]]$tic

xgboost_time_data <- xgboost_time_data %>%
  mutate(Bayesian_time_s = elapsed_time, 
         iterations = 15,
         bayesian_per_iter = Bayesian_time_s/iterations)

# save time data
save(xgboost_time_data, file = "results/model_times/xgboost_time_data.rda")

########################################################################

# Save model objects

save(xgboost_bayes, file = "results/model_fits/xgboost_model.rda")

