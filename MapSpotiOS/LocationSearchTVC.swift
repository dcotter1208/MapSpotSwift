//
//  LocationSearchTVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/3/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import MapKit

class LocationSearchTVC: UITableViewController, UISearchResultsUpdating {
    weak var handleMapSearchDelegate: HandleMapSearch?
    var searchResults = [MKMapItem]()
    var mapView:MKMapView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func parseAddress(mapItem: MKPlacemark) -> String {

        var fullAddress = String()
        let addressDict = mapItem.addressDictionary
        
        if let address = addressDict {
            if let street = address["Street"], city = address["City"], state = address["State"], countryCode = address["CountryCode"] {
                fullAddress = "\(street), \(city), \(state), \(countryCode)"
            }
        }
        return fullAddress
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        if let map = mapView {
            let searchBarText = searchController.searchBar.text
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = searchBarText
            request.region = map.region
            let search = MKLocalSearch(request: request)
            search.startWithCompletionHandler{
                (response, error) in
                
                if let response = response {
                    self.searchResults = response.mapItems
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let mapItem = searchResults[indexPath.item]
        
        print(mapItem)
        
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = parseAddress(mapItem.placemark)
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let searchedLocation = searchResults[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinAtSearchedLocation(searchedLocation)
        dismissViewControllerAnimated(true, completion: nil)
    }


}


