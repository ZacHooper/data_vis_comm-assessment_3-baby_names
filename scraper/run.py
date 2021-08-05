from requests.api import get
import mysecrets
import requests
import pandas as pd
import json
from ratelimit import limits, sleep_and_retry


URL = "https://wovg-community.gateway.prod.api.vic.gov.au/bdm/names/v1.0/popular-baby-names"

@sleep_and_retry
@limits(calls=25, period=60)
def get_top_100_baby_names(gender, year):
    """Get's the top 100 baby names for the given gender and year. Returns the names a list of dicts.
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