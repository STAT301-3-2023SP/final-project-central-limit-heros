########################################################################################################
# Neural Network Fitting: Keras ----
########################################################################################################

# NOTE:: THIS REQUIRES INSTALLATION OF TENSORFLOW + KERAS
# YOU CAN LOOK STUFF UP ONLINE
# USE MINICONDA IF YOU WANT IT TO WORK IDK WHY BUT IT DID

# MUST ALSO RUN `tensorflow::install_tensorflow()` for this to work
# NOTE:: THIS WILL RESTART YOUR R SESSION


########################################################################################################
# LOAD PACKAGES + DATA ----
########################################################################################################

library(tidyverse)
library(tidymodels)
library(tictoc)
tidymodels_prefer()
doMC::registerDoMC(cores = 6) # Vlad u will have to do the other thing for pcs <3

load(file = "data/processed/split_data.rda")
set.seed(702)

reticulate::use_condaenv("r-reticulate") # this is the name of my miniconda env with tensorflow installed

# more info on how to install/get this to work here: https://tensorflow.rstudio.com/install/

########################################################################################################
# RECIPE ----
########################################################################################################


mlp_recipe <- recipe(gayborhood_index ~ ., data = train) %>%
  step_nzv(all_predictors()) %>%
  update_role(zip_code, new_role = "id") %>%
  step_impute_knn(all_numeric_predictors()) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_normalize(all_numeric_predictors()) 


########################################################################################################
# MODEL + WORKLOW SPECS ----
########################################################################################################

mlp_spec <- mlp(hidden_units = tune(), penalty = tune()) %>%
  set_engine('keras') %>%
  set_mode('regression')

mlp_workflow <- workflow() %>% 
  add_model(mlp_spec) %>% 
  add_recipe(mlp_recipe)


########################################################################################################
# FITTING + TUNING ----
########################################################################################################

mlp_grid <- extract_parameter_set_dials(mlp_workflow) %>%
  update(hidden_units = hidden_units(range = c(1,10)),
         penalty = penalty(range = c(-8, 0))) %>%
  grid_regular(levels = 3)

ctrl_grid <- control_resamples(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

ctrl_bayes <- control_bayes(verbose = TRUE, save_pred = TRUE, save_workflow = TRUE)

metrics <- metric_set(rmse, ccc)

tic.clearlog()
tic("KNN")

mlp_tuned <- mlp_workflow %>%
  tune_grid(
    resamples = folds, 
    grid = mlp_grid,
    control = ctrl_grid,
    metrics = metrics
  )

save(mlp_tuned, file = "results/model_fits/mlp_tuned.rda")

toc(log = TRUE)

# save runtime info

mlp_time_log <- tic.log(format = FALSE)

elapsed_time <- mlp_time_log[[1]]$toc - mlp_time_log[[1]]$tic

mlp_time_data <- tribble(
  ~ "model", ~"elapsed_time_s", ~"grid_length", ~"folds", ~"repeats", ~"recipes",
  "K-Nearest Neighbors", elapsed_time, nrow(mlp_grid), 8, 5, 1
) %>%
  mutate(avg_time_per_model_ms = (1000*elapsed_time_s)/(grid_length*folds*repeats*recipes))

########################################################################
# NOW DO BAYES
########################################################################

mlp_bayes <- mlp_workflow %>%
  # iterative tuning with `tune_bayes()`
  tune_bayes(resamples = folds,
             initial = mlp_tuned,
             control = ctrl_bayes,
             iter = 7)

save(mlp_bayes, file = "results/model_fits/mlp_bayes.rda")

########################################################################
## HOW LONG DID BAYESIAN ITERATION TAKE?

mlp_time_log <- tic.log(format = FALSE)

elapsed_time <- mlp_time_log[[1]]$toc - mlp_time_log[[1]]$tic

mlp_time_data <- mlp_time_data %>%
  mutate(Bayesian_time_s = elapsed_time,
         iterations = 7,
         bayesian_per_iter = Bayesian_time_s/iterations)

# save time data
save(mlp_time_data, file = "results/model_times/mlp_time_data.rda")

