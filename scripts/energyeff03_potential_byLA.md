---
title: "EPC_potential_byLA"
output: html_document
date: "2023-03-15"
---

# Analysing the proportion of properties that cannot achieve C ratings for energy efficiency by area

We've combined data on 25 million performance certificates and uploaded to the big data tool BigQuery, in a table called 'EPC_justratings_plusYR'.

We have run a query on this to filter down to certificates from 2012 onwards, and columns that focus on current and potential rating. This generates a new BigQuery table called EPCcurrentVpotential.

Next we run the following query on that table to generate a 33,000 row aggregate dataset showing totals by current and potential rating 'bucket', LA and tenure and the three main categories of tenure (private and social rental; and owner-occupied).

```{sql eval=FALSE, include=FALSE}
#DO NOT RUN THIS CODE - IT WILL NOT WORK IN THIS R NOTEBOOK

SELECT POTENTIAL_ENERGY_RATING, SUM(certs_count) as certs_total, insp_yr, LOCAL_AUTHORITY_LABEL, tenureclean FROM `datacamp-287416.tweetsatmps_month1.EPCcurrentVpotential` 
WHERE insp_yr > 2011 AND tenureclean LIKE "%rivat%"
GROUP BY insp_yr, LOCAL_AUTHORITY_LABEL, POTENTIAL_ENERGY_RATING, tenureclean
ORDER BY LOCAL_AUTHORITY_LABEL DESC, insp_yr 
```

## Import the data

We import the data from the exported CSV.

```{r import 10 years data}
EPC_potentialRatingByLAyrPRIVATE <- rio::import("bigQueryExports/EPC_potentialRatingByLAyrPRIVATE.csv")
```

We check the column names. 

```{r show col names}
#show columns
print(colnames(EPC_potentialRatingByLAyrPRIVATE))

```

## Count grades by year and authority (private rental only)

Now we use the `sqldf` package to run a SQL query that counts private rental inspections only in each of those two classes, for each local authority and year.

First we check the totals tally with our data elsewhere. York for 2012-16 should total 3309 certs.

```{r York test}
sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, SUM(certs_total) AS certs_total, tenureclean
             FROM EPC_potentialRatingByLAyrPRIVATE
             WHERE LOCAL_AUTHORITY_LABEL = 'York' AND insp_yr < 2017
             GROUP BY LOCAL_AUTHORITY_LABEL
             ORDER BY LOCAL_AUTHORITY_LABEL DESC")
```

Let's pivot the SQL query to create two separate columns.

```{r pivot SQL query}
#see https://stackoverflow.com/questions/11724953/creating-multiple-columns-from-one-column
EPCprivatePivotByLApotGradeBand <- sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, insp_yr, sum(case when POTENTIAL_ENERGY_RATING = 'A' OR POTENTIAL_ENERGY_RATING = 'B' OR POTENTIAL_ENERGY_RATING = 'C' then certs_total end) as AtoC, sum(case when POTENTIAL_ENERGY_RATING = 'D' OR POTENTIAL_ENERGY_RATING = 'E' OR POTENTIAL_ENERGY_RATING = 'F' OR POTENTIAL_ENERGY_RATING = 'G' then certs_total end) as DtoG, tenureclean
             FROM EPC_potentialRatingByLAyrPRIVATE
             GROUP BY LOCAL_AUTHORITY_LABEL, insp_yr
             ORDER BY LOCAL_AUTHORITY_LABEL DESC")

#show it
EPCprivatePivotByLApotGradeBand
```

```{r export EPCprivatePivotByLApotGradeBand}
write.csv(EPCprivatePivotByLApotGradeBand, "EPCprivatePivotByLApotGradeBand.csv")
```

## Cleaning up the authorities that have changed: Bucks and Northants

There are a number of authorities which disappeared, or were created, during the period. We can identify them with a SQL query that counts how many entries there are for each LA.

```{r identify missing years}
#create a pivot table showing how many years' data for each LA
la_years_covered <- sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, COUNT(AtoC) AS years
             FROM EPCprivatePivotByLApotGradeBand
             GROUP BY LOCAL_AUTHORITY_LABEL
             ORDER BY years ASC")
#show it
la_years_covered
```

We've downloaded a lookup table of local authority districts for 2011 to 2021. This is in Google Sheets, so we've simplified it and published it as a CSV and import it below.

```{r import lookup table}
#store the CSV link from Google Sheets
lookupcsv = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRH8KRJPfmiIDJcPVdNCIwYS1Nkzya07OVHYi0pQnIPB9k_c3e_h6uAzpRLDoyN1CCArY9AyVGUL2Jo/pub?gid=0&single=true&output=csv"
#read it in as a dataframe
lookupla <- read.csv(lookupcsv)

#show the column names
colnames(lookupla)

#make sure the first one matches
colnames(lookupla)[1] = "LOCAL_AUTHORITY_LABEL"
#rename the second column 
colnames(lookupla)[2] = "currentLAlabel"
```

Now we can merge that lookup data with the existing data

```{r merge EPCprivatePivotByLAyrBand with new names}
#merge the two datasets
EPCprivatePivotByLApotGradeBand <- merge(EPCprivatePivotByLApotGradeBand, lookupla)

EPCprivatePivotByLApotGradeBand
```

## Add 5 year band categories

We can repeat this process to aggregate data based on its year range.

```{r pivot by 5 year groups}
#see https://stackoverflow.com/questions/11724953/creating-multiple-columns-from-one-column
#and https://stackoverflow.com/questions/14630984/how-do-i-do-multiple-case-when-conditions-using-sql-server-2008
EPCprivatePivotByLApotGradeBand_yrBand <- sqldf::sqldf("SELECT currentLAlabel, sum(case when insp_yr > 2012 AND insp_yr < 2018 then AtoC end) as AtoC_13_17, sum(case when insp_yr > 2012 AND insp_yr < 2018 then DtoG end) as DtoG_13_17, sum(case when insp_yr > 2013 AND insp_yr < 2019 then AtoC end) as AtoC_14_18, sum(case when insp_yr > 2013 AND insp_yr < 2019 then DtoG end) as DtoG_14_18, sum(case when insp_yr > 2014 AND insp_yr < 2020 then AtoC end) as AtoC_15_19, sum(case when insp_yr > 2014 AND insp_yr < 2020 then DtoG end) as DtoG_15_19, sum(case when insp_yr > 2015 AND insp_yr < 2021 then AtoC end) as AtoC_16_20, sum(case when insp_yr > 2015 AND insp_yr < 2021 then DtoG end) as DtoG_16_20, sum(case when insp_yr > 2016 AND insp_yr < 2022 then AtoC end) as AtoC_17_21, sum(case when insp_yr > 2016 AND insp_yr < 2022 then DtoG end) as DtoG_17_21, sum(case when insp_yr > 2017 then AtoC end) as AtoC_18_22, sum(case when insp_yr > 2017 then DtoG end) as DtoG_18_22, tenureclean
             FROM EPCprivatePivotByLApotGradeBand
             GROUP BY currentLAlabel
             ORDER BY currentLAlabel DESC")

#show
EPCprivatePivotByLApotGradeBand_yrBand
```


And export (because we're going to change it next).

```{r export EPCprivatePivotByLApotGradeBand_yrBand}
write.csv(EPCprivatePivotByLApotGradeBand_yrBand, "EPCprivatePivotByLApotGradeBand_yrBand.csv")
```

## Calculate percentages

Now we have the totals, but we want to convert those to percentages.

To do that, we are going to loop through each pair of columns for each time period (AtoC and DtoG for 2012-16, etc.), and divide them by the total. Then repalce the originals counts with the percentages.

```{r loop to calculate percs}
#we could make a copy of the data if we wanted at this point, before changing
EPCprivatePivotByLApotGradeBand_yrBand_TOTALS <- EPCprivatePivotByLApotGradeBand_yrBand

#loop through every other number from 2 to 12
for(i in seq(2,12,2)){
  #print it
  print(i)
  #fetch the column at that index, and the next one
  #add all grades in the two columns (i.e. AtoC and DtoG for that year)
  yeartotal <- EPCprivatePivotByLApotGradeBand_yrBand[,i]+EPCprivatePivotByLApotGradeBand_yrBand[,i+1]
  #divide the first column by that total
  AtoCperc <- EPCprivatePivotByLApotGradeBand_yrBand[,i]/yeartotal
  #divide the second column by that total
  DtoGperc <- EPCprivatePivotByLApotGradeBand_yrBand[,i+1]/yeartotal
  #replace the original columns with the percentages
  EPCprivatePivotByLApotGradeBand_yrBand[,i] <- AtoCperc
  EPCprivatePivotByLApotGradeBand_yrBand[,i+1] <- DtoGperc
}

EPCprivatePivotByLApotGradeBand_yrBand
```


```{r export perc version}
write.csv(EPCprivatePivotByLApotGradeBand_yrBand, "EPCprivatePivotByLApotGradeBand_yrBand_PERC.csv")
```

