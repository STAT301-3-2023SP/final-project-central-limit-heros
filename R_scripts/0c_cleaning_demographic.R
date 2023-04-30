# load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load dataset
census_demographic <- read_csv("data/raw/census_demographic/census_demographic.csv")

#cleaning names ----
#change name of the columns to be 2nd row in CSV
names(census_demographic) <- census_demographic[1,]
census_demographic <- census_demographic[-1,] %>% 
  janitor::clean_names()

#selecting necessary columns ----
census_demographic <- census_demographic %>% 
  select(geographic_area_name, contains("estimate_") & !contains("annotation")) %>%
  #add variable with zip code
  mutate(zip_code = str_sub(geographic_area_name, 7, 100)) %>% 
  select(zip_code, everything(), -geographic_area_name) %>% 
  #change everything to numeric
  mutate(zip_code = factor(zip_code),
         across(where(is.character), as.numeric))

# data inspection ----
#missingness
census_demographic %>% 
  naniar::miss_var_summary() %>% 
  filter(pct_miss > 0)
#very little missingness, only one variable with 1.52%

# I will check a few random variables for skew
census_demographic %>% 
  ggplot(aes(x = estimate_sex_and_age_65_years_and_over)) +
  geom_histogram()
#strongly skewed

census_demographic %>% 
  ggplot(aes(x = estimate_race_one_race)) +
  geom_histogram()
#also strongly skewed

#save cleaned dataset ----
save(census_demographic, file = "data/processed/demographic_data.rda")
