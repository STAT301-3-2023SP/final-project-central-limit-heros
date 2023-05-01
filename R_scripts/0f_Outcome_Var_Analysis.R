#############################################################################
# OUTCOME VARIABLE ANALYSIS ----
#############################################################################

## loading packages + data ----

library(tidyverse)
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

