library(tidyverse)

outcome <- read_csv("data/raw/gay-ta.csv") %>% 
  janitor::clean_names() %>% 
  transmute(zip_code = as.numeric(geoid10), index = totindex)

predictors <- read_csv("data/raw/ACSDP5Y2021.DP04-Data.csv", na = c("null")) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_sub(name, 7, 100)) %>% 
  select_if(~ !any(is.na(.))) %>% 
  mutate(across(where(is.character), as.numeric)) %>% 
  select(-name, -geo_id)

data <- outcome %>% 
  left_join(predictors, by = "zip_code")
  