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
  

