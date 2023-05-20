#load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# load model results ----
load("results/rf_log.rda")