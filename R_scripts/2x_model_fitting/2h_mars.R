########################################################################################################
# MARS (earth) Fitting ----
########################################################################################################

########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
tidymodels_prefer()
library(tictoc)
library(doParallel)

load(file = "data/processed/split_data_lasso.rda")
set.seed(702)

#parallel processing
cl <- makePSOCKcluster(3)
registerDoParallel(cl)

########################################################################################################
# RECIPE ----
########################################################################################################

mars_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors())

########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

mars_spec <-
  mars(num_terms =  tune(),
       prod_degree = tune()) %>%
  set_engine("earth") %>% 
  set_mode("regression")

mars_workflow <- workflow() %>% 
  add_model(mars_spec) %>% 
  add_recipe(mars_recipe)

########################################################################################################
# FITTING + TUNING ----
########################################################################################################

mars_grid <- extract_parameter_set_dials(mars_workflow) %>% 
  grid_regular(levels = 3)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("MARS")

mars_tuned <- mars_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = mars_grid,
    control = ctrl_grid,
    metrics = metrics
  )

toc(log = TRUE)

# save runtime info

mars_time_log <- tic.log(format = FALSE)

elapsed_time <- mars_time_log[[1]]$toc - mars_time_log[[1]]$tic

mars_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "MARS", elapsed_time, nrow(mars_grid), 5, 3, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

mars_bayes <- mars_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = mars_tuned,
             control = ctrl_bayes,
             iter = 2)

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

mars_time_log <- tic.log(format = FALSE)

elapsed_time <- mars_time_log[[1]]$toc - mars_time_log[[1]]$tic

mars_time_data <- mars_time_data %>%
  mutate(Bayesian_time_s = elapsed_time)

# save time data
save(mars_time_data, file = "results/model_times/mars_time_data.rda")

########################################################################

# Save model objects

save(mars_bayes, file = "results/model_fits/mars_model.rda")

#end parallel processing
stopCluster(cl)