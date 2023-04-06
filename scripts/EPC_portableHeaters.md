---
title: "EPC_portableHeaters"
output: html_document
date: "2023-03-15"
---

# Analysing the proportion of private rental properties that use portable heaters

We've combined data on 25 million performance certificates and uploaded to the big data tool BigQuery, in a table called 'EPC_justratings_plusYR'.

Next we run the following query on that table to generate a 30,000 row aggregate dataset showing totals by a description of the second heating sources, LA and tenure.

```{sql eval=FALSE, include=FALSE}
#DO NOT RUN THIS CODE - IT WILL NOT WORK IN THIS R NOTEBOOK

SELECT SECONDHEAT_DESCRIPTION, LOCAL_AUTHORITY_LABEL,
#extract the year
EXTRACT(YEAR FROM INSPECTION_DATE) as insp_yr,
#clean the tenure
REPLACE(LOWER(TENURE),"rented","rental") AS tenureclean,
COUNT(*) as inspections
FROM `datacamp-287416.tweetsatmps_month1.certificatescombined`
#filter to 2012 on, and private only
WHERE EXTRACT(YEAR FROM INSPECTION_DATE) > 2011 AND REPLACE(LOWER(TENURE),"rented","rental") LIKE "%rivat%"
GROUP BY SECONDHEAT_DESCRIPTION, LOCAL_AUTHORITY_LABEL, tenureclean, insp_yr
ORDER BY inspections DESC
```

## Import the data

We import the data from the exported CSV.

```{r import 10 years data}
portableHeaters_byLA_PRIVATE <- rio::import("bigQueryExports/portableHeaters_byLA_PRIVATE.csv")
```

We check the column names. 

```{r show col names}
#show columns
print(colnames(portableHeaters_byLA_PRIVATE))

```

## Cleaning up the authorities that have changed: Bucks and Northants

There are a number of authorities which disappeared, or were created, during the period. 

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
portableHeaters_byLA_PRIVATE <- merge(portableHeaters_byLA_PRIVATE, lookupla)

EPCprivatePivotByLApotGradeBand
```

## Count proportions by authority (private rental only) for the last 5 years

Now we use the `sqldf` package to run a SQL query that counts private rental inspections only in each of those two classes, for each local authority and year.

First we check the totals tally with our data elsewhere. York for 2012-16 should total 3309 inspections

```{r York test}
sqldf::sqldf("SELECT currentLAlabel, SUM(inspections) AS certs_total, tenureclean
             FROM portableHeaters_byLA_PRIVATE
             WHERE currentLAlabel = 'York' AND insp_yr < 2017
             GROUP BY currentLAlabel
             ORDER BY currentLAlabel DESC")
```
Let's pivot the SQL query to create two separate columns instead. One counts entries where SECONDHEAT_DESCRIPTION is 'None' or 'Dim' (Welsh for 'none'); the other where it is *not* those terms (having checked that all other terms refer to some form of portable heating).

We are going to filter to just 2018-2022 as we don't need to see change over time, just a total for the last five years.

```{r pivot SQL query}
#see https://stackoverflow.com/questions/11724953/creating-multiple-columns-from-one-column
portableHeaters_byLA_PRIVATE_WIDE <- sqldf::sqldf("SELECT currentLAlabel, sum(case when SECONDHEAT_DESCRIPTION = 'None' OR SECONDHEAT_DESCRIPTION = 'Dim' then inspections end) as No2ndHeat, sum(case when SECONDHEAT_DESCRIPTION != 'None' then inspections end) as Yes2ndHeat, tenureclean
             FROM portableHeaters_byLA_PRIVATE
             WHERE insp_yr > 2017
             GROUP BY currentLAlabel
             ORDER BY currentLAlabel DESC")

#show it
portableHeaters_byLA_PRIVATE_WIDE
```

Let's also add a column that shows that as a percentage.

```{r add % 2nd heating}
#divide the numbers with 2nd heating sources, by the total of both yes and no
portableHeaters_byLA_PRIVATE_WIDE$Perc2ndHeat <- portableHeaters_byLA_PRIVATE_WIDE$Yes2ndHeat/(portableHeaters_byLA_PRIVATE_WIDE$No2ndHeat + portableHeaters_byLA_PRIVATE_WIDE$Yes2ndHeat)
```


```{r export EPCprivatePivotByLApotGradeBand}
write.csv(portableHeaters_byLA_PRIVATE_WIDE, "portableHeaters_byLA_PRIVATE_WIDE.csv")
```

