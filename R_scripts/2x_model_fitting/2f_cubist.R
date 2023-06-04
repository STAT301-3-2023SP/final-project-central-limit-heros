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

load(file = "data/processed/split_data.rda")
set.seed(702)

########################################################################################################
# RECIPE ----
########################################################################################################


cer_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) 


########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

cer_spec <- cubist_rules(committees = tune(), neighbors = tune(), max_rules = tune()) %>%
  set_engine('Cubist') %>%
  set_mode('regression')


cer_workflow <- workflow() %>% 
  add_model(cer_spec) %>% 
  add_recipe(cer_recipe)


########################################################################################################
# FITTING + TUNING ----
########################################################################################################

cer_grid <- extract_parameter_set_dials(cer_workflow) %>%
  grid_regular(levels = 3)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("KNN")

cer_tuned <- cer_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = cer_grid,
    control = ctrl_grid,
    metrics = metrics
  )

save(cer_tuned, file = "results/model_fits/cer_tuned.rda")

toc(log = TRUE)

# save runtime info

cer_time_log <- tic.log(format = FALSE)

elapsed_time <- cer_time_log[[1]]$toc - cer_time_log[[1]]$tic

cer_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "K-Nearest Neighbors", elapsed_time, nrow(cer_grid), 8, 5, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

cer_bayes <- cer_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = cer_tuned,
             control = ctrl_bayes,
             iter = 10)

save(cer_bayes, file = "results/model_fits/cer_bayes.rda")

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

cer_time_log <- tic.log(format = FALSE)

elapsed_time <- cer_time_log[[1]]$toc - cer_time_log[[1]]$tic

cer_time_data <- cer_time_data %>%
  mutate(Bayesian_time_s = elapsed_time,
         iterations = 10,
         bayesian_per_iter = Bayesian_time_s/iterations)

# save time data
save(cer_time_data, file = "results/model_times/cer_time_data.rda")

