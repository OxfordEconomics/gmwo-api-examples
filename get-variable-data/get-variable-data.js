//########################################################################################
//# GMWO API Example - Getting variable data                                             #
//# For more explanation of the steps, see readme.md                                     #
//#                                                                                      #
//# Requirements:                                                                        #  
//# - a GMWO access token, see https://model.oxfordeconomics.com/api/docs#authentication #
//########################################################################################

const baseUrl = "https://model.oxfordeconomics.com/api/v1";
const headers = { 'Authorization': 'Bearer { ACCESS_TOKEN }' };

// Get forecasts to discover the forecast's id
async function getForecasts() {
    // Getting forecasts for the global economic model
    let forecasts = await fetch(`${baseUrl}/resources/oxford-economics/releases/GEM?includeAllFileTypes=false`, {
        headers
        });
    return forecasts.data;
}

// Get indicators from a forecast with a known id
async function getIndicators(forecastId) {
    let indicators = await fetch(`${baseUrl}/forecast-contents/${forecastId}/indicators`, {
        headers
    });

    return indicators.data;
}

// Get the groups (locations) from a forecast with a known id
async function getGroups(forecastId) {
    let groups = await fetch(`${baseUrl}/forecast-contents/${forecastId}/groups`, {
        headers
    });

    return groups.data;
}

// Get info for individual series
async function getVariableInfo(forecastId) {
    // Specify variable keys for relevant series
    const requestKeys =  [
        {
          "GroupCode": "US",
          "IndicatorCode": "GDP"
        },
        {
          "GroupCode": "CHINA",
          "IndicatorCode": "C"
        }
    ];

    // Specify values and metadata only:
    const onlyProps = "Values,Metadata";

    const variableInfo = await fetch(`${baseUrl}/forecast-contents/${forecastId}/model-variables?onlyProps=${onlyProps}`, {
        method: 'POST',
        headers: {
            ...headers,
            'Content-Type': 'application/json'
        },
        data: requestKeys
    });

    return variableInfo.data;
}