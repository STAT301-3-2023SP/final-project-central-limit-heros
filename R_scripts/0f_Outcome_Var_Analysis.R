#############################################################################
# OUTCOME VARIABLE ANALYSIS ----
#############################################################################

## loading packages + data ----

library(tidyverse)
library(tidymodels)
library(patchwork)

# contains our outcome variable, `totindex`
gayta <- read_csv("data/raw/gay-ta.csv") %>%
  janitor::clean_names()

naniar::vis_miss(gayta)

# no missingness <3 yay

p1 <- ggplot(gayta, aes(x = totindex)) +
  geom_density(fill = "rosybrown1") +
  labs(title = "Untransformed Distribution",
       x = "Gayborhood Index (Untransformed)",
       y = "Density") +
  theme_minimal()

p2 <- ggplot(gayta, aes(x = log10(totindex))) +
  geom_density(fill = "rosybrown1") +
  labs(title = "Transformed Distribution",
       x = "Gayborhood Index (log10 Transform)",
       y = "Density") +
  theme_minimal()

p1 + p2 + plot_annotation(title = "Log Transformation Improves Target Variable Normality")


# THIS CODE IS JUST HERE TO PROVE THAT THE LOGIT TRANSFORM IS *U*&Y*^*)%^&)

recipe(totindex ~., data = gayta) %>%
  step_mutate(totindex = totindex/100) %>%
  step_logit(totindex, offset = 0.04) %>%
  prep() %>%
  bake(new_data = NULL) %>%
  ggplot(aes(x = totindex)) +
  geom_density(fill = "rosybrown1") +
  labs(title = "Transformed Distribution",
       x = "Gayborhood Index (logit Transform)",
       y = "Density") +
  theme_minimal()


#  YEO JOHNSON ALSO DOES A BAD JOB-- THIS IS BECAUSE WE HAVE A LOT OF 0 VALUES
# ok get rid of them LMFAO


recipe(totindex ~., data = gayta) %>%
  step_YeoJohnson(totindex) %>%
  prep() %>%
  bake(new_data = NULL) %>%
  ggplot(aes(x = totindex)) +
  geom_density(fill = "rosybrown1") +
  labs(title = "Transformed Distribution",
       x = "Gayborhood Index (yeo johnson Transform)",
       y = "Density") +
  theme_minimal()
  

gayta %>%
  # tidied value was -0.478 
  mutate(yeo1 = 1/sqrt(1 + totindex),
         yeo = 2*(1 - yeo1)) %>%
  ggplot(aes(x = yeo)) +
  geom_density(fill = "rosybrown1") +
  labs(title = "Transformed Distribution",
       x = "Gayborhood Index (Yeo Johnson Transform)",
       y = "Density") +
  theme_minimal()
  
#############################################################################
# Homosexual Tomfoolery ----
#############################################################################

# ok SO. the issue is that our outcome variable, gayborhood index, has a lot of zero values.

# we could fix this by just adding one? since its an index

# but that could scale things weird? and would still give us a bimodal distribution I think

## here's how we fixed it:

outcome <- gayta %>%
  filter(cns_tot_hh > 100) %>%
  select(geoid10, tax_mjoint, mjoint_ss, cns_tot_hh, cns_upss, parade_flag, count_bars, totindex) %>%
  mutate(rate_tax = (mjoint_ss*1000)/tax_mjoint,
         rate_upss = (cns_upss*1000)/cns_tot_hh,
         norm_tax = rate_tax/max(rate_tax, na.rm=T),
         norm_upss = rate_upss/max(rate_upss, na.rm=T),
         norm_bars = count_bars/20) %>%
  # calc sean index
  mutate(sean_index = (40*norm_tax) + (40*norm_upss) + (10*parade_flag) + (10*norm_bars)) %>%
  drop_na() %>% 
  mutate(yeo_index = VGAM::yeo.johnson(sean_index, lambda = -0.268, inverse = F)) %>%
  transmute(zip_code = as.factor(geoid10), gayborhood_index = yeo_index)

# save her out!!

save(outcome, file = "data/processed/outcome_var.rda")

# ESSENTIALLY. WHAT WE HAVE LEARNED HERE TODAY. IS THAT WE NEED THIS YEO TRANSFORM

# AND SOMETIMES YOU HAVE TO MAKE YOUR OWN METRIC OF QUEERNESS STOREBOUGHT IS NOT

# ALWAYS GOOD ENOUGH


# check some stuff 

outcome %>%
  mutate(test = VGAM::yeo.johnson(yeo_index, lambda = -0.268, inverse = T)) %>%
  ggplot(aes(x = yeo_index)) +
  geom_density()
View()



# here are some notes/what happened along the way:





# so actually some of these zip codes dont have anyone living in them LMFAO

gayta %>%
  group_by(totindex) %>%
  count()

# 381 zeros... yikes!

gayta %>%
  #group_by(cns_tot_hh) %>%
  summarize(count = n(),
            median = median(cns_tot_hh),
            mean = mean(cns_tot_hh)) 

# if you look at some of the ones with less than 100 total households,., they're literally
# not real zipcodes so. we don't need those


gayta_no100 <- gayta %>%
  filter(cns_tot_hh > 100)

gayta_no100 %>%
  group_by(totindex) %>%
  count()

# ok 255 phew

# what are our zeros?

zeros <- gayta_no100 %>%
  filter(totindex == 0)

# 94104 definitely has the wrong calculation


## test

gayta %>%
  mutate(sean_ssindex_weight = (ss_index*41.86682)/(58.41252)) %>%
  select(sean_ssindex_weight, ss_index_weight) %>%
  View()

gayta %>%
  mutate(sean_ssindex_weight = (ss_index*70)/(100)) %>%
  select(sean_ssindex_weight, ss_index_weight) %>%
  View()
  
gayta %>%
  mutate(weight_ss = (ss_index_weight)/ss_index) %>%
  View()

# ss index weight is about 41.86682

gayta %>%
  mutate(sean_mmtax_weight = (tax_rate_mm*70)/(174.5283)) %>%
  select(sean_mmtax_weight, mm_tax) %>%
  View()
  
  
  
  

