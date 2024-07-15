/*
'Parsed Google Civic API' Copyright 2017 Sam Suri, all rights reserved. Only use with permission.

Program calls Google Civic's 'Get Representative by Address' API and converts it into a usable dictionary, where each
official is assigned a tier. The available tiers are: Federal, Congressional, State, and County. This program fetches
live data but does not update or post any data. Program uses Alamofire and SwiftyJSON.
*/

import UIKit
import Alamofire
import PlaygroundSupport
import Foundation
import SwiftyJSON

// Allow playgournd file to run
PlaygroundPage.current.needsIndefiniteExecution = true
URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)

// getting input from user, requesting their full address, these can be connected to Outlets in XCODE
let address = "2317 Speedway"  // this can include spaces, apt/unit numbers are ignored
let city = "Austin"  // can contain spaces
let county = "Travis".lowercased()  // has to be lowercase
let state = "Tx".lowercased()  // has to be lowercase
let zip = "78712"

let google_rep_secret = ""  // google Civic secret, ID is not needed
let google_civic_url:String = "https://www.googleapis.com/civicinfo/v2/representatives/?key="+google_rep_secret+"&includeOffices=True&address="+address+", "+city+", "+state+", "+zip
// Adds %20 in URL where spaces are present
let encoded_url = google_civic_url.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
var offices = [String:[[String:Any]]]()  // declaring Dictionary that stores part of returnes JSON where key = "offices"
var officials = [String:[[String:Any]]]()  // declaring Dictionary that stores part of returnes JSON where key = "officials"

let federal_list = [0, 1]  // list of indexes that always correspond to federal officials
let congressional_list = [2,3,4]  // list of indexes that always correspond to congressional officials
var state_list = [Int]()   // indexes for state officials change, has to be formulated
var county_list = [Int]()  // indexes for county officials change, has to be formulated
var temp_ste_list:[Int] = []
var temp_cty_list:[Int] = []

var complete_list = [Any]()  // final list that stores All public officials

var index_list = [Int]()
var catagory_index_list = [Int]()

var count:Int = 0  // starts count at 0, used to match officials' contact info with title info
var print_bool:Bool = false
var temp_dict = [String: Any]()
var compliled:String = ""
var tag:String = ""

let info_list = ["name", "address", "party", "phones"]  // represents key values that we want to include for each official
// list of strings that will be searched for
let category_patterns:[String:String] = [("ocd-division/country:us/state:"+state+"/county:"+county): "cty",
                                         ("ocd-division/country:us/state:"+state+"/sldu:"): "ste",
                                         ("ocd-division/country:us/state:"+state+"/sldl:"): "ste",
                                         ("ocd-division/country:us/state:"+state): "ste"]

// function iterates over appropriate list to find match, if match is found, returns string
func which_indeces(index_number:Int, state_list:[Int], county_list:[Int]) -> String {
    for i in federal_list {
        if index_number == i {  // checks to see if index number in complete_list matches a number in one of the 4 lists
            return "federal"  // matches represent the tier that officials belong to
        }
    }
    for i in congressional_list {
        if index_number == i {
            return "congress"
        }
    }
    for i in state_list {
        if index_number == i {
            return "state"
        }
    }
    for i in county_list {
        if index_number == i {
            return "county"
        }
    }
    return ""  // if official is a city of local official, they will be marked with ""
}

// function populates state_list by finding indexes corresponding to predetermined categories
func state_indexes_to_column(dict_iteration: [String:Any]) -> [Int]{
    for (k, v) in dict_iteration {
        if k == "divisionId"{
            let google_catagory_identifer = v as! String  // identifier is a certain string that belongs to each office
            for (name, cat) in category_patterns {  // iterates over catagory_patterns, defined above
                // checks to see if name is one of two strings, which have alternate endings
                if ((google_catagory_identifer).range(of:"ocd-division/country:us/state:tx/sldu:") != nil) ||
                    ((google_catagory_identifer).range(of:"ocd-division/country:us/state:tx/sldl:") != nil) {
                    for (k2, v2) in dict_iteration {
                        if k2 == "officialIndices"{
                            if cat == "ste"{  // double checks that match is only for 'state' identifiers
                                for i in v2 as! [Int]{
                                    let tempInt = i
                                    temp_ste_list.append(tempInt)
                                }
                            }
                        }
                    }
                }
                // else if name does not match strings with alternate endings, looks for direct match
                else if name == google_catagory_identifer{
                    for (k2, v2) in dict_iteration {
                        if k2 == "officialIndices"{
                            if cat == "ste"{  // double checks that match is only for 'state' identifiers
                                for i in v2 as! [Int]{
                                    let tempInt = i
                                    temp_ste_list.append(tempInt)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return Array(Set<Int>(temp_ste_list))  // list is converted to set as some values are duplicates, converted back to list
}

// function populates county_list by finding indexes corresponding to predetermined categories
func county_indexes_to_column(dict_iteration:[String:Any]) -> [Int] {
    for (k, v) in dict_iteration {
        if k == "divisionId" {
            let google_catagory_identifer = v as! String   // identifier is a certain string that belongs to each office
            for (name, cat) in category_patterns {  // iterates over catagory_patterns, defined above
                if name == google_catagory_identifer {  // looks for direct match
                    for (k2, v2) in dict_iteration {
                        if k2 == "officialIndices" {
                            if cat == "cty" {  // double checks that match is only for 'county' identifiers
                                for i in v2 as! [Int]{
                                    let tempInt = i
                                    temp_cty_list.append(tempInt)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return Array(Set<Int>(temp_cty_list))  // list is converted to set as some values are duplicates, converted back to list
}

// Alamofire is used to make a get request and returns JSON data as a String
Alamofire.request(encoded_url).responseString { response in
    let json = (response.result.value!)
    if let json_to_data = json.data(using: String.Encoding.utf8, allowLossyConversion: false) { //converts to data and encodes it
        let decoded_json = try? JSON(data: json_to_data) // converts to SwiftyJSON JSON type
        let jdson_dict = decoded_json!.dictionaryObject!  // converts to dictionary object of type [String:Any]
        // jdson_dict has to be converted to type [String: Array<Dictionary<String:Any>>], and this has to be done manually by copying values to new dictionary
        var temp_array_1 = [[String:Any]]()
        for (k,v) in jdson_dict {
            if k == "offices"{
                for i in v as! Array<Any>{  // creates array
                    var temp_dict_append_1 = [String:Any]()
                    for (key,value) in i as! [String:Any]{
                        temp_dict_append_1[key] = value // populates dictionary
                    }
                    temp_array_1.append(temp_dict_append_1) // appends dictionary at each index position
                }
            }
        }
        offices["offices"] = temp_array_1  // final array is made to be value in dictionary for 'offices' part of JSON data
        // this has to be repeated for 'officials' part of JSON data
        var temp_array_2 = [[String:Any]]()
        for (k,v) in jdson_dict {
            if k == "officials"{
                for i in v as! Array<Any>{ // creates array
                    var temp_dict_append_2 = [String:Any]()
                    for (key,value) in i as! [String:Any]{
                        temp_dict_append_2[key] = value // populates dictionary
                    }
                    temp_array_2.append(temp_dict_append_2) // appends dictionary at each index position
                }
            }
        }
        officials["officials"] = temp_array_2 // final array is made to be value in dictionary
    }
    
    // returned JSON from API call is broken into two different keys: offices, and officials
    // Each part contains information on each official and has to be matched, but some offices have multiple officials
    for (k,v) in offices {  // calls dictionary that contains part of returned JSON
        if k == "offices"{
            for dict_iteration in v {
                state_list = state_indexes_to_column(dict_iteration: dict_iteration) // function populates state_list
                county_list = county_indexes_to_column(dict_iteration: dict_iteration) // function populates county_list
            }
            state_list.sort() // state_list and county_list are sorted
            county_list.sort()
            for (i, titles) in v.enumerated() {  // enumerates values in dictionary to get count
                if i == count {  // ensures that iteration of each office stops at count, which is eventually incremented
                    for (k2, v2) in titles {
                        if k2 == "officialIndices" {
                            var tempv2 = v2 as! [Int]
                            index_list += tempv2  // each office contains a list of indices that represent officials
                            catagory_index_list += tempv2
                        }
                        if k2 == "name" {  // title of each official is appended to temp_dict
                            temp_dict["title"] = v2 as? String
                        }
                    }
                    for (k,v) in officials {  // calls dictionary that contains part of returned JSON
                        if k == "officials" {
                            for (i2, person_info) in v.enumerated() {   // enumerates values in dictionary to get count
                                for value in index_list {  // references index_list, which was previously populated
                                    if i2 == value {   // checks to see if enumerated count matches index number
                                        print_bool = true  // sets boolean value to one, so that official can be copied to complete_list
                                        index_list = index_list.filter{$0 != value}  // removes index number from index_list, some offices have many officials
                                        for (k3, v3) in person_info {
                                            for info in info_list {
                                                if k3 == info {
                                                    temp_dict[k3] = v3  // info of each official is added to temp_dict
                                                }
                                            }
                                        }
                                    }
                                }
                                if print_bool == true {
                                    let tag = which_indeces(index_number: complete_list.count, state_list: state_list, county_list: county_list)  // which_index is called, finds tier of each official
                                    temp_dict["tier"] = tag  // tier is added to dictionary of each official
                                    complete_list.append(temp_dict)
                                    print_bool = false   // print_bool is reset for next official
                                }
                            }
                        }
                    }
                    if index_list.count == 0 {  // if index_list is empty, count is modified to move onto next office
                        count += 1
                    }
                }
            }
        }
    }
    
    // prints final list
    for i in complete_list{
        for (k,v) in i as! [String:Any] {
            if (k == "tier"){
                print(i)
            }
        }
    }
}
