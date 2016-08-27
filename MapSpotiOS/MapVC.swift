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
import RealmSwift

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

        print(RLMDBManager().realm?.configuration.fileURL)

        setupMapView()
        getUserLocation()
        setUpSearchControllerWithSearchTable()
        setUpSearchBar()
        //if the user profile doesn't exist in Realm then we query Firebase for the data.
        getCurrentUserProfileWithRealm {
            (results) in
            guard results.isEmpty == false else {
                self.queryCurrentUserProfileFromFirebase()
                return
            }
            self.setCurrentUserProfileWithRealmResults(results)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Map Methods

    func setupMapView() {
        guard let mapView = mapView else {return}
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
    
    //MARK: Realm Methods
    func writeUserToRealm(user: Object) {
        let realmDBManager = RLMDBManager()
        realmDBManager.realm?.beginWrite()
        realmDBManager.realm?.add(user)
        
        do {
            try realmDBManager.realm?.commitWrite()
        } catch let error as NSError {
            print(error)
        }
    }
    
    func createRLMUser(name: String, email: String, userID: String, snapshotKey: String, location: String) -> RLMUser {
        let rlmUser = RLMUser()
        rlmUser.createUser(name, email: email, userID: userID, snapshotKey: snapshotKey, location: location)
        return rlmUser
    }
    
    //MARK: Helper Methods

    /*
     Used to istantiate the SignUPTVC or the
     UserProfileTVC (if the user is already logged in).
 */
    func istantiateSignUpOrUserProfileVC(viewControllerToIstantiate: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let istantiatedVC = storyboard.instantiateViewControllerWithIdentifier(viewControllerToIstantiate)
        self.presentViewController(istantiatedVC, animated: true, completion: nil)
    }
    
    /*
     Checks if a user is logged in or not. Called when the profile icons is selected.
     If the user is logged in as Anonymous the presentLoginSignUpOption func is called
     and an alert with options is presented.
 */
    func checkForCurrentlyLoggedInUser() {
        guard FIRAuth.auth()?.currentUser?.anonymous == false else {
            istantiateSignUpOrUserProfileVC("LogInNavController")
            return
        }
        guard FIRAuth.auth()?.currentUser == nil else {
            performSegueWithIdentifier("showUserProfileSegue", sender: self)
            return
        }
        istantiateSignUpOrUserProfileVC("LogInNavController")
    }
    
    /*
     Logs a user in anonymously. Called in queryCurrentUserFromFirebase func
     if a user isn't already logged into their own account.
 */
    func loginWithAnonymousUser() {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
            if error != nil {
                print(error)
            }
        })
    }
    
    /*
     Checks if a user is already logged in. If they aren't then it logs
     them in anonymously. If they are then it makes a query to Realm for
     the Current User's UserProfile and sets the CurrentUser Singleton.
 */
    func getCurrentUserProfileWithRealm(completion:(results: Results<RLMUser>) -> Void) {
        guard FIRAuth.auth()?.currentUser != nil else {
            loginWithAnonymousUser()
        return
        }
        let realmManager = RLMDBManager()
        guard let userID = FIRAuth.auth()?.currentUser?.uid else {return}
        completion(results: realmManager.getCurrentUserFromRealm(userID))
    }
    
    //Queries Firebase for the current user's profile.
    func queryCurrentUserProfileFromFirebase() {
        let firebaseOp = FirebaseOperation()
        let query = firebaseOp.firebaseDatabaseRef.ref.child("users").queryOrderedByChild("userID").queryEqualToValue(FIRAuth.auth()?.currentUser?.uid)
        firebaseOp.queryFirebaseForChildWithConstrtaints(query, firebaseDataEventType: .Value, observeSingleEventType: true) {
            (result) in
            self.setCurrentUserProfileWithFirebaseSnapshot(result)
        }
    }
    
    /*
     Sets the CurrentUser Singleton from a FIRDataSnapshot.
     It also uses that FIRDataSnapShot to write the userprofile to Realm.
 */
    func setCurrentUserProfileWithFirebaseSnapshot(snapshot: FIRDataSnapshot) {
        for child in snapshot.children {
            guard let
                name = child.value["name"] as? String,
                email = child.value["email"] as? String,
                photoURL = child.value["profilePhotoURL"] as? String,
                userID = child.value["userID"] as? String,
                location = child.value["location"] as? String else {
            return
            }
            
            guard photoURL != "" else {
            CurrentUser.sharedInstance.setCurrentUserProperties(name,
                                                                location: location,
                                                                email: email,
                                                                photoURL: "",
                                                                userID: userID,
                                                                snapshotKey: child.key as String)
            let user = createRLMUser(name,
                                     email: email,
                                     userID: userID,
                                     snapshotKey: child.key as String,
                                     location: location)
            writeUserToRealm(user)
                return
            }
            CurrentUser.sharedInstance.setCurrentUserProperties(name,
                                                                location: location,
                                                                email: email,
                                                                photoURL: photoURL,
                                                                userID: userID,
                                                                snapshotKey: child.key)
            CurrentUser.sharedInstance.location = location
            
            downloadProfileImageWithAlamoFire(photoURL, completion: { (image) in
                CurrentUser.sharedInstance.profileImage = image
                let user = self.createRLMUser(name,
                    email: email,
                    userID: userID,
                    snapshotKey: child.key as String,
                    location: location)
                user.photoURL = photoURL
                user.profileImage = UIImageJPEGRepresentation(image, 1.0)
                self.writeUserToRealm(user)
            })
        }
    }
    
    //Takes results from Realm and sets the CurrentUser Singleton.
    func setCurrentUserProfileWithRealmResults(realmResults:Results<RLMUser>) {
        CurrentUser.sharedInstance.setCurrentUserProperties(realmResults[0].name,
                                                            location: realmResults[0].location,
                                                            email: realmResults[0].email,
                                                            photoURL: realmResults[0].photoURL,
                                                            userID: realmResults[0].userID,
                                                            snapshotKey: realmResults[0].snapshotKey)
        
        guard let profileImageData = realmResults[0].profileImage else {return}
        CurrentUser.sharedInstance.profileImage = UIImage(data: profileImageData)
    }
    
    /*
     Downloads the profile image from Cloudinary with AlamoFire.
 */
    func downloadProfileImageWithAlamoFire(photoURL: String, completion:(image:UIImage) -> Void) {
        Alamofire.request(.GET, photoURL)
            .responseImage { response in
                if let image = response.result.value {
                    completion(image: image)
                }
            }
    }
    
    //MARK: SearchController Methods
    
    //Creates SearchController
    func setUpSearchControllerWithSearchTable()  {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let locationSearchTable = storyboard.instantiateViewControllerWithIdentifier("LocationSearchTVC") as! LocationSearchTVC
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
    }
    
    //Configures the Search Bar
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

    @IBAction func unwindToMap(segue: UIStoryboardSegue) {
        
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
        checkForCurrentlyLoggedInUser()
    }
    
    

}

