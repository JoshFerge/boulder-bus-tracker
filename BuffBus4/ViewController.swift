//
//  ViewController.swift
//  BuffBus4
//
//  Created by Joshua Ferge on 7/11/15.
//  Copyright (c) 2015 Joshua Ferge. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Foundation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    
    var locationManager: CLLocationManager!
    
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var UIPicker: UIPickerView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeLabel2: UILabel!
    @IBOutlet weak var next: UILabel!
    
    var stopDict = [String: Stop]()
    var stops = [String]()
    var stopinfo = APIManager.sharedInstance.getStops()
    var closestStop: ( Name:String, Distance: Float)?
    var pickerStartingLocation : Int!
    
    var TitleToIndex = [String: Int]()
    
    var closestStopTitle : String?
    
    var center = true
    
    var currentPickerLocation : Int?
    var getInfoTimer : NSTimer!
    var getLocationTimer : NSTimer!
    var routes = APIManager.sharedInstance.getRoutes()
    var testRoute : Route!
    var routeNumber = 0
    
    var buses = APIManager.sharedInstance.getBuses()
    
    var initialLocation : CLLocation!
    var first = 0
    
    
    
    override func viewDidLoad() {
        
        UIPicker.transform = CGAffineTransformMakeScale(0.8, 0.8);
        mapView.delegate = self
        mapView.showsPointsOfInterest = false
        
        super.viewDidLoad()
        
        
        
        
        for route in routes {
            if route.id == routeNumber {
                testRoute = route
            }
        }
        var i = 0
        for stop in stopinfo!  {
            if testRoute.stops.contains(stop.id) {
                stopDict[stop.title!] = stop
                stops.append(stop.title!)
                TitleToIndex[stop.title!] = i
                i+=1
            }
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        mapView.showsUserLocation = true
        
        getLocationTimer = NSTimer.scheduledTimerWithTimeInterval(65.0, target: self, selector: Selector("updateGPS"), userInfo: nil, repeats: true)
        
        
        
        plotNewBuses()
        plotStops()
        
        
        getInfoTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("plotNewBuses"), userInfo: nil, repeats: true)
        
        switch routeNumber {
        case 1:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.001894, longitude: -105.260184))
            }
            routeLabel.text = "Buff Bus"
            addRoute(BuffBus)
        case 6:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.013267, longitude: -105.271943))
            }
            routeLabel.text = "HOP Clockwise"
            addRoute(hopClockwise)
        case 7:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.013267, longitude: -105.271943))
            }
            routeLabel.text = "HOP Counterclockwise"
            addRoute(hopCounterClockwise)
        case 3:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.01152, longitude: -105.277179))
            }
            
            routeLabel.text = "Late Night Gold"
            addRoute(latenightGold)
        case 4:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.00337, longitude: -105.275977))
            }
            routeLabel.text = "Late Night Black"
            addRoute(lateNightBlack)
        case 5:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.00337, longitude: -105.275977))
            }
            routeLabel.text = "Late Night Silver"
            addRoute(latenightSilver)
        case 9:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                updateTimes(0)
                centerMapOnLocation(CLLocation(latitude: 40.010079, longitude: -105.270484))
            }
            routeLabel.text = "Athens Route"
            addRoute(athensRoute)
        case 8:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                centerMapOnLocation(CLLocation(latitude: 40.001894, longitude: -105.260184))
            }
            routeLabel.text = "Buff Bus Basketball"
            addRoute(basketballRoute)
        case 2:
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
                centerMapOnLocation(CLLocation(latitude: 40.001894, longitude: -105.260184))
            }
            routeLabel.text = "Buff Bus Football"
            addRoute(footballRoute)
        default:
            print("error")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
    }
    
    func updateStops() {
        
        var stopinfo = APIManager.sharedInstance.getStops()
        for stop in stopinfo!  {
            if testRoute.stops.contains(stop.id) {
                stopDict[stop.title!] = stop
            }
            if let closestStopTitle = closestStopTitle as String! {
                if stop.title == closestStopTitle {
                    stop.setNewSubtitle("Nearest Stop")
                }
            }
        }
        if currentPickerLocation != nil  {
            updateTimes(currentPickerLocation!)
            
        }
        
    }
    
    
    func plotNewBuses() {
        getStops(self,callback: updateStops)
        
        getBuses()
        
        let annotationsToRemove = mapView.annotations.filter { $0 !== self.mapView.userLocation && !self.stops.contains($0.title!!) }
        mapView.removeAnnotations(annotationsToRemove)
        var buses = APIManager.sharedInstance.getBuses()
        for bus in buses {
            if bus.routeID == testRoute.id {
                mapView.addAnnotation(bus)
            }
            
        }
    }
    
    func plotStops() {
        
        for stop in APIManager.sharedInstance.getStops()! {
            if testRoute.stops.contains(stop.id) {
                mapView.addAnnotation(stop)
            }
        }
    }
    
    func addRoute(ptrToArray: [[Float]]) {
        let pointsCount = ptrToArray.count
        var pointsToUse: [CLLocationCoordinate2D] = []
        
        for i in 0...pointsCount-1 {
            pointsToUse += [CLLocationCoordinate2DMake(CLLocationDegrees(ptrToArray[i][1]), CLLocationDegrees(ptrToArray[i][0]))]
        }
        
        let myPolyline = MKPolyline(coordinates: &pointsToUse, count: pointsCount)
        
        mapView.addOverlay(myPolyline)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        closestStopTitle = nil
        getLocationTimer.invalidate()
        getInfoTimer.invalidate()
        mapView.removeFromSuperview()
        self.dismissViewControllerAnimated(true, completion: {});
        
    }
    override func viewDidDisappear(animated: Bool) {
        
        
        
        
    }
    func updateGPS() {
//        self.center = false
        first = 0
        updateStops()
        
        
    }
    

    func updateTimes(row: Int) {
        currentPickerLocation = row
        if let times = stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)] {
            
            
            if stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![0] < 0 {
                timeLabel.text = "No Buses Running"
                next.hidden = false
            }
            else if  stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![0] == 1 {
                timeLabel.text = "1 Minute"
                next.hidden = false
            }
                
            else if  stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![0] == 0 {
                timeLabel.text = "Less than a minute"
                next.hidden = false
            }
                
            else {
                next.hidden = false
                var test = stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![0]
                timeLabel.text = String(test) + " Minutes"
            }
            // If only one bus is running/ there is only one next time in the array
            // It will break from the index being out of range
            if stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]!.count > 1 {
                if stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![1] == 0 {
                    timeLabel2.text = "Less than a minute"
                    
                }
                if  stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![1] == 1 {
                    timeLabel.text = "1 Minute"
                    next.hidden = false
                }
                if stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![1] < 0 {
                    timeLabel2.text = ""
                }
                
                else {
                    var test = stopDict[stops[row]]!.nextBusTimes[String(testRoute.id)]![1]
                    
                    timeLabel2.text = String(test) + " Minutes"
                    
                }
            } else {
                timeLabel2.text = ""
            }
        }
        else {
            timeLabel.text = "No Buses Running"
            timeLabel2.text = ""
            next.hidden = false
        }
        
    }
}

