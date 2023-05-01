#############################################################################
# DATA PROCESSING FOR NANDA PARKS DATA 2018 ----
#############################################################################

## loading packages + data ----

library(tidyverse)

nanda_parks <- read_csv("data/raw/nanda_parks_2018/nanda_parks_zcta_2018_01P.csv") %>% 
  janitor::clean_names()

#standard name for zip code column
nanda_parks <- nanda_parks %>% 
  rename(zip_code = zcta19) %>% 
  mutate(zip_code = as.factor(zip_code))
  
#remove text from values and convert to numbers

#change "10 or more" to "10"
#str_extract("10 or more", "^\\d*")

nanda_parks <- nanda_parks %>% 
  #remove text from values
  mutate(count_open_parks_tc10 = str_extract(count_open_parks_tc10, "^\\d*"),
         count_open_parks_tc5 = str_extract(count_open_parks_tc5, "^\\d*"),
         count_open_parks_tc3 = str_extract(count_open_parks_tc3, "^\\d*"),
         #convert any open parks to factor
         any_open_park = as.factor(any_open_park)) %>% 
  #convert all characters to numeric
  mutate(across(where(is.character), as.numeric)) %>% 
  #remove columns in square meters (we only need the square miles ones)
  select(everything(), -zcta_area, tot_park_area)

## missingness slay? ----

naniar::vis_miss(nanda_parks)
naniar::miss_var_summary(nanda_parks) %>% 
  filter(pct_miss > 0)
# no <3 

# save ----
save(nanda_parks, file = "data/processed/parks_data.rda")

# misc data combination ----

gayta <- read_csv("data/raw/gay-ta.csv") %>%
  select(GEOID10, TOTINDEX)

gay_parks <- inner_join(gayta, nanda_parks, by = c( "GEOID10" = "zcta19")) 

