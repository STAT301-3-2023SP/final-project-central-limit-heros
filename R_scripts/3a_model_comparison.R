#load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# load model results ----
load("results/model_fits/rf_model.rda")
load("results/model_fits/cer_bayes.rda")
load("results/model_fits/en_model.rda")
load("results/model_fits/en_pca_model.rda")
load("results/model_fits/knn_bayes.rda")
load("results/model_fits/mlp_tuned.rda")
load("results/model_fits/mars_model.rda")
load("results/model_fits/xgboost_model.rda")
load("results/model_fits/null_model.rda")


shows_best <- function(model_n){
  model <- get(model_n)
  tune::show_best(model, metric = "rmse") %>%
    slice_head(n=1) %>%
    select(mean) %>%
    rename("mean_rmse" = "mean") %>%
    mutate(model_name = model_n)
}

models <- c("cer_bayes", "en_bayes", "en_bayes_pca", "knn_bayes", "mars_bayes",
            "mlp_tuned", "null_fit", "rf_bayes", "xgboost_bayes")

map(models, shows_best) %>%
  as_tibble_col() %>%
  unnest() %>%
  arrange(mean_rmse)


########################################################################################################
# PREDICTION + ASSESSMENT: SHOULD PROBABLY BE MOVED TO SEPARATE FILE (?) ----
########################################################################################################

load("data/processed/test_data.rda")

knn_preds <- predict(knn_final_model, new_data = test) %>% 
  bind_cols(test %>% select(gayborhood_index)) # %>% 
# metrics(truth = popularity, estimate = .pred)

save(knn_preds, file = "results/predictions/knn_preds.rda")