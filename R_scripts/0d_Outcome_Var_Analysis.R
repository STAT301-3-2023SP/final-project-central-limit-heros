#############################################################################
# OUTCOME VARIABLE ANALYSIS ----
#############################################################################

## loading packages + data ----

library(tidyverse)

# contains our outcome variable, `totindex`
gayta <- read_csv("data/raw/gay-ta.csv") %>%
  janitor::clean_names()

naniar::vis_miss(gayta)

# no missingness <3 yay

ggplot(gayta, aes(x = totindex)) +
  geom_density() +
  ggpubr::theme_pubr()

ggplot(gayta, aes(x = log10(totindex))) +
  geom_density() +
  ggpubr::theme_pubr()
