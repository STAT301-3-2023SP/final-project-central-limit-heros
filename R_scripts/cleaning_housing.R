# load pacakges
library(tidyverse)
library(zipcodeR)

# load outcome variable
outcome <- read_csv("data/raw/gay-ta.csv") %>% 
  janitor::clean_names() %>% 
  transmute(zip_code = as.numeric(geoid10), index = totindex)

# load predictor variables
predictors <- read_csv("data/raw/ACSDP5Y2021.DP04-Data.csv", na = c("", "-", "NA", "null")) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_sub(name, 7, 100)) %>% 
  mutate(across(where(is.character), as.numeric)) %>% 
  select_if()

naniar::miss_var_summary(predictors) %>% 
  filter(pct_miss < 100 & pct_miss > 1) %>% 
  View()

# joined data
data <- outcome %>% 
  inner_join(predictors, by = "zip_code")

not_matching <- outcome %>% 
  anti_join(predictors) %>% 
  pull(zip_code)

map_df(not_matching, reverse_zipcode)

predictors[, 10:50]
