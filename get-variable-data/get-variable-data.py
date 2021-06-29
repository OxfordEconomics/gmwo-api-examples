########################################################################################
# GMWO API Example - Getting variable data                                             #
# For more explanation of the steps, see readme.md                                     #
#                                                                                      #  
# Prerequisites:                                                                       #  
# - Python 3 installed                                                                 #
# - 'requests' package installed                                                       #    
# - a GMWO access token, see https://model.oxfordeconomics.com/api/docs#authentication #
########################################################################################

import requests

base_url = 'https://model.oxfordeconomics.com/api'
access_token = <insert your access token here>
headers = {'Authorization' : f'Bearer {access_token}'}

# Discover the id of a Global Economic Model release forecast
gemFolderResponse = requests.get(f"{base_url}/v1/resources/oxford-economics/releases/GEM", headers=headers)
gemFolder = gemFolderResponse.json()
forecastId = gemFolder["Children"][0]["Id"] # Pick first forecast

# Get all indicators for a forecast
indicatorsResponse = requests.get(f"{base_url}/v1/forecast-contents/{forecastId}/indicators", headers=headers)
indicators = indicatorsResponse.json()

 # Get all groups (locations) for a forecast
groupsResponse = requests.get(f"{base_url}/v1/forecast-contents/{forecastId}/groups", headers=headers)
groups = groupsResponse.json()

# Get variable values
indicatorCodes = map(lambda indicator: indicator["Code"], indicators[0:4]) # Pick first 4 indicators
groupCodes = map(lambda group: group["Code"], groups[0:4]) # Pick first 4 groups
variableSelection = [ { "IndicatorCode": indicatorCode, "GroupCode": groupCode } for indicatorCode in indicatorCodes for groupCode in groupCodes]
variablesResponse = requests.post(f"{base_url}/v1/forecast-contents/{forecastId}/variables?onlyProps=Values,Metadata", headers=headers, json=variableSelection)

print(variablesResponse.json())
