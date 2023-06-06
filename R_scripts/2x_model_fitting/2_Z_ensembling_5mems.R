# THE POINT OF THIS SCRIPT IS TO PROVE THAT THERE IS NO LARGE IMPROVEMENT
# TO OUR ENSEMBLE PERFORMANCE WHEN WE ADD THE KNN AND XGBOOST MODELS; SO WE THROW
# THEM OUT

# printing `model_stack_blended_5` makes this evident, the top 4 contributors are
# all the OG models

# Load package(s) ----
library(tidymodels)
library(tidyverse)
library(stacks)
library(rules) 

# Handle common conflicts
tidymodels_prefer()

# Load candidate model info ----
load("results/model_fits/cer_tuned.rda") ## ADD IN OUR CHOSEN THREE HERE
load("results/model_fits/en_model.rda")
load("results/model_fits/rf_model.rda")
load("results/model_fits/knn_bayes.rda")
load("results/model_fits/xgboost_model.rda")

# Create data stack ----

model_stack <- stacks() %>%
  add_candidates(cer_tuned) %>% # ALSO REPLACE SAID CHOSEN THREE HERE
  add_candidates(en_bayes) %>%
  add_candidates(rf_bayes) %>%
  add_candidates(xgboost_bayes) %>%
  add_candidates(knn_bayes)


# Fit the stack ----


# Blend predictions using penalty defined above (tuning step, set seed)
set.seed(1)


model_stack_blended_5 <- model_stack %>%
  blend_predictions()

# Save blended model stack for reproducibility & easy reference (Rmd report)

save(model_stack_blended_5, file = "results/model_fits/blended_stack_5.rda")

# Explore the blended model stack

autoplot(model_stack_blended_5)
autoplot(model_stack_blended_5, type = "members") +
  geom_line()

# fit to ensemble to entire training set ----

model_stack_blended_5_fit <- model_stack_blended_5 %>%
  fit_members()

# Save trained ensemble model for reproducibility & easy reference (Rmd report)
save(model_stack_blended_5_fit, file = "results/model_fits/fit_stack_5.rda")

# look at individs
stacks::collect_parameters(model_stack_blended_5_fit, candidates = "cer_tuned")
