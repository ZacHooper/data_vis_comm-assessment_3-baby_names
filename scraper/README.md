# Vic Baby Names Scraper

It is not possible to download the full dataset in one go so I will need to scrape all the data down from the API and store it in a datafile locally. The dataset is from 2008 to 2020 so there is 12 years of data. Names are either MALE or FEMALE so there should be 2600 (13 actual recorded years) rows of data. 

To keep the scraper simple it will make a request to the API for the top 100 names for a single gender in a single year. Theoretically that should mean 26 requests to the API. The API is limited to 25 requests per minute so the whole scrape time should take just over a minute. 

## Flow
1. Start with year 2008
2. Make a request to the API for the top 100 MALE names
3. Store the returned results in a list (possibly Pandas DataFrame)
4. Make a request to the API for the top 100 FEMALE names 
5. Store the returned results in a list (possibly Pandas DataFrame)
6. Repeat until all years have been retrieved

## MISC Notes
- In order to be a _good_ API user a rate limit has been used on the API function to ensure that we don't exceed the 25 requests a minute.
- If you want to replicate or use this scraper you will need to register for your own API key with the Vic Gov Data website: https://www.developer.vic.gov.au/
  - I am pulling my API key locally from a different module `mysecrets.py` under the variable name `API_KEY`
  - You may recreate this locally yourself or simply overwrite `mysecrets.API_KEY` in the request header with your API Key and remove the `mysecrets` import.