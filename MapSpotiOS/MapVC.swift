//
//  MapVC.swift
//  MapSpotiOS
//
//  Created by Cotter on 8/1/16.
//  Copyright © 2016 Cotter. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

protocol HandleMapSearch: class {
    func dropPinAtSearchedLocation(placemark:MKPlacemark)
}

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, HandleMapSearch {
    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapStyleNavBarButton: UIBarButtonItem!
    
    private var locationManager: CLLocationManager?
    private var newestLocation = CLLocation()
    private var userLocation = MKCoordinateRegion()
    private var resultSearchController:UISearchController? = nil
    private var searchedLocation:MKPlacemark? = nil
    private var key = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        getUserLocation()
        setUpSearchControllerWithSearchTable()
        setUpSearchBar()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Map Methods
    
    func setupMapView() {
        if let mapView = mapView {
            mapView.delegate = self
            mapView.showsPointsOfInterest = false
            mapView.showsUserLocation = true
        }
    }
    
    func adjustMapViewCamera() {
        
        let newCamera = mapView.camera
        if mapView.camera.pitch < 30.0 {
            newCamera.pitch = 30.0
        } else {
            newCamera.pitch = mapView.camera.pitch
        }
            self.mapView.camera = newCamera
    }
    
    //MARK: SearchController Methods
    func setUpSearchControllerWithSearchTable()  {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let locationSearchTable = storyboard.instantiateViewControllerWithIdentifier("LocationSearchTVC") as! LocationSearchTVC
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
    }
    
    func setUpSearchBar() {
        let searchBar = resultSearchController?.searchBar
        searchBar?.sizeToFit()
        searchBar?.placeholder = "Search For Places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
    }
    
    //This drops the pin at the searched location when using the search bar.
    func dropPinAtSearchedLocation(placemark:MKPlacemark) {
        searchedLocation = placemark
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: Location Methods
    func getUserLocation() {
        locationManager = CLLocationManager()
        if let manager = locationManager {
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.requestWhenInUseAuthorization()
            manager.distanceFilter = 100
            manager.startUpdatingLocation()
            
            if let managerLocation = manager.location {
                newestLocation = managerLocation
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            newestLocation = lastLocation
            userLocation = MKCoordinateRegionMakeWithDistance(newestLocation.coordinate, 800, 800)
            mapView.setRegion(userLocation, animated: true)
        }
    }
    
    func presentLoginSignUpOption() {
        
        let alertController = UIAlertController(title: "Login or Sign Up", message: nil, preferredStyle: .Alert)
        
        let login = UIAlertAction(title: "Login", style: .Default) {
            (action) in
            
            //Login user with Firebase
            
        }
        
        let signup = UIAlertAction(title: "Sign Up", style: .Default) {
            (action) in
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let SignUpVC = storyboard.instantiateViewControllerWithIdentifier("SignUpVC")
            self.presentViewController(SignUpVC, animated: true, completion: nil)
            
        }
        
        alertController.addAction(login)
        alertController.addAction(signup)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }

   //MARK: IBActions

    @IBAction func showUserLocation(sender: AnyObject) {
        mapView.setRegion(userLocation, animated: true);
        
    }
    
    @IBAction func changeMapStyle(sender: AnyObject) {
        if mapView.mapType == .Standard {
            mapView.mapType = .HybridFlyover
            mapView.showsCompass = true
            mapStyleNavBarButton.image = UIImage(named: "map")
            adjustMapViewCamera()            
        } else {
            mapView.mapType = .Standard
            mapStyleNavBarButton.image = UIImage(named: "3DCube")
            mapView.showsBuildings = true            
        }
        
    }
    
    @IBAction func profileButtonPressed(sender: AnyObject) {
        
        if FIRAuth.auth()?.currentUser?.uid == nil {
            presentLoginSignUpOption()
        }
        
    }

    
    
    //**END**
}

