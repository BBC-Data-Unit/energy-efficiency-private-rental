## echo "changing into the all-domestic-certificates folder"

## cd all-domestic-certificates

## echo "looking for EPC CSV files in folders beginning 'domestic'"

## find domestic* -name "certificates.csv"

## echo "copying, moving and renaming those files into the current directory"

## num=0; for i in `find output_dir -name "certificates.csv"`; do cp "$i" "$(printf '%03d' $num).${i#*.}"; ((num++)); done

## echo "combining all the files into one"

## cat *.csv > certificatescombined.csv


## ----install pacman and tidyverse----------------------------------------------
#install pacman if it's not installed
if (!require("pacman")) install.packages("pacman")
#install tidyverse if it's not installed
pacman::p_load(tidyverse)
#We don't have to prefix with the package name pacman:: but I feel this makes it easier to understand where a function comes from

#Now sqldf
pacman::p_load(sqldf)



## ----store a list of folders---------------------------------------------------
#create a variable containing a list of the folders
folderlist <- list.files('all-domestic-certificates')
#show the first 5
folderlist[2:5]


## ----remove last file----------------------------------------------------------
#show the 344th item in that vector variable
folderlist[344]
#remove it from the vector
folderlist <- folderlist[-344]


## ----show files in two folders-------------------------------------------------
list.files('all-domestic-certificates/domestic-E06000001-Hartlepool')
list.files('all-domestic-certificates/domestic-E06000002-Middlesbrough')


## ----import CSVs from subfolders-----------------------------------------------
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


## ----show a table of LAs-------------------------------------------------------
#The first dataframe/CSV is for unknown LAs and this column is empty so we will not have any value for that CSV
table(certsdf$LOCAL_AUTHORITY)
#As well as codes we have names 
table(certsdf$LOCAL_AUTHORITY_LABEL)


## ----show column names---------------------------------------------------------
colnames(certsdf)


## ----show column names we want-------------------------------------------------
colnames(certsdf)[c(1:18,21:22,26:31,83:88)]


## ----create and export subset--------------------------------------------------
#subset to specified column indices
certssubset <- certsdf[,c(1:18,21:22,26:31,83:88)]
#export a CSV of the full dataframe
readr::write_csv(certsdf,"certsfull.csv")
#and one of the subset
readr::write_csv(certssubset,"certssubset.csv")


## ----import CSVs but with 32 cols----------------------------------------------
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


## ----table of LAs--------------------------------------------------------------
table(certssubset$LOCAL_AUTHORITY_LABEL)
lacount <- data.frame(table(certssubset$LOCAL_AUTHORITY_LABEL)) 
lacodecount <- data.frame(table(certssubset$LOCAL_AUTHORITY)) 
constcount <- data.frame(table(certssubset$CONSTITUENCY_LABEL))


## ----summarise date range------------------------------------------------------
summary(certssubset$INSPECTION_DATE)


## ----filter to last 5 years----------------------------------------------------
last5years <- certssubset %>% 
  dplyr::filter(INSPECTION_DATE > '2018-01-01')


## ----table energy ratings------------------------------------------------------
table(last5years$CURRENT_ENERGY_RATING)


## ----count ABC-----------------------------------------------------------------
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


## ----table for tenure----------------------------------------------------------
table(last5years$TENURE)


## ----filter to private rental--------------------------------------------------
last5yrs_pr <- last5years %>% 
  dplyr::filter(TENURE %in% c("Rented (private)","rental (private)"))


## ----count A-C ratings---------------------------------------------------------
#grepl also allows us to use regex
ABCcount <- sum(grepl("A|B|C",last5yrs_pr$CURRENT_ENERGY_RATING))
DtoGcount <- sum(grepl("D|E|F|G",last5yrs_pr$CURRENT_ENERGY_RATING))
#What's that as a percentage?
ABCcount/nrow(last5yrs_pr)
DtoGcount/nrow(last5yrs_pr)


## ----simplify------------------------------------------------------------------
#run the sql query and store the results in a new dataframe
ratingsbyla <- sqldf::sqldf('SELECT LOCAL_AUTHORITY_LABEL, CURRENT_ENERGY_RATING, COUNT(CURRENT_ENERGY_RATING) AS ratingcount
             FROM last5yrs_pr
             GROUP BY LOCAL_AUTHORITY_LABEL, CURRENT_ENERGY_RATING')
#show the results
head(ratingsbyla)


## ----export ratings by la csv--------------------------------------------------
write.csv(ratingsbyla, "ratingsbyla.csv")


## ----import CSVs but with 3 cols-----------------------------------------------
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


## ----table of LA names---------------------------------------------------------
lalist <- data.frame(table(certsjustrating$LOCAL_AUTHORITY_LABEL))


## ----export certsjustrating----------------------------------------------------
readr::write_csv(certsjustrating, "certsjustrating.csv")


## ----sql count by LA-----------------------------------------------------------
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

