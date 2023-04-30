#############################################################################
# DATA PROCESSING FOR NANDA PARKS DATA 2018 ----
#############################################################################

## loading packages + data ----

library(tidyverse)

nanda_parks <- read_csv("data/raw/nanda_parks_2018/nanda_parks_zcta_2018_01P.csv")

gayta <- read_csv("data/raw/gay-ta.csv") %>%
  select(GEOID10, TOTINDEX)

gay_parks <- inner_join(gayta, nanda_parks, by = c( "GEOID10" = "zcta19")) 


## missingness slay? ----

naniar::vis_miss(gay_parks)

# no <3 
