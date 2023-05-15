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


knn_recipe <- recipe(log_gbdex ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_median(all_numeric_predictors()) %>% # Median imputation -> probably not best
  step_normalize(all_numeric_predictors()) %>%
  step_pca(all_numeric_predictors(), threshold = tune()) %>%
  step_dummy(all_nominal_predictors()) 

  # step_spline_b() Maybe add splines?
  

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
         dist_power = dist_power(range = c(1,4)),
         threshold = threshold(range = c(.9, .99))) %>%
  grid_regular(levels = 3)

ctrl_grid <- control_stack_grid()

ctrl_bayes <- control_stack_bayes()

metrics <- metric_set(rmse, ccc)


knn_tuned <- knn_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = knn_grid,
    control = ctrl_grid,
    metrics = metrics
  )

knn_bayes <- knn_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = knn_tuned,
             control = ctrl_bayes,
             iter = 7)

knn_workflow_tuned <- knn_workflow %>% 
  finalize_workflow(select_best(knn_bayes, metric = "rmse"))

knn_final_model <- fit(knn_workflow_tuned, train)

# Save model objects

# maybe don't even fit models in this file? but could be helpful

save(knn_workflow_tuned, knn_final_model, file = "results/model_fits/knn_model.rda")


########################################################################################################
# PREDICTION + ASSESSMENT: SHOULD PROBABLY BE MOVED TO SEPARATE FILE (?) ----
########################################################################################################

load("data/processed/test_data.rda")

knn_preds <- predict(knn_final_model, new_data = test) %>% 
  bind_cols(test %>% select(log_gbdex)) # %>% 
 # metrics(truth = popularity, estimate = .pred)

save(knn_preds, file = "results/predictions/knn_preds.rda")

