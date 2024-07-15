# Find_Your_Representatives_by_Tier
The program parses the Google Civic Information 'representativeInfoByAddress' API and returns an array of dictionaries, that each contain the title, name, and personal information of every representative for a particular address, that the user inputs. Additionally, the program dynamically sorts each government official into 4 tiers: Federal, Congressional, State, and County, so that each official is classified correctly, regardless if different regions have different positions or different amount of representatives. This program was developed for Battleground Texas, a non-profit in Austin, Texas. This repository contains two different versions of the program, one written in Python, and one written in Swift. This allows the program to have a greater impact on society. 

## Technical Overview
The JSON, when first called from Google, is in a scattered format. For example, looking at just one official: <br />
Located near the top of the returned JSON: <br />
```
{
   "name": "United States House of Representatives TX-35",
   "divisionId": "ocd-division/country:us/state:tx/cd:35",
   "levels": [
    "country"
   ],
   "roles": [
    "legislatorLowerBody"
   ],
   "officialIndices": [
    4
   ]
}
```
Located near the middle of the returned JSON: <br />
```
{
  "name": "Lloyd Doggett",
  "address": [
    {
     "line1": "2307 Rayburn House Office Building",
     "city": "Washington",
     "state": "DC",
     "zip": "20515"
    }]
}
```
Some government positions, such as Commissioners, have multiple representatives. This made matching an official's title, name, and information particularly difficult. Also, different states and cities have different representatives and different positions require different amounts of people to fill them. While federal officials (the President and the Vice-President) and Congressional officials constantly occupy the same positions in the JSON, state and city officials move. The program dynamically searches for state and county officials using the 'divisionID' key to solve this. The result, for this particular official, after running this program is:
```
{'party': 'Democratic', 'address': [{'state': 'DC', 'city': 'Washington', 'zip': '20515', 'line1': '2307 Rayburn House Office Building'}], 'phones': ['(202) 225-4865'], 'tier': 'congress', 'name': 'Lloyd Doggett', 'title': 'United States House of Representatives TX-35'}
 ```
## Python and Swift
The python version of the program uses requests and re, to make the API Get request and to compile and search for certain strings, respectively. The swift version of the program has two different files, one that works in a 'Playground' and one that works within a 'viewDidLoad' function. This is so that future users do not have to convert the program to the environment that they are using in XCode. The file that was made to work within the 'viewDidLoad' function can easily be changed to be in a 'viewDidAppear' or a 'viewWillAppear' function, so that it can work with the unique design of any app. The program uses both SwiftyJSON and Alamofire, to convert the JSON to a dictionary and to make the API Get request, respectively. 

## Making Changes
At the request of Battleground Texas, city officials were not assigned high importance in the program. This can easily be changed, however, by adding a default return value of 'city' in the which_index function. The names of the 'tiers' can also be changed by modifying the strings that are returned in the which_index function. 

## Notes
If someone inputs an incorrect address, the final list, complete_list, will be empty. You can test for this and display a response to the user if this is occurs. Complete_list will be in the data format [[String:Any]] or Array<Dictionary<String, Any>>. 
