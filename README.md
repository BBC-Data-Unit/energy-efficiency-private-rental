# Renting: Six out of 10 renters live in energy-inefficient homes

![Map showing average home heat loss in different European countries: UK homes lose 3 degrees after five hours, higher than any other European country](https://ichef.bbci.co.uk/news/976/cpsprodpb/CBB3/production/_129274125_home_temperature_loss_map_v3_640-nc.png.webp)

In April 2022, the BBC Shared Data unit [reported](https://www.bbc.co.uk/news/newsbeat-65136313) that six out of 10 recently inspected UK rental homes failed to meet a proposed new standard for energy efficiency.

The project involved analysing over 94 million recommendations from 24 million inspections in England and Wales up to the end of 2022, as well as a further 1.5 million inspections in Scotland, and found:

* Out of 1.9 million lettings given EPC ratings in England and Wales over the last five full years (2018-22), 1.1 million, or 57%, were graded below a C.
* Some 5% of privately rented properties did not have the potential to reach grade ‘C’, according to assessors.
* A quarter of renters were using portable heaters as a secondary source of warmth in their homes.
* Insulation was the most frequently recommended improvement measure for private rental properties, making up 35% of all recommendations.
* Inspections of rental properties in the last five years found, on average, occupants could save almost a third (32%) on their current heating costs if their landlords made all the recommended improvements.
* London boroughs and coastal areas made up 9 of the top 10 local authorities by proportion of properties that did not have the potential to reach grade C. 



## Background and briefing

A [full briefing pack on the story can be found here](https://docs.google.com/document/d/15bqbvfRrsB4Wl65fzJNGQnNTf-jsUH_qthGZ1cUCPSw/edit#heading=h.eksa1piu3vo).

## Get the data

* Shared spreadsheet: [Energy efficiency in private rented accommodation](https://docs.google.com/spreadsheets/d/1-iCVMDG3DNkxoIVWmFQXlAOO5l4GYSCk9B0nESAK97g/edit?usp=sharing) (also as [an XLSX file here](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/data/SDU_Energy%20efficiency%20in%20private%20rented%20accommodation%20FOR%20SHARING.xlsx))
* England and Wales: [Open data on Energy Performance Certificates](https://epc.opendatacommunities.org)
* Scotland: [Domestic Energy Performance Certificates](https://statistics.gov.scot/data/domestic-energy-performance-certificates)
* Northern Ireland: [EPC data](https://docs.google.com/spreadsheets/d/1agvRoD5CbjKUpSm_XiyI81OC65o8S71OFJzeYMoNqM0/edit#gid=0) ([XLSX](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/data/Northern%20Ireland%20EPC%20data.xlsx)) via [a Freedom of Information request](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/data/Northern%20Ireland%20FOI%20response.pdf).
* The ONS provide data on [Energy efficiency of Housing, England and Wales, country and region](https://www.ons.gov.uk/peoplepopulationandcommunity/housing/datasets/energyefficiencyofhousingenglandandwalescountryandregion) which was used for contextual data on the proportion of property types covered by the EPCs, and for methodological guidance.

Full data on energy performance certificates (EPCs) is provided in a series of separate CSV files which was combined for analysis. For the England and Wales data, this was attempted [using an R script](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/scripts/energyeff01compile.md) and [command line](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/scripts/combineepc.sh). In addition, a [Python Colab notebook was written](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/scripts/epc_zip_file.ipynb) to unzip the files where there wasn't enough capacity on the computer. For the Scotland data data was combined using `cat` in command line. 

The resulting files were too large for data analysis in spreadsheets, R or Python, so they were uploaded to Google BigQuery for initial analysis and filtering [using SQL queries documented here](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/blob/main/scripts/Energy%20efficiency%20(private%20rental)_%20BigQuery%20SQL%20queries.pdf).

The results of that initial analysis were further analysed using R notebooks in the [scripts folder](https://github.com/BBC-Data-Unit/energy-efficiency-private-rental/tree/main/scripts).

## Visualisation

* Stacked bar chart: Local authorities in England and Wales with the highest proportion of properties given a D-G EPC rating, 2018-2022
* Map: Average home heat loss after five hours in 2020, by country (Europe)

## Interviews

* Louise, renter in Blackpool
* Adam Royal, 25, renter in Blackpool
* Rachelle Earwaker, senior economist, Joseph Rowntree Foundation
* Conal Land, case worker, Citizens Advice 
* Chris Norris, director of policy, National Residential Landlords Association
* Jonathan Winston, support manager, The Carbon Trust
* Spokesperson, Department for Business, Energy and Industrial Strategy

## Partner usage

The Shared Data Unit makes data journalism available to news organisations across the media industry, as part of a partnership between the BBC and the News Media Association. Stories generated by the partnership included:

* Andover Advertiser: [Half of private rentals in Test Valley would not meet energy standard](https://www.andoveradvertiser.co.uk/news/23461461.half-private-rentals-test-valley-not-meet-energy-standard/)
* Bristol Cable: [Revealed: Over half of Bristol’s rental homes would fail to meet proposed new energy efficiency standard](https://thebristolcable.org/2023/04/bristol-rental-homes-fail-energy-efficiency-standard/)
* Daily Express: [Could you be paying more for your bills? Areas with worst energy efficient homes MAPPED](https://www.express.co.uk/news/uk/1754377/energy-efficiency-map-heating-bills-spt)
* Hampshire Chronicle: [Half of rented homes in Winchester would fail to meet energy standard](https://www.hampshirechronicle.co.uk/news/23461361.half-rented-homes-winchester-fail-meet-energy-standard/)
* Lichfield Live: [ Figures reveal more than half of rental properties in Lichfield and Burntwood would fail to meet proposed new energy efficiency standard](https://lichfieldlive.co.uk/2023/04/06/figures-reveal-more-than-half-of-rental-properties-in-lichfield-and-burntwood-would-fail-to-meet-proposed-new-energy-efficiency-standard/)
* The Lochside Press: [74% of private rentals in Argyll and Bute would fail new energy standard](https://thelochsidepress.com/2023/04/06/74-of-private-rentals-in-argyll-and-bute-would-fail-new-energy-standard/)
* London World: [Cost of living: Most London homes fail to meet energy efficiency standard](https://www.londonworld.com/news/london-homes-miss-energy-efficiency-standard-4098151)
* This is Money: [Is YOUR town one of these 10 where homes leak the most heat? Areas with the most - and least - energy efficient properties are revealed](https://www.thisismoney.co.uk/money/bills/article-11937617/The-areas-energy-efficient-homes-cost-heat.html)
* The Scotsman: [Over half of rented properties in Scotland set to flout new energy efficiency rules](https://www.scotsman.com/news/environment/over-half-of-rented-properties-in-scotland-set-to-flout-new-energy-efficiency-rules-4095458)
* We Love Stornoway: ['Giant green-rules fail' for island renters](https://welovestornoway.com/index.php/home/welovesyhomepage-2/28293-isles-private-rentals-in-massive-energy-fail)


## Related repos

* In March 2020, the BBC Shared Data unit [reported that nearly two thirds of UK homes fail to meet long-term energy efficiency targets](https://github.com/BBC-Data-Unit/energy-efficiency-of-homes).
* All [stories related to housing can be found here](https://github.com/search?q=topic%3Ahousing+org%3ABBC-Data-Unit+fork%3Atrue&type=repositories)
