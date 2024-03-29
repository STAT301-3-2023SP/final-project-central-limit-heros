########################################################################################################
# PREDICTION + ASSESSMENT ----
########################################################################################################

##load packages ----
library(tidyverse)
library(tidymodels)
library(rules) # for cubist ensemble
library(stacks)

# handle common conflicts
tidymodels_prefer()

## load model results
load("data/processed/test_data_lasso.rda")
load("data/processed/split_data_lasso.rda")
load("results/model_fits/fit_stack.rda")
load("results/model_fits/cer_bayes.rda")
# our winning model fit was our 3 member ensemble, so we'll use that to get stuff out

########################################################################################################
# ENSEMBLE MODEL ----
########################################################################################################


ensemble_preds <- test %>%
  bind_cols(predict(model_stack_blended_fit, .)) %>%
  select(.pred, gayborhood_index) %>%
  mutate(predictions = VGAM::yeo.johnson(.pred, lambda = -0.268, inverse = T),
         true_gayborhood_index = VGAM::yeo.johnson(gayborhood_index, lambda = -0.268, inverse = T)) %>%
  select(predictions, true_gayborhood_index) %>%
  mutate(residuals = true_gayborhood_index-predictions,
         sq_resid = (residuals)^2) #%>%
  #summarise(mean = mean(sq_resid),
  #          rmse = sqrt(mean))

# Save predictions

save(ensemble_preds, file = "results/predictions/ensemble_preds.rda")
#load("results/predictions/ensemble_preds.rda")


ensemble_preds %>% 
  yardstick::rmse(truth = true_gayborhood_index, estimate = predictions)

ensemble_preds %>% 
  yardstick::ccc(truth = true_gayborhood_index, estimate = predictions)

# plot residuals against fitted values

ensemble_preds %>%
  ggplot(aes(x = predictions, y = residuals)) +
  geom_point(alpha = 0.3) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  theme_minimal()


ensemble_preds %>%
  ggplot(aes(x = true_gayborhood_index, y = predictions)) +
  geom_abline(slope = 1, color = "red", linetype = "dashed") +
  geom_point() +
  coord_obs_pred() +
  theme_minimal()



# look at how individual members performed:

member_preds <- test %>%
  select(gayborhood_index) %>%
  bind_cols(predict(model_stack_blended_fit, test, members = TRUE)) %>%
  mutate(across(everything(), ~ VGAM::yeo.johnson(., lambda = -0.268, inverse = T)))
    

rmse_by_member <- map(member_preds, rmse_vec, truth = member_preds$gayborhood_index) %>%
  as_tibble() %>%
  select(!gayborhood_index) %>%
  rename("ensemble" = ".pred") %>%
  pivot_longer(cols = everything()) %>%
  rename("model_name" = "name",
         "rmse" = "value")


ccc_by_member <- map(member_preds, ccc_vec, truth = member_preds$gayborhood_index) %>%
  as_tibble() %>%
  select(!gayborhood_index) %>%
  rename("ensemble" = ".pred") %>%
  pivot_longer(cols = everything()) %>%
  rename("model_name" = "name",
         "ccc" = "value")

save(ccc_by_member, rmse_by_member, file = "results/predictions/metrics_by_member.rda")
#load("results/predictions/metrics_by_member.rda")


# cubist might actaully be better
########################################################################################################
# CUBIST ALONE ----
########################################################################################################

# This is to prove that we CAN fit the model with RMSE = 3.2 in the ensemble; but its grasping
# at straws (overfitting to the test data)

cer_fit <- cer_bayes %>%
  extract_workflow() %>%
  # this is model 23 (the lowest rmse component of our ensemble)
  finalize_workflow(c(committees = 100, neighbors = 4, max_rules = 250) %>% as_tibble_row()) %>%
  fit(train) 

cer_fit <- cer_bayes %>%
  extract_workflow() %>%
  finalize_workflow(select_best(cer_bayes, metric = "rmse")) %>%
  fit(train) 


cer_preds <- test %>%
  bind_cols(predict(cer_fit, .)) %>%
  select(.pred, gayborhood_index) %>%
  mutate(predictions = VGAM::yeo.johnson(.pred, lambda = -0.268, inverse = T),
         true_gayborhood_index = VGAM::yeo.johnson(gayborhood_index, lambda = -0.268, inverse = T)) %>%
  select(predictions, true_gayborhood_index) %>%
  mutate(residuals = true_gayborhood_index-predictions,
         sq_resid = (residuals)^2) #%>%
#summarise(mean = mean(sq_resid),
#          rmse = sqrt(mean))

# Save predictions

save(cer_preds, file = "results/predictions/cer_preds.rda")
#load("results/predictions/ensemble_preds.rda")


cer_preds %>% 
  yardstick::rmse(truth = true_gayborhood_index, estimate = predictions)

cer_preds %>% 
  yardstick::ccc(truth = true_gayborhood_index, estimate = predictions)

# plot residuals against fitted values

cer_preds %>%
  ggplot(aes(x = predictions, y = residuals)) +
  geom_point(alpha = 0.3) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  theme_minimal()


cer_preds %>%
  ggplot(aes(x = true_gayborhood_index, y = predictions)) +
  geom_abline(slope = 1, color = "red", linetype = "dashed") +
  geom_point() +
  coord_obs_pred() +
  theme_minimal()

