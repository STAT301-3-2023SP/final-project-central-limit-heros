# Data for Final Project

### Outcome Variable

In order to rank Gayborhood status, we are using a published dataset [from data world](https://data.world/the-pudding/gayborhoods)[^1] that was analyzed to display distribution of queer communities in Jan Diehm's 2018 article [*Men are from Chelsea, Women are from Park Slope*](https://pudding.cool/2018/06/gayborhoods/). Specifically, the metrics in this dataset are combined to form a Gayborhood index, which we will use as the supervising variable for our machine learning project. This index is a holistic assessment of queerness, derived primarily from the following measures:

[^1]: Jan Diehm. (2018). *Gayborhoods* [Data set]. *The Pudding*, data.world. https://data.world/the-pudding/gayborhoods. Accessed 10 April 2023.

- Same-sex joint tax filers
- Unmarried partner same sex households
- Number of Gay Bars
- Whether or not a pride parade routes through the region

### Predictor Variables

Because this project is based primarily on data by ZCTA, a US Census-defined zipcode proxy, we are able to pool data from three main sources, to encompass 3 major facets of urban life.


1. Our [first predictor set](https://data.census.gov/table?q=rent&g=010XX00US$8600000&tid=ACSDP5Y2021.DP04)[^2] comes from the US Census, and provides a variety of information about housing characteristics including number of housing units in an area, rent prices, and indicators of development (phone reception, income to rent ratio, etc.). This is derived from the Census's ACS 5-year survey estimates, as published in 2021.

[^2]: US Census. (2021). *DP04: SELECTED HOUSING CHARACTERISTICS* [Data set]. data.census.gov. https://data.census.gov/table?q=rent&g=010XX00US$8600000&tid=ACSDP5Y2021.DP04. Accessed 24 April 2023.


2. We also used US Census data to glean information about various demographic characteristics, as represented in [our second data section](https://data.census.gov/table?g=010XX00US$8600000&tid=ACSDP5Y2015.DP05)[^3]. This set primarily synthesizes demographic information that is *not* specifically related to sexuality (i.e. the parameters that went into the calculation of our outcome variable), but describe other characteristics of each area.

[^3]: US Census. (2015). *DP05: ACS DEMOGRAPHIC AND HOUSING ESTIMATES* [Data set]. data.census.gov. https://data.census.gov/table?g=010XX00US$8600000&tid=ACSDP5Y2015.DP05. Accessed 26 April 2023.


3. We also opted to include data from Open ICPSR, which included [information about parks](https://doi.org/10.3886/E119803V1)[^4] in each geographical region, including number of open parks and proportion of ZCTA area that is park space. Since parks are public areas, they serve as a predictive metric for the culture of a community, and are thus important in describing neighborhood lifestyle.

[^4]: Li, Mao, Melendez, Robert, Khan, Anam, Gomez-Lopez, Iris, Clarke, Philippa, and Chenoweth, Megan. (2020). *National Neighborhood Data Archive (NaNDA): Parks by ZIP Code Tabulation Area, United States, 2018*. Ann Arbor, MI: Inter-university Consortium for Political and Social Research. https://doi.org/10.3886/E119803V1. Accessed 23 April 2023

