---
title: "EPC_potential_byLA_SCOTLAND"
output: html_document
date: "2023-03-15"
---

# Analysing the proportion of properties that cannot achieve C ratings for energy efficiency by area

We've combined data on 1.6m performance certificates using command line. Now we need to import and analyse it.

```{r import 10 years data}
#we skip one row because the headers are repeated
allepcSCOTLAND <- rio::import("scotland/allepcSCOTLAND.csv", 
                              skip = 1, 
                              header = T)
```

We check the column names. 

```{r show col names}
#show columns
print(colnames(allepcSCOTLAND))

```

```{r check date col}
#summarise the date column - is it treated as a date?
summary(allepcSCOTLAND$INSPECTION_DATE)
#print one entry
(allepcSCOTLAND$INSPECTION_DATE[2])
#extract the first 4 chars
substr(allepcSCOTLAND$INSPECTION_DATE[2],1,4)
```
```{r}
testdf <- sqldf::sqldf("SELECT POTENTIAL_ENERGY_RATING, COUNT(*) AS certs
                       FROM allepcSCOTLAND
                       GROUP BY POTENTIAL_ENERGY_RATING")

testdf
```



```{r}
query1 <- "SELECT POTENTIAL_ENERGY_RATING, COUNT(*) as certs_total, LEFT(INSPECTION_DATE, 4) AS insp_yr, LOCAL_AUTHORITY_LABEL, TENURE FROM allepcSCOTLAND
WHERE insp_yr > 2012 AND TENURE LIKE '%rivat%'
GROUP BY insp_yr, LOCAL_AUTHORITY_LABEL, POTENTIAL_ENERGY_RATING, TENURE
ORDER BY LOCAL_AUTHORITY_LABEL DESC, insp_yr "
testdf <- sqldf::sqldf(query1)
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


## Add 5 year band categories

We can repeat this process to aggregate data based on its year range.

```{r pivot by 5 year groups}
#see https://stackoverflow.com/questions/11724953/creating-multiple-columns-from-one-column
#and https://stackoverflow.com/questions/14630984/how-do-i-do-multiple-case-when-conditions-using-sql-server-2008
EPCprivatePivotByLApotGradeBand_yrBand <- sqldf::sqldf("SELECT LOCAL_AUTHORITY_LABEL, sum(case when insp_yr > 2011 AND insp_yr < 2017 then AtoC end) as AtoC_12_16, sum(case when insp_yr > 2011 AND insp_yr < 2017 then DtoG end) as DtoG_12_16, sum(case when insp_yr > 2012 AND insp_yr < 2018 then AtoC end) as AtoC_13_17, sum(case when insp_yr > 2012 AND insp_yr < 2018 then DtoG end) as DtoG_13_17, sum(case when insp_yr > 2013 AND insp_yr < 2019 then AtoC end) as AtoC_14_18, sum(case when insp_yr > 2013 AND insp_yr < 2019 then DtoG end) as DtoG_14_18, sum(case when insp_yr > 2014 AND insp_yr < 2020 then AtoC end) as AtoC_15_19, sum(case when insp_yr > 2014 AND insp_yr < 2020 then DtoG end) as DtoG_15_19, sum(case when insp_yr > 2015 AND insp_yr < 2021 then AtoC end) as AtoC_16_20, sum(case when insp_yr > 2015 AND insp_yr < 2021 then DtoG end) as DtoG_16_20, sum(case when insp_yr > 2016 AND insp_yr < 2022 then AtoC end) as AtoC_17_21, sum(case when insp_yr > 2016 AND insp_yr < 2022 then DtoG end) as DtoG_17_21, sum(case when insp_yr > 2017 then AtoC end) as AtoC_18_22, sum(case when insp_yr > 2017 then DtoG end) as DtoG_18_22, tenureclean
             FROM EPCprivatePivotByLApotGradeBand
             GROUP BY LOCAL_AUTHORITY_LABEL
             ORDER BY LOCAL_AUTHORITY_LABEL DESC")

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

#loop through every other number from 2 to 14
for(i in seq(2,14,2)){
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

