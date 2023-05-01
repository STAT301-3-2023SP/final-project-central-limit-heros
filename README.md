# Queer Coded: Supervised ML to Predict LGBTQ+ Acceptance in American Neighborhoods
## Data Science 3 with R Final Project (STAT 301-3)

### Introduction

Neighborhoods with a high queer population, or [*Gayborhoods*](https://en.wikipedia.org/wiki/Gay_village), have been urban areas in which LGBTQ+ people have found community and built culture worldwide. However, these geographic areas serve as much more than the sexuality of their constituents, and have been cited as yielding robust creative economies, as well as a welcoming environment for those of many identities. Knowing this, the identity of a certain locale as a Gayborhood becomes a crucial sociological metric, with neighborhoods with a more prevalent queer identity driving social liberalism in the face of prejudice. Our analysis thus focuses on building a **location-based regression model** that can uses a variety of parameters including housing, land use, and non-queer demographic data **to predict Gayborhood degree**, and, in so doing, determine whether an area is suitable for queer folks with the goal of advancing understanding of liberal areas.


In order to rank Gayborhood status, we are using a published dataset [from data world](https://data.world/the-pudding/gayborhoods)[^1] that was analyzed to display distribution of queer communities in Jan Diehm's 2018 article [*Men are from Chelsea, Women are from Park Slope*](https://pudding.cool/2018/06/gayborhoods/). Specifically, the metrics in this dataset are combined to form a Gayborhood index, which we will use as the supervising variable for our machine learning project. This index is a holistic assessment of queerness, derived primarily from the following measures:

[^1]: Jan Diehm. (2018). *Gayborhoods* [Data set]. *The Pudding*, data.world. https://data.world/the-pudding/gayborhoods. Accessed 10 April 2023.

- Same-sex joint tax filers
- Unmarried partner same sex households
- Number of Gay Bars
- Whether or not a pride parade routes through the region


Models will be trained using park data and Census data, and will be assessed primarily by root mean squared error.
