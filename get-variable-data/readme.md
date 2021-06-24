# GMWO API Example: Getting variable data

The following code snippets use the curl command line utility. See [`http://curl.haxx.se/`](http://curl.haxx.se/) for details on downloading and using curl.

 ### Authentication
 
 You can find out how to get your access token in the [authentication section of our API Guide](https://model.oxfordeconomics.com/api/docs/#authentication).


 ## Discover forecast id

To list forecasts within a specific directory, use `GET v1/resources/{identifier}` endpoint. 
 For example, to list all Oxford Economics Global Economic Model releases, `GET v1/resources/oxford-economics/releases/GEM`

 ``` curl
 curl -X GET "https://model.oxfordeconomics.com/api/v1/resources/oxford-economics/releases/GEM?includeAllFileTypes=false" -H  "accept: application/json" -H  "Authorization: Bearer { ACESSS_TOKEN }"
 ```

<details>
<summary> GET v1/resources/oxford-economics/releases/GEM response  </summary>

``` json
{
  "Type": "Directory",
  "Children": [  

    /// THE NUMBER OF CHILDREN HAS BEEN DELIBERATELY TRUNCATED FOR BREVITY IN THIS EXAMPLE  
    {
      "Type": "Forecast",
      "EconomicDomain": "MACRO",
      "ForecastUrl": "/v1/forecasts/=7ae5918b-f6e2-4d85-b5f8-196cf6de2fff",
      "Versions": [
        {
          "Name": "Jun21_25yr",
          "EconomicDomain": "MACRO",
          "Range": {
            "From": "1980Q1",
            "To": "2050Q4"
          },
          "Id": "8f1273b2-1135-4ca8-a3eb-47e6d500e142",
          "Version": 0,
          "CreatedAt": "2021-06-09T11:29:09+00:00"
        },
        {
          "Name": "Jun21_25yr",
          "EconomicDomain": "MACRO",
          "Range": {
            "From": "1980Q1",
            "To": "2050Q4"
          },
          "Id": "29fb11db-0de2-43dd-ba19-7fb9d9e5c641",
          "Version": 1,
          "CreatedAt": "2021-06-09T11:34:49+00:00"
        }
      ],
      "Product": {
        "TypeCode": "OEF",
        "Code": "GBLMACRLM25_ONLINE"
      },
      "ResourceType": "Forecast",
      "Id": "7ae5918b-f6e2-4d85-b5f8-196cf6de2fff",
      "Name": "Jun21_25yr",
      "Path": "/oxford-economics/releases/GEM/Jun21_25yr",
      "Archiving": null
    },
    {
      "Type": "Forecast",
      "EconomicDomain": "MACRO",
      "ForecastUrl": "/v1/forecasts/=7f087cc0-4bf7-4e18-9c46-940968f3c8b2",
      "Versions": [
        {
          "Name": "Mar21_2_25yr",
          "EconomicDomain": "MACRO",
          "Range": {
            "From": "1980Q1",
            "To": "2050Q4"
          },
          "Id": "1e016eb5-2346-4ef4-91fb-205d1fec2738",
          "Version": 0,
          "CreatedAt": "2021-03-24T10:08:53+00:00"
        }
      ],
      "Product": {
        "TypeCode": "OEF",
        "Code": "GBLMACRLM25_ONLINE"
      },
      "ResourceType": "Forecast",
      "Id": "7f087cc0-4bf7-4e18-9c46-940968f3c8b2",
      "Name": "Mar21_2_25yr",
      "Path": "/oxford-economics/releases/GEM/Mar21_2_25yr",
      "Archiving": null
    },
    {
      "Type": "Forecast",
      "EconomicDomain": "MACRO",
      "ForecastUrl": "/v1/forecasts/=80c9b2f6-6ce6-45ce-9835-6a05c37b0a78",
      "Versions": [
        {
          "Name": "Jun21_10yr",
          "EconomicDomain": "MACRO",
          "Range": {
            "From": "1980Q1",
            "To": "2031Q4"
          },
          "Id": "f08c3028-9a3e-4809-98b0-293fed791bea",
          "Version": 0,
          "CreatedAt": "2021-06-09T11:22:41+00:00"
        }
      ],
      "Product": {
        "TypeCode": "OEF",
        "Code": "GBLMACRLM10_ONLINE"
      },
      "ResourceType": "Forecast",
      "Id": "80c9b2f6-6ce6-45ce-9835-6a05c37b0a78",
      "Name": "Jun21_10yr",
      "Path": "/oxford-economics/releases/GEM/Jun21_10yr",
      "Archiving": null
    }
  
  ],
  "ResourceType": "Directory",
  "Id": "08b42924-e48c-4b19-9b2f-3feb725269f1",
  "Name": "GEM",
  "Path": "/oxford-economics/releases/GEM",
  "Archiving": null
}
```

</details>
<br />

The endpoint itself returns the `Directory` whose `Children` in this example are all `Forecasts`

Taking a closer look at the objects returned

``` json
{
      "Type": "Forecast",
      "EconomicDomain": "MACRO",
      "ForecastUrl": "/v1/forecasts/=29121064-7ef3-41c2-87cc-0eac837b30a9",
      "Versions": [
        {
          "Name": "Jun21_5yr",
          "EconomicDomain": "MACRO",
          "Range": {
            "From": "1980Q1",
            "To": "2026Q4"
          },
          "Id": "f1ad679a-08f2-42b8-af6b-70dafdfe8c9e",
          "Version": 0,
          "CreatedAt": "2021-06-09T11:13:49+00:00"
        }
      ],
      "Product": {
        "TypeCode": "OEF",
        "Code": "GBLMACRLM5_ONLINE"
      },
      "ResourceType": "Forecast",
      "Id": "29121064-7ef3-41c2-87cc-0eac837b30a9",
      "Name": "Jun21_5yr",
      "Path": "/oxford-economics/releases/GEM/Jun21_5yr",
      "Archiving": null
}

```

The field that you would be interested in would be the `Id` field.   
**In order to use it in the rest of the endpoints it needs to be prepended with an `=` sign or `%3D` when used in an URL**

 ## Get all indicators for a forecast

 All indicators for a forecast can be retrieved via the `/v1/forecast-contents/{id}/indicators` endpoint

 ``` curl
curl -X GET "https://model.oxfordeconomics.com/api/v1/forecast-contents/80c9b2f6-6ce6-45ce-9835-6a05c37b0a78/indicators" -H  "accept: application/json" -H  "Authorization: Bearer {JWT / ACESSS_TOKEN}"

 ```

 You will get a list looking like this:

 <details>
 <summary>/v1/forecast-contents/{id}/indicators Response</summary>

``` json

THIS IS A TRUNCATED LIST OF THE INDICATORS AS THE FULL RESPONSE CONTAINS ~ 5710 indicators at the time of creation of this guide
[
  {
    "Code": "GDP",
    "Name": "GDP, real, LCU"
  },
  {
    "Code": "IP",
    "Name": "Industrial production index"
  },
  {
    "Code": "C",
    "Name": "Consumption, private, real, LCU"
  },
  {
    "Code": "IF",
    "Name": "Investment, total fixed investment, real, LCU"
  },
  {
    "Code": "IPNR",
    "Name": "Investment, private sector business, real, LCU"
  },
  {
    "Code": "IPRD",
    "Name": "Investment, private dwellings, real, LCU"
  },
  {
    "Code": "GI",
    "Name": "Investment, government, real, LCU"
  },
  {
    "Code": "GC",
    "Name": "Consumption, government, real, LCU"
  },
  {
    "Code": "ST",
    "Name": "Stocks, total stock levels, real, LCU"
  },
  {
    "Code": "IS",
    "Name": "Stockbuilding, real, LCU"
  },
  {
    "Code": "X",
    "Name": "Exports, goods & services, real, LCU"
  },
  {
    "Code": "XS",
    "Name": "Exports, services, real, LCU"
  },
  {
    "Code": "XGNF",
    "Name": "Exports, non-fuel goods, real, LCU"
  },
  {
    "Code": "XFU",
    "Name": "Exports, fuels, real, LCU"
  },
  {
    "Code": "M",
    "Name": "Imports, goods & services, real, LCU"
  },
  {
    "Code": "MS",
    "Name": "Imports, services, real, LCU"
  },
  {
    "Code": "MGNF",
    "Name": "Imports, non-fuel goods, real, LCU"
  },
  {
    "Code": "MFU",
    "Name": "Imports, fuels, real, LCU"
  },
  {
    "Code": "TFE",
    "Name": "Total final expenditure, real, LCU"
  },
  {
    "Code": "TRX",
    "Name": "Time trend in exports equation"
  },
  {
    "Code": "TRM",
    "Name": "Time trend in imports equation"
  },
  {
    "Code": "WT",
    "Name": "World trade index"
  },
  {
    "Code": "GDP!",
    "Name": "GDP, nominal, LCU"
  },
  {
    "Code": "C!",
    "Name": "Consumption, private, nominal, LCU"
  },
  {
    "Code": "IF!",
    "Name": "Investment, total fixed investment, nominal, LCU"
  },
  {
    "Code": "GC!",
    "Name": "Consumption, government, nominal, LCU"
  },
  {
    "Code": "IS!",
    "Name": "Stockbuilding, nominal, LCU"
  },
  {
    "Code": "X!",
    "Name": "Exports, goods & services, nominal, LCU"
  },
  {
    "Code": "XG!",
    "Name": "Exports, goods, nominal, LCU"
  },
  {
    "Code": "XS!",
    "Name": "Exports, services, nominal, LCU"
  },
  {
    "Code": "M!",
    "Name": "Imports, goods & services, nominal, LCU"
  },
  {
    "Code": "MG!",
    "Name": "Imports, goods, nominal, LCU"
  },
  {
    "Code": "MS!",
    "Name": "Imports, services, nominal, LCU"
  },
  {
    "Code": "BCU",
    "Name": "Current account of balance of payments, LCU"
  },
  {
    "Code": "BVI",
    "Name": "Visible trade balance, LCU"
  },
  {
    "Code": "NIPD!",
    "Name": "Interest, profit and dividends, net, LCU"
  },
  {
    "Code": "NETR",
    "Name": "Transfers, net current account transfers, LCU"
  },
  {
    "Code": "MON",
    "Name": "Money supply, LCU"
  },
  {
    "Code": "RSH",
    "Name": "Interest rate, short-term"
  },
  {
    "Code": "RLG",
    "Name": "Interest rate, long-term government bond yields"
  }
  ...

]
```
 
 </details>  
<br />
  
 ## Choose indicators to retrieve data for
 
 For the sake of this example lets choose some indicators from the list ( we need to use the `Code` field):

  - GDP, real, LCU => `GDP`
  - Consumption, private, real, LCU => `C`
  - Current account of balance of payments, LCU => `BCU`

 ## Get all locations 

All locations or groups as they can be referred to can be retrieved via the `/v1/forecast-contents/{id}/groups` endpoint 

``` curl
curl -X GET "https://model.oxfordeconomics.com/api/v1/forecast-contents/80c9b2f6-6ce6-45ce-9835-6a05c37b0a78/groups" -H  "accept: application/json" -H  "Authorization: Bearer {JWT / ACESSS_TOKEN} "

```

<details>
<summary>GET v1/forecast-contents/{id}/groups response</summary>


``` json
[
  {
    "Type": "Normal",
    "Code": "US",
    "Name": "United States"
  },
  {
    "Type": "Normal",
    "Code": "JAPAN",
    "Name": "Japan"
  },
  {
    "Type": "Normal",
    "Code": "CHINA",
    "Name": "China"
  },
  {
    "Type": "Normal",
    "Code": "EURO_11",
    "Name": "Eurozone"
  },
  {
    "Type": "Normal",
    "Code": "EU",
    "Name": "European Union"
  },
  {
    "Type": "Normal",
    "Code": "GERMANY",
    "Name": "Germany"
  },
  {
    "Type": "Normal",
    "Code": "FRANCE",
    "Name": "France"
  },
  {
    "Type": "Normal",
    "Code": "ITALY",
    "Name": "Italy"
  },
  {
    "Type": "Normal",
    "Code": "UK",
    "Name": "United Kingdom"
  },
  {
    "Type": "Normal",
    "Code": "ALGERIA",
    "Name": "Algeria"
  },
  {
    "Type": "Normal",
    "Code": "ANGOLA",
    "Name": "Angola"
  },
  {
    "Type": "Normal",
    "Code": "ARGENTIN",
    "Name": "Argentina"
  },
  {
    "Type": "Normal",
    "Code": "AUSTRALI",
    "Name": "Australia"
  },
  {
    "Type": "Normal",
    "Code": "AUSTRIA",
    "Name": "Austria"
  },
  {
    "Type": "Normal",
    "Code": "BAHRAIN",
    "Name": "Bahrain"
  },
  {
    "Type": "Normal",
    "Code": "BELGIUM",
    "Name": "Belgium"
  },
  {
    "Type": "Normal",
    "Code": "BOTSWANA",
    "Name": "Botswana"
  },
  {
    "Type": "Normal",
    "Code": "BRAZIL",
    "Name": "Brazil"
  },
  {
    "Type": "Normal",
    "Code": "BULGARIA",
    "Name": "Bulgaria"
  },
  {
    "Type": "Normal",
    "Code": "CANADA",
    "Name": "Canada"
  },
  {
    "Type": "Normal",
    "Code": "CHILE",
    "Name": "Chile"
  },
  {
    "Type": "Normal",
    "Code": "COLOMBIA",
    "Name": "Colombia"
  },
  {
    "Type": "Normal",
    "Code": "CROATIA",
    "Name": "Croatia"
  },
  {
    "Type": "Normal",
    "Code": "CYPRUS",
    "Name": "Cyprus"
  },
  {
    "Type": "Normal",
    "Code": "CZECH",
    "Name": "Czech Republic"
  },
  {
    "Type": "Normal",
    "Code": "DENMARK",
    "Name": "Denmark"
  },
  {
    "Type": "Normal",
    "Code": "ECUADOR",
    "Name": "Ecuador"
  },
  {
    "Type": "Normal",
    "Code": "EGYPTSR",
    "Name": "Egypt"
  },
  {
    "Type": "Normal",
    "Code": "ESTONIA",
    "Name": "Estonia"
  },
  {
    "Type": "Normal",
    "Code": "FINLAND",
    "Name": "Finland"
  },
  {
    "Type": "Normal",
    "Code": "GHANA",
    "Name": "Ghana"
  },
  {
    "Type": "Normal",
    "Code": "GREECE",
    "Name": "Greece"
  },
  {
    "Type": "Normal",
    "Code": "HK",
    "Name": "Hong Kong, China"
  },
  {
    "Type": "Normal",
    "Code": "HUNGARY",
    "Name": "Hungary"
  },
  {
    "Type": "Normal",
    "Code": "INDIA",
    "Name": "India"
  },
  {
    "Type": "Normal",
    "Code": "INDONESI",
    "Name": "Indonesia"
  },
  {
    "Type": "Normal",
    "Code": "IRANSR",
    "Name": "Iran"
  },
  {
    "Type": "Normal",
    "Code": "IRAQ_ANN",
    "Name": "Iraq Annual"
  },
  {
    "Type": "Normal",
    "Code": "IRELAND",
    "Name": "Ireland"
  },
  {
    "Type": "Normal",
    "Code": "ISRAELSR",
    "Name": "Israel"
  },
  {
    "Type": "Normal",
    "Code": "KENYA",
    "Name": "Kenya"
  },
  {
    "Type": "Normal",
    "Code": "KOREA",
    "Name": "Korea, Rep."
  },
  {
    "Type": "Normal",
    "Code": "KUWAIT",
    "Name": "Kuwait"
  },
  {
    "Type": "Normal",
    "Code": "LATVIA",
    "Name": "Latvia"
  },
  {
    "Type": "Normal",
    "Code": "LITH",
    "Name": "Lithuania"
  },
  {
    "Type": "Normal",
    "Code": "LUX",
    "Name": "Luxembourg"
  },
  {
    "Type": "Normal",
    "Code": "MALAYSIA",
    "Name": "Malaysia"
  },
  {
    "Type": "Normal",
    "Code": "MALTA",
    "Name": "Malta"
  },
  {
    "Type": "Normal",
    "Code": "MAURIT",
    "Name": "Mauritius"
  },
  {
    "Type": "Normal",
    "Code": "MEXICO",
    "Name": "Mexico"
  },

  ...
  
  {
    "Type": "Normal",
    "Code": "ADVANECO",
    "Name": "Advanced Economies"
  },
  {
    "Type": "Normal",
    "Code": "EMERGMAR",
    "Name": "Emerging Markets"
  },
  {
    "Type": "Normal",
    "Code": "ASIAPAC",
    "Name": "Asia Pacific"
  },
  {
    "Type": "Normal",
    "Code": "BRIC",
    "Name": "BRICs"
  },
  {
    "Type": "Normal",
    "Code": "GCC",
    "Name": "GCC"
  },
  {
    "Type": "Normal",
    "Code": "WORLD",
    "Name": "World"
  }
]
```
</details>
<br />

 ## Choose location to retrieve data for 

 For the sake of this example lets retrieve data for some of the larger economies.  
 Similarly to the indicators we are going to need the `Code`

  - United States => `US`
  - China => `CHINA`
  - Eurozone => `EURO_11`


 ## Fetch forecast contents

 You get some model variable data from `/v1/forecast-contents/{id}/model-variables`

 First you need to convert your indicator + group code into the following objects

 ``` json
   {
    "GroupCode": "Group code",
    "IndicatorCode": " Indicator code"
  }

 ```

 The body of your request should contain an array of those objects like so:

 ```json
 [
  {
    "GroupCode": "US",
    "IndicatorCode": "GDP"
  },
  {
    "GroupCode": "US",
    "IndicatorCode": "C"
  },
  {
    "GroupCode": "US",
    "IndicatorCode": "BCU"
  },
  {
    "GroupCode": "CHINA",
    "IndicatorCode": "GDP"
  },
  {
    "GroupCode": "CHINA",
    "IndicatorCode": "C"
  },
  {
    "GroupCode": "CHINA",
    "IndicatorCode": "BCU"
  },
  {
    "GroupCode": "EURO_11",
    "IndicatorCode": "GDP"
  },
  {
    "GroupCode": "EURO_11",
    "IndicatorCode": "C"
  },
  {
    "GroupCode": "EURO_11",
    "IndicatorCode": "BCU"
  },
]

 ```

### onlyProps

The `onlyProps` query string can be used to avoid unnecessarily large queries.  
If none are specified the `WHOLE` dataset for a model variable is returned which includes:
- Values
- Metadata
- Fixes
- Residuals
- Equations

For performant queries we recommend specifying only the data you require.

Only `Values` and `Metadata` is used within this example


### Resulting curl request
 ```curl
 curl -X POST "https://model.oxfordeconomics.com/api/v1/forecast-contents/80c9b2f6-6ce6-45ce-9835-6a05c37b0a78/model-variables?onlyProps=Values,Metadata" -H  "accept: application/json" -H  "Authorization: Bearer { ACCESS_TOKEN}" -H  "Content-Type: application/json" -d " [  {    \"GroupCode\": \"US\",    \"IndicatorCode\": \"GDP\"  },  {    \"GroupCode\": \"US\",    \"IndicatorCode\": \"C\"  },  {    \"GroupCode\": \"US\",    \"IndicatorCode\": \"BCU\"  },  {    \"GroupCode\": \"CHINA\",    \"IndicatorCode\": \"GDP\"  },  {    \"GroupCode\": \"CHINA\",    \"IndicatorCode\": \"C\"  },  {    \"GroupCode\": \"CHINA\",    \"IndicatorCode\": \"BCU\"  },  {    \"GroupCode\": \"EURO_11\",    \"IndicatorCode\": \"GDP\"  },  {    \"GroupCode\": \"EURO_11\",    \"IndicatorCode\": \"C\"  },  {    \"GroupCode\": \"EURO_11\",    \"IndicatorCode\": \"BCU\"  },]"

 ```

<details>
<summary>POST /v1/forecast-contents/{id}/model-variables response</summary>

```json

/// RESPONSE HAS BEEN TRUNCATED TO SHOW JUST 1 VARIABLE FOR BREVITY WITHIN THIS EXAMPLE
[
    {
    "Residuals": [],
    "ResidualType": "Additive",
    "Equations": [],
    "Fixes": [],
    "FixHints": {
      "History": [],
      "Forecast": []
    },
    "SecondResidual": null,
    "IndicatorCode": "GDP",
    "GroupCode": "US",
    "SectorCode": "US",
    "Values": [
      {
        "Value": 1709.4,
        "Period": "1980Q1"
      },
      {
        "Value": 1674.2,
        "Period": "1980Q2"
      },
      {
        "Value": 1672.2,
        "Period": "1980Q3"
      },
      {
        "Value": 1703.375,
        "Period": "1980Q4"
      },
      {
        "Value": 1736.75,
        "Period": "1981Q1"
      },
      {
        "Value": 1723.9,
        "Period": "1981Q2"
      },
      {
        "Value": 1744.525,
        "Period": "1981Q3"
      },
      {
        "Value": 1725.525,
        "Period": "1981Q4"
      },
      {
        "Value": 1698.725,
        "Period": "1982Q1"
      },
      {
        "Value": 1706.475,
        "Period": "1982Q2"
      },
      {
        "Value": 1699.95,
        "Period": "1982Q3"
      },
      {
        "Value": 1700.625,
        "Period": "1982Q4"
      },
      {
        "Value": 1723.025,
        "Period": "1983Q1"
      },
      {
        "Value": 1762.25,
        "Period": "1983Q2"
      },
      {
        "Value": 1797.475,
        "Period": "1983Q3"
      },
      {
        "Value": 1834.975,
        "Period": "1983Q4"
      },
      {
        "Value": 1870.85,
        "Period": "1984Q1"
      },
      {
        "Value": 1903.175,
        "Period": "1984Q2"
      },
      {
        "Value": 1921.525,
        "Period": "1984Q3"
      },
      {
        "Value": 1937.3,
        "Period": "1984Q4"
      },
      {
        "Value": 1956.05,
        "Period": "1985Q1"
      },
      {
        "Value": 1973.275,
        "Period": "1985Q2"
      },
      {
        "Value": 2003.425,
        "Period": "1985Q3"
      },
      {
        "Value": 2018.3,
        "Period": "1985Q4"
      },
      {
        "Value": 2037.15,
        "Period": "1986Q1"
      },
      {
        "Value": 2046.325,
        "Period": "1986Q2"
      },
      {
        "Value": 2065.9,
        "Period": "1986Q3"
      },
      {
        "Value": 2077,
        "Period": "1986Q4"
      },
      {
        "Value": 2092.475,
        "Period": "1987Q1"
      },
      {
        "Value": 2115.05,
        "Period": "1987Q2"
      },
      {
        "Value": 2133.4,
        "Period": "1987Q3"
      },
      {
        "Value": 2170.05,
        "Period": "1987Q4"
      },
      {
        "Value": 2181.25,
        "Period": "1988Q1"
      },
      {
        "Value": 2209.9,
        "Period": "1988Q2"
      },
      {
        "Value": 2222.85,
        "Period": "1988Q3"
      },
      {
        "Value": 2252.475,
        "Period": "1988Q4"
      },
      {
        "Value": 2275.375,
        "Period": "1989Q1"
      },
      {
        "Value": 2292.75,
        "Period": "1989Q2"
      },
      {
        "Value": 2309.725,
        "Period": "1989Q3"
      },
      {
        "Value": 2314.275,
        "Period": "1989Q4"
      },
      {
        "Value": 2339.575,
        "Period": "1990Q1"
      },
      {
        "Value": 2348.075,
        "Period": "1990Q2"
      },
      {
        "Value": 2349.625,
        "Period": "1990Q3"
      },
      {
        "Value": 2328.225,
        "Period": "1990Q4"
      },
      {
        "Value": 2317.35,
        "Period": "1991Q1"
      },
      {
        "Value": 2335.4,
        "Period": "1991Q2"
      },
      {
        "Value": 2347.2,
        "Period": "1991Q3"
      },
      {
        "Value": 2355.4,
        "Period": "1991Q4"
      },
      {
        "Value": 2383.575,
        "Period": "1992Q1"
      },
      {
        "Value": 2409.425,
        "Period": "1992Q2"
      },
      {
        "Value": 2433.25,
        "Period": "1992Q3"
      },
      {
        "Value": 2458.625,
        "Period": "1992Q4"
      },
      {
        "Value": 2462.75,
        "Period": "1993Q1"
      },
      {
        "Value": 2477.075,
        "Period": "1993Q2"
      },
      {
        "Value": 2488.9,
        "Period": "1993Q3"
      },
      {
        "Value": 2522.75,
        "Period": "1993Q4"
      },
      {
        "Value": 2547.25,
        "Period": "1994Q1"
      },
      {
        "Value": 2581.75,
        "Period": "1994Q2"
      },
      {
        "Value": 2596.85,
        "Period": "1994Q3"
      },
      {
        "Value": 2626.6,
        "Period": "1994Q4"
      },
      {
        "Value": 2635.9,
        "Period": "1995Q1"
      },
      {
        "Value": 2643.775,
        "Period": "1995Q2"
      },
      {
        "Value": 2666.275,
        "Period": "1995Q3"
      },
      {
        "Value": 2684.375,
        "Period": "1995Q4"
      },
      {
        "Value": 2704.475,
        "Period": "1996Q1"
      },
      {
        "Value": 2749.575,
        "Period": "1996Q2"
      },
      {
        "Value": 2774.25,
        "Period": "1996Q3"
      },
      {
        "Value": 2803.05,
        "Period": "1996Q4"
      },
      {
        "Value": 2821.15,
        "Period": "1997Q1"
      },
      {
        "Value": 2868.025,
        "Period": "1997Q2"
      },
      {
        "Value": 2903.9,
        "Period": "1997Q3"
      },
      {
        "Value": 2928.85,
        "Period": "1997Q4"
      },
      {
        "Value": 2958.125,
        "Period": "1998Q1"
      },
      {
        "Value": 2985.5,
        "Period": "1998Q2"
      },
      {
        "Value": 3022.9,
        "Period": "1998Q3"
      },
      {
        "Value": 3071.75,
        "Period": "1998Q4"
      },
      {
        "Value": 3100.825,
        "Period": "1999Q1"
      },
      {
        "Value": 3124.675,
        "Period": "1999Q2"
      },
      {
        "Value": 3165.6,
        "Period": "1999Q3"
      },
      {
        "Value": 3219.4,
        "Period": "1999Q4"
      },
      {
        "Value": 3231.05,
        "Period": "2000Q1"
      },
      {
        "Value": 3290.2,
        "Period": "2000Q2"
      },
      {
        "Value": 3294.6,
        "Period": "2000Q3"
      },
      {
        "Value": 3315.125,
        "Period": "2000Q4"
      },
      {
        "Value": 3305.675,
        "Period": "2001Q1"
      },
      {
        "Value": 3325,
        "Period": "2001Q2"
      },
      {
        "Value": 3311.2,
        "Period": "2001Q3"
      },
      {
        "Value": 3320.225,
        "Period": "2001Q4"
      },
      {
        "Value": 3349.25,
        "Period": "2002Q1"
      },
      {
        "Value": 3369.55,
        "Period": "2002Q2"
      },
      {
        "Value": 3384.525,
        "Period": "2002Q3"
      },
      {
        "Value": 3389.75,
        "Period": "2002Q4"
      },
      {
        "Value": 3408.575,
        "Period": "2003Q1"
      },
      {
        "Value": 3437.875,
        "Period": "2003Q2"
      },
      {
        "Value": 3496.275,
        "Period": "2003Q3"
      },
      {
        "Value": 3536.4,
        "Period": "2003Q4"
      },
      {
        "Value": 3555.275,
        "Period": "2004Q1"
      },
      {
        "Value": 3582.375,
        "Period": "2004Q2"
      },
      {
        "Value": 3616.25,
        "Period": "2004Q3"
      },
      {
        "Value": 3652.475,
        "Period": "2004Q4"
      },
      {
        "Value": 3692.9,
        "Period": "2005Q1"
      },
      {
        "Value": 3709.95,
        "Period": "2005Q2"
      },
      {
        "Value": 3743.025,
        "Period": "2005Q3"
      },
      {
        "Value": 3766.65,
        "Period": "2005Q4"
      },
      {
        "Value": 3816.75,
        "Period": "2006Q1"
      },
      {
        "Value": 3825.675,
        "Period": "2006Q2"
      },
      {
        "Value": 3831.6,
        "Period": "2006Q3"
      },
      {
        "Value": 3864.225,
        "Period": "2006Q4"
      },
      {
        "Value": 3873.325,
        "Period": "2007Q1"
      },
      {
        "Value": 3895.525,
        "Period": "2007Q2"
      },
      {
        "Value": 3916.675,
        "Period": "2007Q3"
      },
      {
        "Value": 3940.5,
        "Period": "2007Q4"
      },
      {
        "Value": 3917.85,
        "Period": "2008Q1"
      },
      {
        "Value": 3938.075,
        "Period": "2008Q2"
      },
      {
        "Value": 3916.75,
        "Period": "2008Q3"
      },
      {
        "Value": 3832,
        "Period": "2008Q4"
      },
      {
        "Value": 3788.975,
        "Period": "2009Q1"
      },
      {
        "Value": 3783.525,
        "Period": "2009Q2"
      },
      {
        "Value": 3797.3,
        "Period": "2009Q3"
      },
      {
        "Value": 3839.025,
        "Period": "2009Q4"
      },
      {
        "Value": 3853.775,
        "Period": "2010Q1"
      },
      {
        "Value": 3889.325,
        "Period": "2010Q2"
      },
      {
        "Value": 3918,
        "Period": "2010Q3"
      },
      {
        "Value": 3937.65,
        "Period": "2010Q4"
      },
      {
        "Value": 3928.2,
        "Period": "2011Q1"
      },
      {
        "Value": 3956.275,
        "Period": "2011Q2"
      },
      {
        "Value": 3955.175,
        "Period": "2011Q3"
      },
      {
        "Value": 4001.025,
        "Period": "2011Q4"
      },
      {
        "Value": 4032.35,
        "Period": "2012Q1"
      },
      {
        "Value": 4049.7,
        "Period": "2012Q2"
      },
      {
        "Value": 4055.175,
        "Period": "2012Q3"
      },
      {
        "Value": 4059.775,
        "Period": "2012Q4"
      },
      {
        "Value": 4095.75,
        "Period": "2013Q1"
      },
      {
        "Value": 4100.8,
        "Period": "2013Q2"
      },
      {
        "Value": 4132.925,
        "Period": "2013Q3"
      },
      {
        "Value": 4165.9,
        "Period": "2013Q4"
      },
      {
        "Value": 4154.125,
        "Period": "2014Q1"
      },
      {
        "Value": 4210.375,
        "Period": "2014Q2"
      },
      {
        "Value": 4261.775,
        "Period": "2014Q3"
      },
      {
        "Value": 4285.75,
        "Period": "2014Q4"
      },
      {
        "Value": 4326.45,
        "Period": "2015Q1"
      },
      {
        "Value": 4355.7,
        "Period": "2015Q2"
      },
      {
        "Value": 4371.5,
        "Period": "2015Q3"
      },
      {
        "Value": 4378.525,
        "Period": "2015Q4"
      },
      {
        "Value": 4403.325,
        "Period": "2016Q1"
      },
      {
        "Value": 4417.05,
        "Period": "2016Q2"
      },
      {
        "Value": 4441.1,
        "Period": "2016Q3"
      },
      {
        "Value": 4469.05,
        "Period": "2016Q4"
      },
      {
        "Value": 4494.325,
        "Period": "2017Q1"
      },
      {
        "Value": 4513.525,
        "Period": "2017Q2"
      },
      {
        "Value": 4546.4,
        "Period": "2017Q3"
      },
      {
        "Value": 4589.85,
        "Period": "2017Q4"
      },
      {
        "Value": 4632.625,
        "Period": "2018Q1"
      },
      {
        "Value": 4663.6,
        "Period": "2018Q2"
      },
      {
        "Value": 4688.1,
        "Period": "2018Q3"
      },
      {
        "Value": 4703.475,
        "Period": "2018Q4"
      },
      {
        "Value": 4737.575,
        "Period": "2019Q1"
      },
      {
        "Value": 4755.15,
        "Period": "2019Q2"
      },
      {
        "Value": 4785.425,
        "Period": "2019Q3"
      },
      {
        "Value": 4813.5,
        "Period": "2019Q4"
      },
      {
        "Value": 4752.7,
        "Period": "2020Q1"
      },
      {
        "Value": 4325.625,
        "Period": "2020Q2"
      },
      {
        "Value": 4649.125,
        "Period": "2020Q3"
      },
      {
        "Value": 4698.6,
        "Period": "2020Q4"
      },
      {
        "Value": 4772.025,
        "Period": "2021Q1"
      },
      {
        "Value": 4922.81641,
        "Period": "2021Q2"
      },
      {
        "Value": 5054.84863,
        "Period": "2021Q3"
      },
      {
        "Value": 5098.545,
        "Period": "2021Q4"
      },
      {
        "Value": 5120.592,
        "Period": "2022Q1"
      },
      {
        "Value": 5177.617,
        "Period": "2022Q2"
      },
      {
        "Value": 5212.94336,
        "Period": "2022Q3"
      },
      {
        "Value": 5228.182,
        "Period": "2022Q4"
      },
      {
        "Value": 5253.042,
        "Period": "2023Q1"
      },
      {
        "Value": 5275.831,
        "Period": "2023Q2"
      },
      {
        "Value": 5290.98633,
        "Period": "2023Q3"
      },
      {
        "Value": 5310.013,
        "Period": "2023Q4"
      },
      {
        "Value": 5330.529,
        "Period": "2024Q1"
      },
      {
        "Value": 5351.255,
        "Period": "2024Q2"
      },
      {
        "Value": 5371.05957,
        "Period": "2024Q3"
      },
      {
        "Value": 5390.317,
        "Period": "2024Q4"
      },
      {
        "Value": 5412.40039,
        "Period": "2025Q1"
      },
      {
        "Value": 5434.91,
        "Period": "2025Q2"
      },
      {
        "Value": 5458.27441,
        "Period": "2025Q3"
      },
      {
        "Value": 5482.147,
        "Period": "2025Q4"
      },
      {
        "Value": 5505.10059,
        "Period": "2026Q1"
      },
      {
        "Value": 5525.68,
        "Period": "2026Q2"
      },
      {
        "Value": 5545.505,
        "Period": "2026Q3"
      },
      {
        "Value": 5564.6543,
        "Period": "2026Q4"
      },
      {
        "Value": 5586.08057,
        "Period": "2027Q1"
      },
      {
        "Value": 5607.13428,
        "Period": "2027Q2"
      },
      {
        "Value": 5627.862,
        "Period": "2027Q3"
      },
      {
        "Value": 5648.48633,
        "Period": "2027Q4"
      },
      {
        "Value": 5669.368,
        "Period": "2028Q1"
      },
      {
        "Value": 5691.93457,
        "Period": "2028Q2"
      },
      {
        "Value": 5714.24072,
        "Period": "2028Q3"
      },
      {
        "Value": 5737.30127,
        "Period": "2028Q4"
      },
      {
        "Value": 5760.40332,
        "Period": "2029Q1"
      },
      {
        "Value": 5785.17041,
        "Period": "2029Q2"
      },
      {
        "Value": 5809.32031,
        "Period": "2029Q3"
      },
      {
        "Value": 5833.733,
        "Period": "2029Q4"
      },
      {
        "Value": 5858.35,
        "Period": "2030Q1"
      },
      {
        "Value": 5884.80762,
        "Period": "2030Q2"
      },
      {
        "Value": 5910.903,
        "Period": "2030Q3"
      },
      {
        "Value": 5937.088,
        "Period": "2030Q4"
      },
      {
        "Value": 5965.09326,
        "Period": "2031Q1"
      },
      {
        "Value": 5993.30469,
        "Period": "2031Q2"
      },
      {
        "Value": 6021.77734,
        "Period": "2031Q3"
      },
      {
        "Value": 6050.23828,
        "Period": "2031Q4"
      }
    ],
    "Frequency": "Quarterly",
    "Metadata": {
      "Description": "GDP, real, LCU",
      "AnnualizationType": "Sum",
      "Units": "US$",
      "ScaleFactor": "Billions",
      "Source": "GDPH@USNA / 4",
      "Unit": "US$",
      "Scaling": "Billions: chained 2012 prices",
      "OriginalSourceProvider": "Bureau of Economic Analysis\\Haver Analytics",
      "OriginalSourceCode": "Real Gross Domestic Product (SAAR, Bil.Chn.2012$) / 4",
      "IsSeasonallyAdjusted": true,
      "ContactName": "Oxford Economics",
      "ContactEmail": "admin@oxfordeconomics.com",
      "BaseYearIndex": "",
      "BaseYearPrice": "chained 2012",
      "DerivedHistoryEnd": "2021Q1",
      "GroupName": "United States",
      "IndicatorProperties": {
        "SectorCoverage": "Whole Economy"
      },
      "InternalId": "1001"
    }
  }
]
```
 </details>
<br/>
