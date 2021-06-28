########################################################################################
# GMWO API Example - Getting variable data                                             #
# For more explanation of the steps, see readme.md                                     #
#                                                                                      #  
# Prerequisites:                                                                       #  
# - R installed                                                                        #
# - RStudio installed                                                                  #    
# - a GMWO access token, see https://model.oxfordeconomics.com/api/docs#authentication #
########################################################################################


# import modules
require('httr')
require('jsonlite')
require('comprehenr')

# program constants
# note: ACCESS_TOKEN must be set below
#
ACCESS_TOKEN <- ''
AUTHORIZATION_HEADER_VALUE <- paste('Bearer', ACCESS_TOKEN,sep = " ")
BASE <- "https://model.oxfordeconomics.com/api"


get_Request<- function(endpoint, authorization_header_value)
{
    response <-GET(endpoint, add_headers("Authorization" = authorization_header_value))

    json_response <- parse_json(response)

    return(json_response)
}

get_Resources <- function(resourceId)
{
    endpoint <- paste(BASE,'/v1/resources/', resourceId, sep="" )    
    
    return(get_Request(endpoint, AUTHORIZATION_HEADER_VALUE))
}

get_Indicators <- function(forecastId)
{
    endpoint <- paste(BASE,'/v1/forecast-contents/', forecastId, '/indicators',sep="")

    return(get_Request(endpoint, AUTHORIZATION_HEADER_VALUE))
}

get_Locations <- function(forecastId)
{
    endpoint <- paste(BASE, '/v1/forecast-contents/', forecastId, '/groups', sep="")
   
    return(get_Request(endpoint, AUTHORIZATION_HEADER_VALUE))
}

get_VariableData <- function(forecastId, locations, indicators)
{
    body <- to_list(for(group in locations) for(indicator in indicators) list(IndicatorCode=indicator$Code, GroupCode=group$Code))

    endpoint <- paste(BASE, '/v1/forecast-contents/', forecastId, '/model-variables', sep="")
    response <- POST(
        endpoint,
        body = body, 
        add_headers("Authorization" = AUTHORIZATION_HEADER_VALUE),
        query= list(onlyProps = "Values,Metadata"),
        encode="json"
    )
    data <- parse_json(response)
    
    return(data)
}

# get a list of forecasts
resources <- get_Resources("oxford-economics/releases/GEM")

# get the first forecast from the macro releases
forecastId <- resources$Children[[1]]$Id[1]

# get list of indicators
indicators <- head(get_Indicators(forecastId), 5) # use only first 5 indicators

# get list of locations(groups)
locations <- head(get_Locations(forecastId), 5) # use only first 5 locations (groups)

# get variable data
raw_data <- get_VariableData(forecastId, locations, indicators)

print(raw_data)

