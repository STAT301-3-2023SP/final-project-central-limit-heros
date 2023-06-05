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
    #select(mean) %>%
    rename("mean_rmse" = "mean") %>%
    mutate(model_name = model_n)
}

models <- c("cer_bayes", "en_bayes", "en_bayes_pca", "knn_bayes", "mars_bayes",
            "mlp_tuned", "null_fit", "rf_bayes", "xgboost_bayes")

initial_model_comparison <- map(models, shows_best) %>%
  as_tibble_col() %>%
  unnest() %>%
  arrange(mean_rmse) %>%
  mutate(hyperparameters = case_when(
    str_detect(model_name, "^xgboost_bayes") ~ str_c("Min N = ", as.character(signif(min_n, digits = 2)), ", ",
                                             "Learn Rate = ", as.character(signif(learn_rate, digits = 2)), ", ",
                                             "Loss Reduction = ", as.character(signif(loss_reduction, digits = 2))),
    str_detect(model_name, "^cer_bayes") ~ str_c("Committees = ", as.character(signif(committees, digits = 2)), ", ",
                                             "Max Rules = ", as.character(signif(max_rules, digits = 2)), ", ",
                                             "Neighbors = ", as.character(signif(neighbors, digits = 2))),
    str_detect(model_name, "^en_bayes") ~ str_c("Penalty = ", as.character(signif(penalty, digits = 2)), ", ",
                                               "Mixture = ", as.character(signif(mixture, digits = 2))),
    str_detect(model_name, "rf_bayes") ~ str_c("Mtry = ", as.character(signif(mtry, digits = 2)), ", ",
                                               "Trees = ", as.character(signif(trees, digits = 2)),", ",
                                               "Min N = ", as.character(signif(min_n, digits = 2))),
    str_detect(model_name, "knn_bayes") ~ str_c("Neighbors = ", as.character(signif(neighbors, digits = 2)), ", ",
                                               "Dist Power = ", as.character(signif(dist_power, digits = 2))),
    str_detect(model_name, "mlp_tuned") ~ str_c("Penalty = ", as.character(signif(penalty, digits = 2)), ", ",
                                                "Hidden Units = ", as.character(signif(hidden_units, digits = 2))),
    str_detect(model_name, "mars_bayes") ~ str_c("Num Terms = ", as.character(signif(num_terms, digits = 2)), ", ",
                                                "Prod Degree = ", as.character(signif(prod_degree, digits = 2))),
    TRUE ~ NA
  )) %>%
  select(model_name, mean_rmse, std_err, hyperparameters) %>%
  mutate(model_name = case_when(
    model_name == "cer_bayes" ~ "Cubist Ensemble Regression (BI)",
    model_name == "en_bayes" ~ "Elastic Net (BI)",
    model_name == "rf_bayes" ~ "Random Forest (BI)",
    model_name == "knn_bayes" ~ "K-Nearest Neighbors (BI)",
    model_name == "xgboost_bayes" ~ "Boosted Trees (BI)",
    model_name == "en_bayes_pca" ~ "Elastic Net (PLS) (BI)",
    model_name == "mars_bayes" ~ "Multivariate Adaptive Regression Splines (BI)",
    model_name == "mlp_tuned" ~ "Neural Network (Keras)",
    model_name == "null_fit" ~ "Null Model"
  )) %>%
  mutate(
    mean_rmse = signif(mean_rmse, digits= 3),
    std_err = round(std_err, digits = 3)
  ) %>%
  rename("Model Type" = "model_name",
         "Best mean RMSE" = "mean_rmse",
         "Standard Error" = "std_err",
         "Hyperparameters used" = "hyperparameters") 

save(initial_model_comparison, file = "results/initial_comp.rda")


########################################################################################################
# PREDICTION + ASSESSMENT: SHOULD PROBABLY BE MOVED TO SEPARATE FILE (?) ----
########################################################################################################

load("data/processed/test_data.rda")

knn_preds <- predict(knn_final_model, new_data = test) %>% 
  bind_cols(test %>% select(gayborhood_index)) # %>% 
# metrics(truth = popularity, estimate = .pred)

save(knn_preds, file = "results/predictions/knn_preds.rda")