# Processed Data

This folder contains the processed datasets derived from data cleaning and feature engineering processes. That is, the data is now ready for an Exploratory Data Analysis, splitting, resampling, etc. Data is saved as `.rda` files to maintain data types from cleaning and ease of access.

Included processed datasets:

-   `combined_datasets.rda` is the concatenation of the four chosen datasets (listed below) with the transformed index outcome variable

    -   Outcome Variable: `outcome_var.rda`

    -   Component 1: `commuter_data.rda`

    -   Component 2: `demographic_data.rda`

    -   Component 3: `housing_predictors.rda`

    -   Component 4: `parks_data.rda`

    -   Not used: `income_data.rda`

-   `lasso_var_selection_01`, `split_data_lasso.rda`, and `test_data_lasso.rda` represent datasets resulting from mechanically selecting relevant predictors through a LASSO model with penalty 0.01

-   `time_data.rda` contains information about model fitting which is relevant to understand computational power necessary to run models and may reveal trade-offs in performance and speed.
