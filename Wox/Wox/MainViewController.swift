//
//  ViewController.swift
//  Wox
//
//  Created by Matthew Bordas on 11/23/15.
//  Copyright © 2015 Undecided. All rights reserved.
//

import UIKit
import MapKit

class MainViewController: UIViewController , UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properites
    
    @IBOutlet weak var mapView: MKMapView!
    
    var currentLocation = CLLocation(latitude: 37.8023, longitude: -122.4494)
    let regionRadius: CLLocationDistance = 1000
    var locationManager = CLLocationManager()
    var testRoutes1 = [Route]()
    var testRoutes2 = [Route]()
    
    // Searching
    var locations = ["Chinatown","Pier 39", "Golden Gate Bridge", "Golden Gate Park", "Lombard Street", "Alcatraz Island", "California Academy of Sciences", "The Presidio", "AT&T Park", "Angel Island", "Marina", "Tenderloin"]
    var endLocationsToXY = ["Marina": CLLocation(latitude: 37.80684, longitude: -122.4312), "Tenderloin":CLLocation(latitude: 37.785, longitude: -122.4212)]
    var filteredLocations = [String]()
    var searchResultsController: UISearchController!
    var searchBarTextField: UITextField!
    
    var test1 = true
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "SideMenu"), landscapeImagePhone: nil, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        initializeMapView()
        initializeLocations()
        initializeSearchController()
        centerMapOnLocation(currentLocation)
        setUpRoutes()
        let pin = Pin(title: "Current Location", locationName: "", coordinate: CLLocationCoordinate2D(latitude: testRoutes1[0].steps[0].latitude, longitude: testRoutes1[0].steps[0].longitude))
        mapView.addAnnotation(pin)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }

    
    // MARK: - Init
    
    func initializeSearchController() {
        let searchResultsTableViewController = UITableViewController()
        searchResultsTableViewController.tableView.tableFooterView = UIView()
        searchResultsTableViewController.tableView.dataSource = self
        searchResultsTableViewController.tableView.delegate = self
        searchResultsTableViewController.tableView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        searchResultsController = UISearchController(searchResultsController: searchResultsTableViewController)
        searchResultsController.searchBar.delegate = self
        searchResultsController.searchBar.searchBarStyle = UISearchBarStyle.Default
        let currentScreen = UIScreen.mainScreen()
        searchResultsController.searchBar.frame = CGRectMake(0, 0, currentScreen.bounds.width+5, 44)
        searchResultsController.searchBar.translucent = true
        // Get handle to the UITextField embedded inside the UISearchBar
        for subView: UIView in searchResultsController.searchBar.subviews
        {
            for field: AnyObject in subView.subviews
            {
                if field is UITextField
                {
                    searchBarTextField = field as! UITextField
                    // Change the search text to gray
                    searchBarTextField.textColor = UIColor.grayColor()
                    searchBarTextField.leftViewMode = UITextFieldViewMode.Never
                }
            }
        }
        // Add it under the nav bar
        self.mapView.addSubview(searchResultsController.searchBar)
        self.mapView.bringSubviewToFront(searchResultsController.searchBar)
        
        searchResultsController.searchBar.placeholder = "Search for a walk"
        
        searchResultsController.searchBar.delegate = self
        
        // Allow this view controller to be convered by the results table view ?
        self.definesPresentationContext = true
        
        // This ViewController will be responsible for implementing UISearchResultsDialog protocol method(s) - so handling what happens when user types into the search bar
        searchResultsController.searchResultsUpdater = self
        
        // This view controller conforms to the delegate protocol for the UISearchController
        searchResultsController.delegate = self
        
        searchResultsController.dimsBackgroundDuringPresentation = true
    }
    
    func initializeMapView() {
        mapView.mapType = .Standard
        mapView.showsUserLocation = true
        mapView.delegate = self
    }
    
    func initializeLocations() {
        
    }
    
    // MARK: - TableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellReuseId = "cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellReuseId)
        if cell == nil
        {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellReuseId)
            // Style cell here
            cell!.textLabel!.textColor = UIColor.whiteColor()
            cell!.backgroundColor = UIColor.clearColor()
            cell!.backgroundView = UIView()
            cell!.selectedBackgroundView = UIView()
        }
        
        // Get cell info from filtered results
        let currentSearch = filteredLocations[indexPath.row]
        cell!.textLabel!.text = currentSearch
        
        return cell!
    }
    
    // MARK: - TableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedLocation = filteredLocations[indexPath.row]
        
        if selectedLocation != "Marina" {
            test1 = false
            // Clear overlays and annotations
            mapView.removeAnnotations(mapView.annotations)
            mapView.removeOverlays(mapView.overlays)
            // Add start annotation
            let startPin = Pin(title: "Current Location", locationName: "", coordinate: CLLocationCoordinate2DMake(CLLocationDegrees(37.78247), CLLocationDegrees(-122.41)))
            mapView.addAnnotation(startPin)
        }
        
        // Drop ending pin
        let cllocation = endLocationsToXY[selectedLocation]!
        centerMapOnLocation(cllocation)
        let location2d = CLLocationCoordinate2DMake(CLLocationDegrees(cllocation.coordinate.latitude), CLLocationDegrees(cllocation.coordinate.longitude))
        
        let pin = Pin(title: selectedLocation, locationName: "", coordinate:location2d)
        mapView.addAnnotation(pin)
        
        drawRoute()
        searchResultsController.active = false
    }
    
    // MARK: - Map
    
    func centerMapOnLocation(location: CLLocation) {
        // Location is new center point
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func setUpRoutes() {
        // First route has 3
        testRoutes1.append(Route(filename: "PalaceA.csv"))
        testRoutes1.append(Route(filename: "PalaceB.csv"))
        testRoutes1.append(Route(filename: "PalaceC.csv"))
        
        // Second route has 3
        testRoutes2.append(Route(filename: "MissionA.csv"))
        testRoutes2.append(Route(filename: "MissionB.csv"))
        testRoutes2.append(Route(filename: "MissionC.csv"))
        
    }
    
    func drawRoute() {
        // Test 1
        if test1 {
            let myPolyline = MKPolyline(coordinates: &testRoutes1[0].steps, count: testRoutes1[0].steps.count)
            myPolyline.title = "route1A"
            mapView.addOverlay(myPolyline)
            
            
            let myPolyline2 = MKPolyline(coordinates: &testRoutes1[1].steps, count: testRoutes1[1].steps.count)
            myPolyline2.title = "route2A"
            mapView.addOverlay(myPolyline2)
            
            let myPolyline3 = MKPolyline(coordinates: &testRoutes1[2].steps, count: testRoutes1[2].steps.count)
            myPolyline3.title = "route3A"
            mapView.addOverlay(myPolyline3)
        }
        else {
            let myPolyline = MKPolyline(coordinates: &testRoutes2[0].steps, count: testRoutes2[0].steps.count)
            myPolyline.title = "route1B"
            mapView.addOverlay(myPolyline)
            
            let myPolyline2 = MKPolyline(coordinates: &testRoutes2[1].steps, count: testRoutes2[1].steps.count)
            myPolyline2.title = "route2B"
            mapView.addOverlay(myPolyline2)
            
            let myPolyline3 = MKPolyline(coordinates: &testRoutes2[2].steps, count: testRoutes2[2].steps.count)
            myPolyline3.title = "route3B"
            mapView.addOverlay(myPolyline3)
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        if searchController.searchBar.text?.characters.count > 0
        {
            searchController.searchBar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
            
                filteredLocations = locations.filter
                {
                    (location: String) -> Bool in
                    var searchText = searchController.searchBar.text!
                    searchText.replaceRange(searchText.startIndex...searchText.startIndex, with: String(searchText[searchText.startIndex]).capitalizedString)
                    let searchResultAsRange = location.rangeOfString(searchText)
                    return searchResultAsRange != nil
            }
            let resultsTableViewController = searchController.searchResultsController as! UITableViewController
            resultsTableViewController.tableView.reloadData()
        }
        else
        {
            searchController.searchBar.backgroundColor = UIColor.clearColor()
        }
    }
    
}

extension MainViewController: MKMapViewDelegate {
    // called for every annotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Pin {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            }
            else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                //view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            }
            if (view.annotation?.title)! == "Current Location" {
                view.pinTintColor = MKPinAnnotationView.greenPinColor()
            }
            else if (view.annotation?.title)! == "Score" {
                view.pinTintColor = MKPinAnnotationView.purplePinColor()
            }
            else {
                view.pinTintColor = MKPinAnnotationView.redPinColor()
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let lineView = MKPolylineRenderer(overlay: overlay)
        if test1 {
            lineView.strokeColor = UIColor.greenColor()
            if overlay.title! == "route1A"{
                let overlayPin = Pin(title: "Score", locationName: "0.002224299", coordinate: CLLocationCoordinate2DMake(37.80651,-122.4376))
                mapView.addAnnotation(overlayPin)
            }
            else if overlay.title! == "route2A" {
                let overlayPin = Pin(title: "Score", locationName: "0.001933514", coordinate: CLLocationCoordinate2DMake(37.80396,-122.4402))
                mapView.addAnnotation(overlayPin)
            }
            else {
                let overlayPin = Pin(title: "Score", locationName: "0.002061181", coordinate: CLLocationCoordinate2DMake(37.803,-122.437))
                mapView.addAnnotation(overlayPin)
            }
        }
        else {
            lineView.strokeColor = UIColor.redColor()
            if overlay.title! == "route1B"{
                let overlayPin = Pin(title: "Score", locationName: "0.01376404", coordinate: CLLocationCoordinate2DMake(37.78135,-122.4182))
                mapView.addAnnotation(overlayPin)
            }
            else if overlay.title! == "route2B" {
                let overlayPin = Pin(title: "Score", locationName: "0.01397126", coordinate: CLLocationCoordinate2DMake(37.78547,-122.4157))
                mapView.addAnnotation(overlayPin)
            }
            else {
                let overlayPin = Pin(title: "Score", locationName: "0.01384273", coordinate: CLLocationCoordinate2DMake(37.78255,-122.4161))
                mapView.addAnnotation(overlayPin)
            }
        }
        
        lineView.lineWidth = 5.0
        return lineView
    }
}

