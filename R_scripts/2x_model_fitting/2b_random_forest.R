#load packages ----
library(tidyverse)
library(tidymodels)
library(tictoc)
library(doParallel)

# handle common conflicts
tidymodels_prefer()

#load required datasets ----
load("data/processed/split_data.rda")

#recipe - log with 0s ---- 
rf_recipe <- recipe(gayborhood_index ~ ., data = train) %>% 
  update_role(zip_code, new_role = "id") %>% 
  step_dummy(all_nominal_predictors()) %>% 
  step_impute_knn(all_predictors()) %>% 
  step_normalize(all_predictors()) %>% 
  step_zv(all_predictors())

# Define model ----
rf_model <- rand_forest(
  mode = "regression",
  mtry = tune(),
  min_n = tune()) %>%
  set_engine("ranger")

#check tuning parameters
rf_params <- hardhat::extract_parameter_set_dials(rf_model)
rf_params

#mtry needs to be specified
#there are 137 unique variables in the dataset, we can use max mtry = 120
rf_params <- rf_params %>% 
  update(mtry = mtry(range = c(1,120)),
         min_n = min_n())

# define tuning grid ----
rf_grid <- grid_regular(rf_params, levels = 5)

# workflow ----
rf_wflow <- workflow() %>% 
  add_model(rf_model) %>% 
  add_recipe(rf_recipe) 

# Tuning/fitting ----

tic("rf")
## Set up parallel processing ----
#using 3 cores
cl <- makePSOCKcluster(3)
registerDoParallel(cl)

# Place tuning code in here
rf_tune <- rf_wflow %>% 
  tune_grid(
    resamples = folds,
    grid = rf_grid
  )

#end parallel processing
stopCluster(cl)

toc(log = TRUE)

# save runtime info
time_log <- tic.log(format = FALSE)

rf_tictoc <- tibble(
  model = time_log[[1]]$msg,
  start_time = time_log[[1]]$tic, 
  end_time = time_log[[1]]$toc,
  runtime = end_time - start_time
)

# Write out results & workflow
save(rf_wflow, rf_tune, rf_tictoc, file = "results/rf_log.rda")

#load("results/elastic_net.rda")
#collect_metrics(rf_tune)

# How many of the indices are actually 0? ----
load("data/processed/combined_datasets.rda")

combined_datasets %>% 
  filter(gayborhood_index == 0) %>% 
  nrow()

combined_datasets %>% nrow()


#log train - is it normally distributed?
train %>% 
  ggplot(aes(x = log_gbdex))+
  geom_density()
