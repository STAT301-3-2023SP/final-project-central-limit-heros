## Data collection {#sec-COLLECT}

Because this project is based primarily on data by ZCTA, a US Census-defined zip code proxy, we are able to pool data from two main sources -- the US Census and Open ICPSR-- to encompass 4 major facets of urban life.

1. Our [first predictor set](https://data.census.gov/table?q=rent&g=010XX00US$8600000&tid=ACSDP5Y2021.DP04)[^2] comes from the US Census, and provides a variety of information about housing characteristics including number of housing units in an area, rent prices, and indicators of development (phone reception, income to rent ratio, etc.). This is derived from the Census's ACS 5-year survey estimates for the year 2015. We use data from 2015 since that is also when the Gayborhood dataset was published. The data are relevant to our prediction problem of interest as housing characteristics may imply information about how affordable and lively local economies are, as urban areas tend to attract more LGBTQ+ identifying individuals.

[^2]: US Census. (2021). *DP04: SELECTED HOUSING CHARACTERISTICS* [Data set]. data.census.gov. https://data.census.gov/table?q=rent&g=010XX00US$8600000&tid=ACSDP5Y2021.DP04. Accessed 24 April 2023.

2. We also used US Census data to glean information about various demographic characteristics, as represented in [our second data section](https://data.census.gov/table?g=010XX00US$8600000&tid=ACSDP5Y2015.DP05)[^3]. This set primarily synthesizes demographic information that is *not* specifically related to sexuality (i.e. the parameters that went into the calculation of our outcome variable), but describe other characteristics of each area. As mentioned before, having these data might reveal how welcoming a city is based on diversity, while avoiding issues of multicolinearity.

[^3]: US Census. (2015). *DP05: ACS DEMOGRAPHIC AND HOUSING ESTIMATES* [Data set]. data.census.gov. https://data.census.gov/table?g=010XX00US$8600000&tid=ACSDP5Y2015.DP05. Accessed 26 April 2023.


3. We also opted to include data from Open ICPSR, which included [information about parks](https://doi.org/10.3886/E119803V1)[^4] in each geographical region, including number of open parks and proportion of ZCTA area that is park space. Since parks are public areas, they serve as a predictive metric for the culture of a community, and are thus important in describing neighborhood lifestyle.

[^4]: Li, Mao, Melendez, Robert, Khan, Anam, Gomez-Lopez, Iris, Clarke, Philippa, and Chenoweth, Megan. (2020). *National Neighborhood Data Archive (NaNDA): Parks by ZIP Code Tabulation Area, United States, 2018*. Ann Arbor, MI: Inter-university Consortium for Political and Social Research. https://doi.org/10.3886/E119803V1. Accessed 23 April 2023

4. Finally, we included data concerning the primary method of [transport to work](https://data.census.gov/table?q=commuting&g=010XX00US$8600000&tid=ACSST5Y2021.S0802)[^5], also from the US Census ACS survey. This will round out our predictors by describing the movement, as well as the physical locale, within a neighborhood, and may be useful to understand the structure of the area (urban/suburban/rural/other).

[^5]: US Census. (2015). *S0802: MEANS OF TRANSPORTATION TO WORK BY SELECTED CHARACTERISTICS* [Data set]. data.census.gov. https://data.census.gov/table?q=commuting&g=010XX00US$8600000&tid=ACSST5Y2021.S0802. Accessed 30 April 2023.

These yield a functional dataset with $> 550$ predictors, which fall into the above categories. For example, these variables included:

- Estimate of households that made less than $10,000
- Estimate of households with 1 vehicle available
- Estimate of wholesale workers who carpooled with a car, truck, or van
- Count of open parks
- Estimate of residents aged 20 to 24