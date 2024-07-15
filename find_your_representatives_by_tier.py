"""
'Parsed Google Civic API' Program v1.0, Copyright 2017 Sam Suri, all rights reserved. Only use with permission. 

Program calls Google Civic's 'Get Representative by Address' API and converts it into a usable dictionary, where each
official is assigned a tier. The available tiers are: Federal, Congressional, State, and County. This program fetches
live data but does not update or post any data. 
"""
from copy import deepcopy
from json import loads
import requests
import re

# getting input from user, requesting their full address
address = input('Please enter your street address: ')  # this can include spaces, apt/unit numbers are ignored
city = input('Please enter the city you live in: ')  # can contain spaces
county = input('Please enter the county you reside in: ').lower()  # has to be lowercase
state = input('Please enter your state abbreviation: ').lower()  # has to be lowercase
zip = input('Please enter your 5 digit zip code: ')

google_rep_secret = ''  # google Civic secret, ID is not needed
# uses get request to return json
google_civic_results = requests.get(str('https://www.googleapis.com/civicinfo/v2/representatives/?key='
                       +google_rep_secret+'&includeOffices=True&address='+address+', '+city+', '+state+', '+zip)).text
loaded_google = loads(google_civic_results)  # deserializes JSON

info_list = ['name', 'address', 'party', 'phones']  # represents key values that we want to include for each official
# list of strings that will be compiled using re, so that they can be searched for
category_patterns = [(str('ocd-division/country:us/state:'+state+'/county:'+county), 'cty'),
                     (str('ocd-division/country:us/state:'+state+'/sldu:\d\d'), 'ste'),
                     (str('ocd-division/country:us/state:'+state+'/sldl:\d\d'), 'ste'),
                     (str('ocd-division/country:us/state:'+state), 'ste')
                     ]

federal_list = [0, 1]  # list of indexes that always correspond to federal officials
congressional_list = [2, 3, 4]  # list of indexes that always correspond to congressional officials
state_list = []  # indexes for state officials change, has to be formulated
county_list = []  # indexes for county officials change, has to be formulated

complete_list = []  # final list that stores All public officials
index_list = []

count = 0  # starts count at 0, used to match officials' contact info with title info
print_bool = 0
temp_dict = {}
compliled = ''
tag = ''

# function iterates over appropriate list to find match, if match is found, returns string
def which_indeces(index_number, state_list, county_list):
    for i in federal_list:
        if index_number == i:  # checks to see if index number in complete_list matches a number in one of the 4 lists
            return 'federal'  # matches represent the tier that officials belong to
    for i in congressional_list:
        if index_number == i:
            return 'congress'
    for i in state_list:
        if index_number == i:
            return 'state'
    for i in county_list:
        if index_number == i:
            return 'county'

# function populates state_list by finding indexes corresponding to predetermined categories
def state_indexes_to_column(dict_iteration):
    temp_ste_list = []
    for k, v in dict_iteration.items():
        if k == 'divisionId':
            google_catagory_identifer = v  # identifier is a certain string that belongs to each office
            for name, cat in category_patterns:  # iterates over catagory_patterns, defined above
                # checks to see if name is one of two strings, which have alternate endings
                if (name == str('ocd-division/country:us/state:' + state + '/sldu:\d\d')) | (
                    name == str('ocd-division/country:us/state:' + state + '/sldl:\d\d')):
                    compiled = re.compile(name)  # if so, names are compiled using re so that they can be searched for
                    if bool(re.search(compiled, google_catagory_identifer)) == True:  # searches for name in google_catagory_identifier
                        for k2, v2 in dict_iteration.items():
                            if k2 == 'officialIndices':
                                if cat == 'ste':  # double checks that match is only for 'state' identifiers
                                    temp_ste_list += v2
                # if name does not match strings with alternate endings, looks for direct match, re is not needed
                elif name == google_catagory_identifer:
                    for k2, v2 in dict_iteration.items():
                        if k2 == 'officialIndices':
                            if cat == 'ste':  # double checks that match is only for 'state' identifiers
                                temp_ste_list += v2
    return list(set(temp_ste_list))  # list is converted to set as some values are duplicates, converted back to list

# function populates county_list by finding indexes corresponding to predetermined categories
def county_indexes_to_column(dict_iteration):
    temp_cty_list = []
    for k, v in dict_iteration.items():
        if k == 'divisionId':
            google_catagory_identifer = v  # identifier is a certain string that belongs to each office
            for name, cat in category_patterns:  # iterates over catagory_patterns, defined above
                if name == google_catagory_identifer:  # looks for direct match, re library is not needed
                    for k2, v2 in dict_iteration.items():
                        if k2 == 'officialIndices':
                            if cat == 'cty':  # double checks that match is only for 'county' identifiers
                                temp_cty_list += v2
    return list(set(temp_cty_list))  # list is converted to set as some values are duplicates, converted back to list

# JSON object is broken into three initial keys: divisions, offices, and officials
# Each part contains information on each official and has to be matched, but some offices have multiple officials
for k, v in loaded_google.items():  # iterates over items in deserialized JSON object
    if k == 'offices':
        for dict_iteration in loaded_google[k]:
            state_list += state_indexes_to_column(dict_iteration)  # function populates state_list
            county_list += county_indexes_to_column(dict_iteration)  # function populates county_list
        state_list.sort()  # state_list and county_list are sorted
        county_list.sort()
        for i, titles in enumerate(loaded_google[k]):  # enumerates values returned by index: loaded_google['offices']
            if i == count:  # ensures that iteration of each office stops at count, which is eventually incremented
                for k2, v2 in titles.items():
                    if k2 == 'officialIndices':
                        index_list += v2  # each office contains a list of indices that represent officials
                    if k2 == 'name':  # title of each official is appended to temp_dict
                        temp_dict['title'] = v2
                for k, v in loaded_google.items():
                    if k == 'officials':
                        for i2, person_info in enumerate(loaded_google[k]):  # enumerates values returned by loaded_google['officials']
                            for value in index_list:  # references index_list, which was previously populated
                                if i2 == value:  # checks to see if enumerated count matches index number
                                    print_bool = 1  # sets boolean value to one, so that official can be copied to complete_list
                                    index_list.remove(value)  # removes index number from index_list, some offices have many officials
                                    for k3, v3 in person_info.items():
                                        for info in info_list:
                                            if k3 == info:
                                                temp_dict[k3] = v3  # info of each official is added to temp_dict
                            if print_bool == 1:
                                complete_list.append(deepcopy(temp_dict))  # temp_dict is deep copied into complete_list
                                print_bool = 0  # print_bool is reset for next official
                if len(index_list) == 0:  # if index_list is empty, count is modified to move onto next office
                    count += 1

# when complete_list is fully populated, each index position is used to find tier that corresponds to each official
for count, representative in enumerate(complete_list):  # complete_list is enumerated
    tag = which_indeces(count, state_list, county_list)  # which_index is called, finds tier of each official
    representative['tier'] = tag  # tier is added to dictionary of each official

# prints final list and excludes officials that could not be matched, such as local and city officials
for i in complete_list:
    for k, v in i.items():
        if (k == 'tier') & (v != None):
            print(i)
