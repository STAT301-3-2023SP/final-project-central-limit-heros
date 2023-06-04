# Load package(s) ----
library(tidymodels)
library(tidyverse)
library(stacks)
library(rules) # if using a cubist model (which i think we will)

# Handle common conflicts
tidymodels_prefer()

# Load candidate model info ----
load("results/model_fits/cer_tuned.rda") ## ADD IN OUR CHOSEN THREE HERE
load("results/model_fits/en_pca_model.rda")
load("results/model_fits/knn_tuned.rda")

# Create data stack ----

model_stack <- stacks() %>%
  add_candidates(cer_tuned) %>% # ALSO REPLACE SAID CHOSEN THREE HERE
  add_candidates(en_bayes_pca) %>%
  add_candidates(knn_tuned)


# Fit the stack ----


# Blend predictions using penalty defined above (tuning step, set seed)
set.seed(1)


model_stack_blended <- model_stack %>%
  blend_predictions()

# Save blended model stack for reproducibility & easy reference (Rmd report)

save(model_stack_blended, file = "results/model_fits/blended_stack.rda")

# Explore the blended model stack

autoplot(model_stack_blended)
autoplot(model_stack_blended, type = "members") +
  geom_line()

# fit to ensemble to entire training set ----

model_stack_blended_fit <- model_stack_blended %>%
  fit_members()

# Save trained ensemble model for reproducibility & easy reference (Rmd report)
save(model_stack_blended_fit, file = "results/model_fits/fit_stack.rda")

