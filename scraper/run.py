"""
This scraper scrapes the API of the Popular Baby Names Victoria API: https://www.developer.vic.gov.au/index.php?option=com_apiportal&view=apitester&usage=api&managerId=1&apiName=Popular%20Baby%20Names%20Victoria%20API&apiId=1c3356c4-9e9e-4aeb-b766-4f8480d486c1&apiVersion=1.0.0&type=rest&menuId=153#!/v1.0/GET_popular_baby_names

The scraper will pull down all the names and their ranks between the years of 2008 and 2020 whilst ensuring it remains within the API's rate limits. 

Author: Zac Hooper
Email: zac.g.hooper@gmail.com

"""

import mysecrets
import requests
import pandas as pd
from ratelimit import limits, sleep_and_retry

URL = "https://wovg-community.gateway.prod.api.vic.gov.au/bdm/names/v1.0/popular-baby-names"

@sleep_and_retry
@limits(calls=25, period=60)
def get_top_100_baby_names(gender, year):
    """Gets the top 100 baby names for the given gender and year. Returns the names a list of dicts.
    Each item will detail the _position_ the name was ranked, the _name_, the _count_ of how many children were given the name, the _sex_ of the child with the name and the _year_ the name was given.  

    Args:
        gender (str): Either MALE or FEMALE
        year (int): an Int between 2008 & 2020
    """
    r = requests.get(URL, params={"sex":gender,"year":year}, headers={"apikey": mysecrets.API_KEY})
    data = r.json()
    return data['popular_baby_names']

total_list = []
for year in range(2008, 2021):
    print(f"Getting names for {year}")
    # Make API call for MALE
    male_names = get_top_100_baby_names("MALE", year)

    # Make API call for FEMALE
    female_names = get_top_100_baby_names("FEMALE", year)

    # Add data to total list
    total_list += male_names
    total_list += female_names

# Write total list to a CSV file
df = pd.DataFrame(total_list).to_csv('data.csv')