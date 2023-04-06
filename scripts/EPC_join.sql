#see the PDF for all SQL queries. This joins EPC certificate data with recommendations data.

#we use a. here and b. below to prefix the field because later on we rename each table a and b
SELECT a.LMK_KEY, 
  a.INDICATIVE_COST, 
  #Most have a £ but some don't so £* means 'none or more'
  #followed by none or more numbers: [0-9]*
  #followed by none or more commas: ,*
  #followed by one or more numbers: [0-9]+
  #remove £ and , and convert to a number
  CAST(REPLACE(REPLACE(REGEXP_EXTRACT(INDICATIVE_COST, "£*[0-9]*,*[0-9]+"),"£",""),",","") AS INT) AS lowercost, 
  #as above but with $ at the end to indicate 'at the end of the string'
  CAST(CAST(REPLACE(REPLACE(REGEXP_EXTRACT(INDICATIVE_COST, "£*[0-9]*,*[0-9]+\\.*[0-9]*$"),"£",""),",","") AS FLOAT64) AS INT) AS uppercost, 
  a.IMPROVEMENT_DESCR_TEXT, 
  a.IMPROVEMENT_ID, 
  a.IMPROVEMENT_ID_TEXT, 
  a.IMPROVEMENT_ITEM, 
  a.IMPROVEMENT_SUMMARY_TEXT,
  EXTRACT(YEAR FROM b.INSPECTION_DATE) AS insp_yr,
  #again, b. here is used to indicate the second table
  b.LOCAL_AUTHORITY_LABEL,
  b.TENURE,
  b.UPRN,
  b.POSTCODE,
  b.CURRENT_ENERGY_RATING,
  b.POTENTIAL_ENERGY_RATING,
  b.ENERGY_CONSUMPTION_CURRENT,
  b.ENERGY_CONSUMPTION_POTENTIAL,
  COUNT(*)
#this is where we rename this table as a
FROM `datacamp-287416.tweetsatmps_month1.EPC_recscombined` a
#rename this as b
LEFT JOIN `datacamp-287416.tweetsatmps_month1.certificatescombined` b 
#so it's easier to then name the fields we are joining on
ON (a.LMK_KEY = b.LMK_KEY) 
#filter years before 2012
WHERE EXTRACT(YEAR FROM b.INSPECTION_DATE) > 2011
#we have to name all the fields in the GROUP command
GROUP BY a.LMK_KEY, 
  a.INDICATIVE_COST, 
  lowercost,
  uppercost,
  a.IMPROVEMENT_DESCR_TEXT, 
  a.IMPROVEMENT_ID, 
  a.IMPROVEMENT_ID_TEXT, 
  a.IMPROVEMENT_ITEM, 
  a.IMPROVEMENT_SUMMARY_TEXT,
  insp_yr,
  b.TENURE,
  b.UPRN,
  b.BUILDING_REFERENCE_NUMBER,
  b.POSTCODE,
  b.CURRENT_ENERGY_RATING,
  b.POTENTIAL_ENERGY_RATING,
  b.ENERGY_CONSUMPTION_CURRENT,
  b.ENERGY_CONSUMPTION_POTENTIAL,
  b.LOCAL_AUTHORITY_LABEL
#put the most recent years top, and then the largest numbers of inspections
ORDER BY insp_yr DESC, 
  COUNT(*) ASC
