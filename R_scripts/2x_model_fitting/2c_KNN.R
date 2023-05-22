########################################################################################################
# K-Nearest Neighbors Model Fitting ----
########################################################################################################

# K-nearest neighbors <3

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


knn_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) 


########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

knn_spec <-
  nearest_neighbor(neighbors = tune(), dist_power = tune()) %>%
  set_engine('kknn') %>%
  set_mode('regression')

knn_workflow <- workflow() %>% 
  add_model(knn_spec) %>% 
  add_recipe(knn_recipe)


########################################################################################################
# FITTING + TUNING ----
########################################################################################################

knn_grid <- extract_parameter_set_dials(knn_workflow) %>%
  update(neighbors = neighbors(range = c(5,40)),
         dist_power = dist_power(range = c(1,4))) %>%
  grid_regular(levels = 3)

ctrl_grid <- control_stack_grid()

ctrl_bayes <- control_stack_bayes()

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("KNN")

knn_tuned <- knn_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = knn_grid,
    control = ctrl_grid,
    metrics = metrics
  )

toc(log = TRUE)

# save runtime info

knn_time_log <- tic.log(format = FALSE)

elapsed_time <- knn_time_log[[1]]$toc - knn_time_log[[1]]$tic

knn_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "K-Nearest Neighbors", elapsed_time, nrow(knn_grid), 8, 5, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

knn_bayes <- knn_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = knn_tuned,
             control = ctrl_bayes,
             iter = 7)

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

knn_time_log <- tic.log(format = FALSE)

elapsed_time <- knn_time_log[[1]]$toc - knn_time_log[[1]]$tic

knn_time_data <- knn_time_data %>%
  mutate(Bayesian_time_s = elapsed_time)

# save time data
save(knn_time_data, file = "results/model_times/knn_time_data.rda")

########################################################################

knn_workflow_tuned <- knn_workflow %>% 
  finalize_workflow(select_best(knn_bayes, metric = "rmse"))

knn_final_model <- fit(knn_workflow_tuned, train)

# Save model objects

save(knn_bayes, knn_workflow, knn_workflow_finalized, knn_final_model, file = "results/model_fits/knn_model.rda")

