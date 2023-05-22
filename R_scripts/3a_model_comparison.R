#load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# load model results ----
load("results/rf_log.rda")



########################################################################################################
# PREDICTION + ASSESSMENT: SHOULD PROBABLY BE MOVED TO SEPARATE FILE (?) ----
########################################################################################################

load("data/processed/test_data.rda")

knn_preds <- predict(knn_final_model, new_data = test) %>% 
  bind_cols(test %>% select(gayborhood_index) # %>% 
# metrics(truth = popularity, estimate = .pred)

save(knn_preds, file = "results/predictions/knn_preds.rda")