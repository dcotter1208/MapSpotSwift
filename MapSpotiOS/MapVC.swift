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
        setupMapView()
        getUserLocation()
        setUpSearchControllerWithSearchTable()
        setUpSearchBar()
        getCurrentUserProfileWithRealm()
//        queryCurrentUserFromFirebase()
        
        
        
        let dbManager = RLMDBManager()
        print(dbManager.realm?.configuration.fileURL)
        
        
        if let userID = FIRAuth.auth()?.currentUser?.uid {
            dbManager.getCurrentUserFromRealm(userID)
        }
        
//        
//        let dbManager = RLMDBManager()
//        let user = RLMUser()
//        user.createUser("Donovan", email: "cotter@yahoo.com", userID: "34234225235", snapshotKey: "jasfja888jsj", location: "", photoURL: nil, profileImage: nil)
//        dbManager.writeObject(user)
        
        
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
    
    /*
     Presents options for login(logs user in), signup(presenets SignUpTVC)
     or continuing to use the app as an Anonymous user.
 */
    func presentLoginSignUpOption(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler { (emailTF) in
            emailTF.placeholder = "email"
        }
        alertController.addTextFieldWithConfigurationHandler { (passwordTF) in
            passwordTF.placeholder = "password"
        }
        let login = UIAlertAction(title: "Login", style: .Default) {
            (action) in
            FIRAuth.auth()?.signInWithEmail(alertController.textFields![0].text!, password: alertController.textFields![1].text!, completion: { (user, error) in
                guard error == nil else {
                    self.presentLoginSignUpOption("Login Failed", message: "Please check your email & password and try again.")
                    print(error?.description)
                    return
                }
                //Check for the current user profile in realm. if it isn't in realm the query from Firebase and write to realm. This solves the edge case for if someone logs into the account and did not register for the account on the phone their signing in on.
//                self.queryCurrentUserFromFirebase()
                //Set Current User Singleton Here
            })
        }
        let signup = UIAlertAction(title: "Sign Up", style: .Default) {
            (action) in
            self.istantiateSignUpOrUserProfileVC("SignUpNavController")
        }
        let continueAsAnonymous = UIAlertAction(title: "Continue Anonymously", style: .Default, handler: nil)
        alertController.addAction(login)
        alertController.addAction(signup)
        alertController.addAction(continueAsAnonymous)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    /*
     Used to istantiate the SignUPTVC or the
     UserProfileTVC (if the user is already logged in).
 */
    func istantiateSignUpOrUserProfileVC(viewControllerToIstantiate: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let istantiatedVC = storyboard.instantiateViewControllerWithIdentifier(viewControllerToIstantiate)
        
        guard viewControllerToIstantiate != "EditProfileTVC" else {
            return
        }
        self.presentViewController(istantiatedVC, animated: true, completion: nil)
    }
    
    /*
     Checks if a user is logged in or not. Called when the profile icons is selected.
     If the user is logged in as Anonymous the presentLoginSignUpOption func is called
     and an alert with options is presented.
 */
    func checkForCurrentlyLoggedInUser() {
        guard FIRAuth.auth()?.currentUser?.anonymous == false else {
            presentLoginSignUpOption("Login", message: "Don't have an account? Sign Up")
            return
        }
        guard FIRAuth.auth()?.currentUser == nil else {
            performSegueWithIdentifier("showUserProfileSegue", sender: self)
            return
        }
        presentLoginSignUpOption("Login", message: "Don't have an account? Sign Up")
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
    func getCurrentUserProfileWithRealm() {
        guard FIRAuth.auth()?.currentUser != nil else {
            loginWithAnonymousUser()
        return
        }
        
        let realmManager = RLMDBManager()
        guard let userID = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        let results = realmManager.getCurrentUserFromRealm(userID)
        setCurrentUserProfileWithRealmResults(results)
    }
    
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
 */
    func setCurrentUserProfileWithFirebaseSnapshot(snapshot: FIRDataSnapshot) {
        
        for child in snapshot.children {
            guard let
                name = child.value["name"],
                email = child.value["email"],
                photoURL = child.value["profilePhotoURL"],
                userID = child.value["userID"],
                location = child.value["location"] else {
            return
            }
            
            guard photoURL != nil else {
            CurrentUser.sharedInstance.setCurrentUserProperties(name as! String, email: email as! String, photoURL: "", userID: userID as! String, snapshotKey: child.key as String)
                return
            }
            CurrentUser.sharedInstance.setCurrentUserProperties(name as! String, email: email as! String, photoURL: photoURL as! String, userID: userID as! String, snapshotKey: child.key as String)
            downloadProfileImageWithAlamoFire(photoURL as! String, completion: { (image) in
                CurrentUser.sharedInstance.profileImage = image
            })
            
            guard location != nil else {
                return
            }
            CurrentUser.sharedInstance.location = location as! String
        }
    }
    
    func setCurrentUserProfileWithRealmResults(realmResults:Results<RLMUser>) {
        CurrentUser.sharedInstance.setCurrentUserProperties(realmResults[0].name, email: realmResults[0].email, photoURL: realmResults[0].photoURL, userID: realmResults[0].userID, snapshotKey: realmResults[0].snapshotKey)
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

