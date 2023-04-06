---
title: "Compiling energy efficiency data"
output: html_notebook
---

# Analysing energy efficiency data: compiling the data

This notebook details the process of analysing data on energy efficiency in thousands of households across the UK. 

Data is available at https://epc.opendatacommunities.org/domestic/search - you need to register/sign in. You can then select a particular local authority or constituency and download data for that - or you can download the full 23.5m-row dataset (if you try to select a specific date range it will only allow you to download a sample of 5,000 rows).

The full dataset is a 4.5GB file which unzips to a 36.5GB folder with a subfolder for each local authority, each containing two CSVs.

We've extracted data for over 340 local authorities into a folder called 'all-domestic-certificates'. However, as data for each authority is stored in a separate subfolder (e.g. 'domestic-E06000001-Hartlepool'), we need to bring that data together in order to analyse and compare it.

A further complication is that combining all the CSV files would probably create an unwieldy and inconveniently large file, so we need to ensure the size of any resulting file is as small as we can get it: a couple of strategies we could adopt include:

* Remove unnecessary columns 
* Narrow our focus to data within a particular timescale.

*Note: We can also use command line. In fact, after attempting the approach detailed below, which took too long for code to execute, we switched to a command line approach. The code for that is shown below:*


```{bash command line version}
echo "changing into the all-domestic-certificates folder"
cd all-domestic-certificates
echo "looking for EPC CSV files in folders beginning 'domestic'"
find domestic* -name "certificates.csv"
echo "copying, moving and renaming those files into the current directory"
num=0; for i in `find output_dir -name "certificates.csv"`; do cp "$i" "$(printf '%03d' $num).${i#*.}"; ((num++)); done
echo "combining all the files into one"
cat *.csv > certificatescombined.csv
```


## Install libraries

First, let's install `pacman` as this can then be used to install other packages if they're not already installed.

```{r install pacman and tidyverse}
#install pacman if it's not installed
if (!require("pacman")) install.packages("pacman")
#install tidyverse if it's not installed
pacman::p_load(tidyverse)
#We don't have to prefix with the package name pacman:: but I feel this makes it easier to understand where a function comes from

#Now sqldf
pacman::p_load(sqldf)

```


## Import and combine data

We can generate a list of folders using the `list.files()` function.

```{r store a list of folders}
#create a variable containing a list of the folders
folderlist <- list.files('all-domestic-certificates')
#show the first 5
folderlist[2:5]
```
We know that one file is a text file. We need to remove that from our list.

```{r remove last file}
#show the 344th item in that vector variable
folderlist[344]
#remove it from the vector
folderlist <- folderlist[-344]
```

Every folder has two CSVs, with the same names.

```{r show files in two folders}
list.files('all-domestic-certificates/domestic-E06000001-Hartlepool')
list.files('all-domestic-certificates/domestic-E06000002-Middlesbrough')
```


We can then loop through that list and fetch the files within each folder. We use the `read_csv()` function from the `readr` package, part of the `tidyverse` collection we imported at the start of this notebook. This is faster than base R's `read.csv()` package.

We limit the loop to the next 9 folder (index 2 to index 10) for now, so we can test a subset.

```{r import CSVs from subfolders}
#import one CSV to form the dataframe that we can add others to
certsdf <- readr::read_csv('all-domestic-certificates/domestic-_unknown_local_authority--Unknown-Local-Authority-/certificates.csv')
#loop through the list of folders - we limit it to the next 9 for now
for (i in folderlist[2:10]){
  #create a path to the certificates CSV in the particular subfolder
  fullpath <- paste0('all-domestic-certificates/',i,'/certificates.csv')
  #import that file
  tempdf <- readr::read_csv(fullpath)
  #append to the ongoing file
  certsdf <- rbind(certsdf, tempdf)
}
```

We can use `table()` to get an overview of values in the `LOCAL_AUTHORITY` field of the data. 

```{r show a table of LAs}
#The first dataframe/CSV is for unknown LAs and this column is empty so we will not have any value for that CSV
table(certsdf$LOCAL_AUTHORITY)
#As well as codes we have names 
table(certsdf$LOCAL_AUTHORITY_LABEL)
```
## Reduce the size of the dataframe

There are 92 fields/variables in this dataframe. We don't need all of them. 

```{r show column names}
colnames(certsdf)
```

We are specifically interested in data about energy consumption and efficiency, including breakdowns for lighting, heating and hot water cost. We also need all the contextual data about location, local authority and tenure - and unique identifiers for any future matching.

There is also some interesting data here with further breakdowns on things like glazing type, roof, etc. but we will leave that for a separate analysis.

```{r show column names we want}
colnames(certsdf)[c(1:18,21:22,26:31,83:88)]
```
Now we've identified the columns we want, we can create a subset of just those. Again we use `readr` and its `write_csv()` function because it's faster than base R's `write.csv()` and doesn't include row names.

```{r create and export subset}
#subset to specified column indices
certssubset <- certsdf[,c(1:18,21:22,26:31,83:88)]
#export a CSV of the full dataframe
readr::write_csv(certsdf,"certsfull.csv")
#and one of the subset
readr::write_csv(certssubset,"certssubset.csv")
```

Exporting the two dataframes as CSVs allows us to see how much we've reduced the file by: it's by around two-thirds (176MB compared to 530MB), which makes sense given we've removed 60 of 92 columns.

Using `write_csv` also saves us extra memory: `read.csv()` creates files that are more than 10% larger (200MB and 590MB).

## Importing all the data

We can specify those columns while importing, too, using the `col_select=` argument in `read_csv()`.

Because we're using another argument, I've named the first argument (`file=`) too for clarity.

```{r import CSVs but with 32 cols}
#import one CSV to form the dataframe that we can add others to
certssubset <- readr::read_csv(
  file = 'all-domestic-certificates/domestic-_unknown_local_authority--Unknown-Local-Authority-/certificates.csv', 
  col_select=c(1:18,21:22,26:31,83:88)
  )
#loop through the list of folders - we limit it to the next 9 for now
for (i in folderlist){
  #create a path to the certificates CSV in the particular subfolder
  fullpath <- paste0('output_dir/',i,'/certificates.csv')
  #import that file
  tempdf <- readr::read_csv(file = fullpath, 
                            col_select=c(1:18,21:22,26:31,83:88))
  #append to the ongoing file
  certssubset <- rbind(certssubset, tempdf)
}
```
  
Once imported, we can check which local authorities are represented. If we've stopped the import partway through, we can see how far it got.

```{r table of LAs}
table(certssubset$LOCAL_AUTHORITY_LABEL)
lacount <- data.frame(table(certssubset$LOCAL_AUTHORITY_LABEL)) 
lacodecount <- data.frame(table(certssubset$LOCAL_AUTHORITY)) 
constcount <- data.frame(table(certssubset$CONSTITUENCY_LABEL))
```

## How many C+ rated properties in each LA?

Even with a partial dataset we can start to do some analysis. For example, one topical angle would be to follow up on [this story](https://www.bigissue.com/news/housing/private-renters-energy-efficiency-plans-dropped-government/):

> "The Department for Business, Energy and Industrial Strategy (BEIS) launched a consultation in September 2020 on ‘Improving the Energy Performance of Privately Rented Homes in England and Wales’.

> "It proposed a target that all new tenancies in the private rented sector should be in a property with an energy performance certificate (EPC) rating of at least a ‘C’ by 2025. It also proposed for this to be extended to cover all tenancies in the sector by 2028.

> "But despite the consultation closing in January 2021, the government has yet to provide any public response two years on, leading many to suggest the plans have been abandoned."

What proportion of private rental properties, then, would currently meet that target? (A scale story) And how much does that vary between local authorities? (A variation story) In which local authorities is the challenge biggest? (Ranking) Which ones are success stories and why? (Leads) Are things improving, and at what rate? (Change)

If we are interested in the current situation we need to be aware of the fact that the data covers historical data too. How historical?

```{r summarise date range}
summary(certssubset$INSPECTION_DATE)
```

### Filter out ratings from older dates

To narrow down to more recent inspections, we will need to deal with dates. Luckily the INSPECTION_DATE column has been stored as a date and we can filter it using `filter()` from the tidyverse's `dplyr` package.

```{r filter to last 5 years}
last5years <- certssubset %>% 
  dplyr::filter(INSPECTION_DATE > '2018-01-01')
```

### Calculate proportion of properties with C or above

We can now see what the ener gy ratings are like for properties inspected during that period.

```{r table energy ratings}
table(last5years$CURRENT_ENERGY_RATING)
```

Let's make life easier for ourselves by counting how many As, Bs, and Cs there are together.

```{r count ABC}
#We could use a simple == logical match but could only do it one letter at a time
Acount <- sum(last5years$CURRENT_ENERGY_RATING == "A")
#We could use str_detect with regex
ABCcount <- sum(str_detect(last5years$CURRENT_ENERGY_RATING, "A|B|C"))
#grepl also allows us to use regex
ABCcount <- sum(grepl("A|B|C",last5years$CURRENT_ENERGY_RATING))
DtoGcount <- sum(grepl("D|E|F|G",last5years$CURRENT_ENERGY_RATING))
#What's that as a percentage?
ABCcount/nrow(last5years)
DtoGcount/nrow(last5years)
```

### Calculate results for private rental

That's all properties - what about private rental specifically? 

The column we need to filter on is TENURE - but this needs some cleaning.

```{r table for tenure}
table(last5years$TENURE)
```

We need to include both terms for private rental in our `filter()` function by using the `%in%` operator.

```{r filter to private rental}
last5yrs_pr <- last5years %>% 
  dplyr::filter(TENURE %in% c("Rented (private)","rental (private)"))
```

Now to calculate the proportion for that subset.

```{r count A-C ratings}
#grepl also allows us to use regex
ABCcount <- sum(grepl("A|B|C",last5yrs_pr$CURRENT_ENERGY_RATING))
DtoGcount <- sum(grepl("D|E|F|G",last5yrs_pr$CURRENT_ENERGY_RATING))
#What's that as a percentage?
ABCcount/nrow(last5yrs_pr)
DtoGcount/nrow(last5yrs_pr)
```

### Calculate ratings by LA

So the figure across all the LAs in the dataset is 40%. We've previously done an analysis of Stockton where the figure was 50%, so that suggests quite a lot of potential variation.

Let's calculate the same figure for each LA. 

Start by simplifying our data to count the numbers of ratings in each band by LA. We use the library `sqldf` and its identically-named function `sqldf()` to write a SQL query that does that.

```{r simplify}
#run the sql query and store the results in a new dataframe
ratingsbyla <- sqldf::sqldf('SELECT LOCAL_AUTHORITY_LABEL, CURRENT_ENERGY_RATING, COUNT(CURRENT_ENERGY_RATING) AS ratingcount
             FROM last5yrs_pr
             GROUP BY LOCAL_AUTHORITY_LABEL, CURRENT_ENERGY_RATING')
#show the results
head(ratingsbyla)
```

```{r export ratings by la csv}
write.csv(ratingsbyla, "ratingsbyla.csv")
```

## Import just the ratings and LA and date

Can we speed up our combination of CSVs by limiting to just the columns we need for this analysis? Local authority name and code, date, tenure, and rating?

Not quite: this still takes a long time to run - more than a day - but eventually we do get something.

```{r import CSVs but with 3 cols}
#import one CSV to form the dataframe that we can add others to
certsjustrating <- readr::read_csv(
  file = 'all-domestic-certificates/domestic-_unknown_local_authority--Unknown-Local-Authority-/certificates.csv', 
  col_select=c(1,7,13,14,83,88)
  )
#loop through the list of folders - we skip the first
for (i in folderlist[2:343]){
  #create a path to the certificates CSV in the particular subfolder
  fullpath <- paste0('all-domestic-certificates/',i,'/certificates.csv')
  #import that file
  tempdf <- readr::read_csv(file = fullpath, 
                            col_select=c(1,7,13,14,83,88))
  #append to the ongoing file
  certsjustrating <- rbind(certsjustrating, tempdf)
}
```

We can check if the code has worked by creating a table of all the local authority names.

```{r table of LA names}
lalist <- data.frame(table(certsjustrating$LOCAL_AUTHORITY_LABEL))
```

## Export for BigQuery

The resulting table is 24m rows long. We can query it, but given its size it's worth exporting as a CSV straight away for use in a tool designed for dealing with such large datasets, e.g. BigQuery.

We use readr's write_csv() function because it generates a smaller file than base write.csv(). This also takes quite some time to run. 

```{r export certsjustrating}
readr::write_csv(certsjustrating, "certsjustrating.csv")
```

In BigQuery we can run SQL queries. For comparison, here's one to see how long it takes to run:

```{r sql count by LA}
#store SQL query as a string
q_countbyLA <- "SELECT LOCAL_AUTHORITY_LABEL, count(*) as certs_count FROM certsjustrating GROUP BY LOCAL_AUTHORITY_LABEL ORDER BY LOCAL_AUTHORITY_LABEL"

#store the system time
start_time <- Sys.time()
#run SQL query
sqldf::sqldf(q_countbyLA)
#calculate the time elapsed
end_time <- Sys.time()
totaltime <- end_time - start_time
totaltime
```




