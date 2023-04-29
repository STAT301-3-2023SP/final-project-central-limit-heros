# load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load dataset
census_income <- read_csv("data/raw/census_income/census_income.csv")

#cleaning names ----
#change name of the columns to be 2nd row in CSV
names(census_income) <- census_income[1,]
census_income <- census_income[-1,] %>% 
  janitor::clean_names()

#selecting necessary columns ----
census_income2 <- census_income %>% 
  select(geographic_area_name, contains("estimate_") & !contains("annotation")) %>%
  #add variable with zip code
  mutate(zip_code = str_sub(geographic_area_name, 7, 100)) %>% 
  select(zip_code, everything(), -geographic_area_name) %>% 
  #change everything to numeric
  mutate(across(where(is.character), as.numeric))

# data inspection ----
#missingness
census_income2 %>% 
  naniar::miss_var_summary() %>% 
  filter(pct_miss > 0)
#some cols are completely, should be deleted
census_income2 <- census_income2 %>% 
  select_if(~ !all(is.na(.)))

census_income2 %>% 
  naniar::miss_var_summary()

# are we going to be doing log transformations? should we look for skew?
# I will check a few random variables for skew
census_income2 %>% 
  ggplot(aes(x = households_estimate_total)) +
  geom_histogram()
#households - strongly skewed

census_income2 %>% 
  ggplot(aes(x = families_estimate_15_000_to_24_999)) +
  geom_histogram()
#income brackets also strongly skewed