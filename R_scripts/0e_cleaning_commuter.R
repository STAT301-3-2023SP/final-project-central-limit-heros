# load packages ----
library(tidyverse)
library(tidymodels)

# handle common conflicts
tidymodels_prefer()

# set seed
set.seed(1)

# load dataset
census_commuter <- read_csv("data/raw/census_commuting/ACSST5Y2015.S0802-Data.csv")

#cleaning names ----
#change name of the columns to be 2nd row in CSV
names(census_commuter) <- census_commuter[1,]
census_commuter <- census_commuter[-1,] %>% 
  janitor::clean_names()

#selecting necessary columns ----
census_commuter <- census_commuter %>% 
  select(geographic_area_name, contains("estimate_") & !contains("annotation")) %>%
  #add variable with zip code
  mutate(zip_code = str_sub(geographic_area_name, 7, 100)) %>% 
  select(zip_code, everything(), -geographic_area_name) %>% 
  #change everything to numeric
  mutate(zip_code = factor(zip_code),
         across(where(is.character), as.numeric))

# data inspection ----
# select and get rid of high missingness
high_missing <- census_commuter %>% 
  naniar::miss_var_summary() %>% 
  filter(pct_miss > 20) %>%
  select(variable)

census_commuter <- census_commuter %>%
  select(!contains(high_missing[[1]])) 

# I will check a random variables for skew
census_commuter %>% 
  ggplot(census_commuter, aes(x = car_truck_or_van_carpooled_estimate_median_earnings_dollars)) +
  geom_histogram()
#some skew 

#save cleaned dataset ----
save(census_commuter, file = "data/processed/commuter_data.rda")
