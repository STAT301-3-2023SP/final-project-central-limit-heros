National Neighborhood Data Archive (NaNDA)
Warning when opening .csv files in Excel
Last updated: 12/03/2019


***USE CAUTION WHEN OPENING .CSV FILES IN EXCEL.***

Microsoft Excel strips leading zeros from numbers when opening CSV files.
Most NaNDA .csv files contain FIPS codes for census tracts, states, and counties. Some FIPS codes have leading zeros.
If you double-click a CSV file to open it, the FIPS codes will become incorrect.

To open a .csv file in Excel (replicated in MS Office 2016):
1. Open a blank Excel workbook.
2. In the Data ribbon, choose From Text.
3. Locate your .csv file and choose Import.
4. In step 1 of the Text Import Wizard, check "My data has headers." Then choose Next.
5. In step 2 of the Text Import Wizard under Delimiters, unselect "Tab" and select "Comma." Then choose Next.
6. In step 3 of the Text Import Wizard, select each column that contains leading zeros. Under Column Data Format, select "Text."
7. Click Finish, then OK.

For additional information and alternate solutions, search the Internet for "Excel leading zeros."