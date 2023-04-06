---
title: "EPC_AtoC_byLAtenure5yr"
output: html_document
date: "2023-03-15"
---

# Analysing the proportion of properties rated A-C for energy efficiency by area

We've combined data on 1.5 million performance certificates in Scotland and uploaded to the big data tool BigQuery, in a table called 'EPC_scotland_cleaned'. We have run the following query on that table to generate a 1,914 row dataset showing totals by rating, LA and tenure for 2013 onwards and the three main categories of tenure (private and social rental; and owner-occupied).

```{sql eval=FALSE, include=FALSE}
#DO NOT RUN THIS CODE - IT WILL NOT WORK IN THIS R NOTEBOOK

SELECT CURRENT_ENERGY_RATING, COUNT(*) as certs_total, insp_yr, LOCAL_AUTHORITY_LABEL, TENURE
FROM `datacamp-287416.tweetsatmps_month1.EPC_scotland_cleaned`
#filter to 2013+ and private rental only
WHERE CAST(insp_yr AS INT) > 2012 AND TENURE LIKE '%rivat%'
GROUP BY insp_yr, LOCAL_AUTHORITY_LABEL, CURRENT_ENERGY_RATING, TENURE
ORDER BY LOCAL_AUTHORITY_LABEL DESC, insp_yr

```

## Import the data

We import the data from the exported CSV.

```{r import 10 years data}
EPC_10yrs_LAtenureRatingSCOT <- rio::import("scotlandexport.csv")
```

## Add a column showing A-C or D-G

We want to count in two categories: A-C or D-G, so we need to add a column classifying each row accordingly.

```{r add A-C column}
#create a lookup dataframe 
bandlookupdf <- data.frame(CURRENT_ENERGY_RATING = c('A','B','C','D','E','F','G'), ratingband = c('A-C','A-C','A-C','D-G','D-G','D-G','D-G'))

#join it to the dataframe so we have a band category column
EPCdfwBandsSCOT <- dplyr::left_join(EPC_10yrs_LAtenureRatingSCOT, bandlookupdf, by = "CURRENT_ENERGY_RATING")

write.csv(EPCdfwBandsSCOT, "EPCdfwBandsSCOT.csv")
```

## Count grades by year and authority (private rental only)

Now we use the `sqldf` package to run a SQL query that counts private rental inspections only in each of those two classes, for each local authority and year.

```{r count by rating band}
sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, insp_yr, ratingband, SUM(certs_count) AS totalcerts, tenureclean
             FROM EPCdfwBandsSCOT
             GROUP BY LOCAL_AUTHORITY_LABEL, insp_yr, ratingband
             ORDER BY LOCAL_AUTHORITY_LABEL DESC")
```

This creates two separate rows for A-C and D-G, however, so let's pivot the SQL query to create two separate columns instead.

```{r pivot SQL query}
#see https://stackoverflow.com/questions/11724953/creating-multiple-columns-from-one-column
EPCprivatePivotByLAyrBandSCOT <- sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, insp_yr, sum(case when ratingband = 'A-C' then certs_count end) as AtoC, sum(case when ratingband = 'D-G' then certs_count end) as DtoG, tenureclean
             FROM EPCdfwBandsSCOT
             GROUP BY LOCAL_AUTHORITY_LABEL, insp_yr
             ORDER BY LOCAL_AUTHORITY_LABEL DESC")

#show it
EPCprivatePivotByLAyrBandSCOT
```

```{r export EPCprivatePivotByLAyrBand}
write.csv(EPCprivatePivotByLAyrBandSCOT,"EPCprivatePivotByLAyrBandSCOT.csv")
```



## Add 5 year band categories

We can repeat this process to aggregate data based on its year range.

```{r pivot by 5 year groups}
#see https://stackoverflow.com/questions/11724953/creating-multiple-columns-from-one-column
#and https://stackoverflow.com/questions/14630984/how-do-i-do-multiple-case-when-conditions-using-sql-server-2008
EPC5yrPrivatePivotByLASCOT <- sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, sum(case when insp_yr > 2011 AND insp_yr < 2017 then AtoC end) as AtoC_12_16, sum(case when insp_yr > 2011 AND insp_yr < 2017 then DtoG end) as DtoG_12_16, sum(case when insp_yr > 2012 AND insp_yr < 2018 then AtoC end) as AtoC_13_17, sum(case when insp_yr > 2012 AND insp_yr < 2018 then DtoG end) as DtoG_13_17, sum(case when insp_yr > 2013 AND insp_yr < 2019 then AtoC end) as AtoC_14_18, sum(case when insp_yr > 2013 AND insp_yr < 2019 then DtoG end) as DtoG_14_18, sum(case when insp_yr > 2014 AND insp_yr < 2020 then AtoC end) as AtoC_15_19, sum(case when insp_yr > 2014 AND insp_yr < 2020 then DtoG end) as DtoG_15_19, sum(case when insp_yr > 2015 AND insp_yr < 2021 then AtoC end) as AtoC_16_20, sum(case when insp_yr > 2015 AND insp_yr < 2021 then DtoG end) as DtoG_16_20, sum(case when insp_yr > 2016 AND insp_yr < 2022 then AtoC end) as AtoC_17_21, sum(case when insp_yr > 2016 AND insp_yr < 2022 then DtoG end) as DtoG_17_21, sum(case when insp_yr > 2017 then AtoC end) as AtoC_18_22, sum(case when insp_yr > 2017 then DtoG end) as DtoG_18_22, tenureclean
             FROM EPCprivatePivotByLAyrBandSCOT
             GROUP BY LOCAL_AUTHORITY_LABEL
             ORDER BY LOCAL_AUTHORITY_LABEL DESC")

#show
EPC5yrPrivatePivotByLASCOT
```


And export (because we're going to change it next).

```{r export EPC5yrPrivatePivotByLASCOT}
write.csv(EPC5yrPrivatePivotByLASCOT, "EPC5yrPrivatePivotByLASCOT.csv")
```

We can add a total too

```{r calculate total}
#from https://www.statology.org/r-add-total-row/
library(dplyr)

EPC5yrPrivatePivotByLASCOT <- EPC5yrPrivatePivotByLASCOT %>%
  bind_rows(summarise(., across(where(is.numeric), sum),
                         across(where(is.character), ~'Total')))
```


## Calculate percentages

Now we have the totals, but we want to convert those to percentages.

To do that, we are going to loop through each pair of columns for each time period (AtoC and DtoG for 2013-17, etc.), and divide them by the total. Then repalce the originals counts with the percentages.

```{r loop to calculate percs}
#we could make a copy of the data if we wanted at this point, before changing
EPC5yrPrivatePivotByLASCOTtotals <- EPC5yrPrivatePivotByLASCOT

#loop through every other number from 2 to 14
for(i in seq(2,14,2)){
  #print it
  print(i)
  #fetch the column at that index, and the next one
  #add all grades in the two columns (i.e. AtoC and DtoG for that year)
  yeartotal <- EPC5yrPrivatePivotByLASCOT[,i]+EPC5yrPrivatePivotByLASCOT[,i+1]
  #divide the first column by that total
  AtoCperc <- EPC5yrPrivatePivotByLASCOT[,i]/yeartotal
  #divide the second column by that total
  DtoGperc <- EPC5yrPrivatePivotByLASCOT[,i+1]/yeartotal
  #replace the original columns with the percentages
  EPC5yrPrivatePivotByLASCOT[,i] <- AtoCperc
  EPC5yrPrivatePivotByLASCOT[,i+1] <- DtoGperc
}

EPC5yrPrivatePivotByLASCOT
```

Let's also add another column which calculates the change between the first and last 5 year period.

```{r calculate change since start}
#subtract 13-17 from 18-22 for A to C
EPC5yrPrivatePivotByLASCOT$AtoCchangeSince13_17 <- EPC5yrPrivatePivotByLASCOT$AtoC_18_22 - EPC5yrPrivatePivotByLASCOT$AtoC_13_17

#subtract 13-17 from 18-22 for D to G
EPC5yrPrivatePivotByLASCOT$DtoGchangeSince13_17 <- EPC5yrPrivatePivotByLASCOT$DtoG_18_22 - EPC5yrPrivatePivotByLASCOT$DtoG_13_17
```

```{r export perc version}
write.csv(EPC5yrPrivatePivotByLASCOT, "EPC5yrPrivatePivotByLASCOT.csv")
```
