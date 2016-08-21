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
import Alamofire
import AlamofireImage

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
        queryCurrentUserFromFirebase()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Map Methods
    
    func setupMapView() {
        
        guard let mapView = mapView else {
            return
        }

        mapView.delegate = self
        mapView.showsPointsOfInterest = false
        mapView.showsUserLocation = true
    }
    
    func adjustMapViewCamera() {
        let newCamera = mapView.camera
        
        guard mapView.camera.pitch < 30.0 else {
            newCamera.pitch = mapView.camera.pitch
            return
        }
        newCamera.pitch = 30
        self.mapView.camera = newCamera
    }
    
    //MARK: Helper Methods
    
    func queryCurrentUserFromFirebase() {
        guard FIRAuth.auth()?.currentUser != nil else {
        return
        }
        let firebaseOp = FirebaseOperation()
        let query = firebaseOp.firebaseDatabaseRef.ref.child("users").queryOrderedByChild("userID").queryEqualToValue(FIRAuth.auth()?.currentUser?.uid)
        firebaseOp.queryFirebaseForChildWithConstrtaints(query, firebaseDataEventType: .Value, observeSingleEventType: true) {
            (result) in
            self.setCurrentUserProfile(result)
        }
    }
    
    func setCurrentUserProfile(snapshot: FIRDataSnapshot) {
        
        for child in snapshot.children {
            guard let
                name = child.value["name"],
                email = child.value["email"],
                photoURL = child.value["profilePhotoURL"],
                userID = child.value["userID"] else {
            return
            }
            guard photoURL != nil else {
            CurrentUser.sharedInstance.setCurrentUserProperties(name as! String, email: email as! String, photoURL: "", userID: userID as! String, snapshotKey: child.key as String)
                return
            }
            CurrentUser.sharedInstance.setCurrentUserProperties(name as! String, email: email as! String, photoURL: photoURL as! String, userID: userID as! String, snapshotKey: child.key as String)
            downloadProgileImageWithAlamoFire(photoURL as! String, completion: { (image) in
                CurrentUser.sharedInstance.profileImage = image
            })
        }
    }
    
    func downloadProgileImageWithAlamoFire(photoURL: String, completion:(image:UIImage) -> Void) {
        Alamofire.request(.GET, photoURL)
            .responseImage { response in
                if let image = response.result.value {
                    completion(image: image)
                }
        }
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
        
        guard let manager = locationManager else {
            return
        }

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.requestWhenInUseAuthorization()
        manager.distanceFilter = 100
        manager.startUpdatingLocation()
        
        guard let managerLocation = manager.location else {
            return
        }
        newestLocation = managerLocation
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let lastLocation = locations.last else {
            return
        }
        newestLocation = lastLocation
        userLocation = MKCoordinateRegionMakeWithDistance(newestLocation.coordinate, 800, 800)
        mapView.setRegion(userLocation, animated: true)
    }


   //MARK: IBActions
    @IBAction func TEMPSIGNOUT(sender: AnyObject) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print(error)
        }
    }

    @IBAction func showUserLocation(sender: AnyObject) {
        mapView.setRegion(userLocation, animated: true)
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
        
    }

    //**END**
}

