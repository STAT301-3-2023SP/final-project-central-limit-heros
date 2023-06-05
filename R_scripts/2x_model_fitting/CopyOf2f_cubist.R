########################################################################################################
# Cubist Ensemble Regression Model Fitting ----
########################################################################################################

# This is tree based (I think)

########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
library(tictoc)
library(rules) # parsnip extension package needed for cubist ensemble regression
tidymodels_prefer()
doMC::registerDoMC(cores = 6) # Vlad u will have to do the other thing for pcs <3

load(file = "data/processed/split_data_lasso.rda")
set.seed(702)

########################################################################################################
# RECIPE ----
########################################################################################################


cer_test_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_spline_natural(all_numeric_predictors()) %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) 


########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

cer_test_spec <- cubist_rules(committees = tune(), neighbors = tune(), max_rules = tune()) %>%
  set_engine('Cubist') %>%
  set_mode('regression')


cer_test_workflow <- workflow() %>% 
  add_model(cer_test_spec) %>% 
  add_recipe(cer_test_recipe)


########################################################################################################
# FITTING + TUNING ----
########################################################################################################

cer_test_grid <- extract_parameter_set_dials(cer_test_workflow) %>%
  grid_regular(levels = 3)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("KNN")

cer_test_tuned <- cer_test_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = cer_test_grid,
    control = ctrl_grid,
    metrics = metrics
  )

save(cer_test_tuned, file = "results/model_fits/cer_test_tuned.rda")

toc(log = TRUE)

# save runtime info

cer_test_time_log <- tic.log(format = FALSE)

elapsed_time <- cer_test_time_log[[1]]$toc - cer_test_time_log[[1]]$tic

cer_test_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "K-Nearest Neighbors", elapsed_time, nrow(cer_test_grid), 5, 3, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

cer_test_bayes <- cer_test_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = cer_test_tuned,
             control = ctrl_bayes,
             iter = 10)

save(cer_test_bayes, file = "results/model_fits/cer_test_bayes.rda")

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

cer_test_time_log <- tic.log(format = FALSE)

elapsed_time <- cer_test_time_log[[1]]$toc - cer_test_time_log[[1]]$tic

cer_test_time_data <- cer_test_time_data %>%
  mutate(Bayesian_time_s = elapsed_time,
         iterations = 10,
         bayesian_per_iter = Bayesian_time_s/iterations)

# save time data
save(cer_test_time_data, file = "results/model_times/cer_test_time_data.rda")

