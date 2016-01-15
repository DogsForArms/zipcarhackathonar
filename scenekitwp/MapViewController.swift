//
//  MapViewController.swift
//  scenekitwp
//
//  Created by Ethan Sherr on 1/14/16.
//  Copyright © 2016 Ethan Sherr. All rights reserved.
//

import UIKit
import MapKit

class MyAnnotation: NSObject, MKAnnotation
{
    var title:String?
    
    var coordinate:CLLocationCoordinate2D
    
    init(title t:String, coordinate c: CLLocationCoordinate2D)
    {
        title = t
        coordinate = c
    }
}

class MapViewController: UIViewController, MKMapViewDelegate
{

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        let longPress = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        mapView.addGestureRecognizer(longPress)
        mapView.delegate = self
        
    }
    
    
    @IBAction func showMe(sender: AnyObject) {
        performSegueWithIdentifier("toCamera", sender: self)
    }
    
    
    
    let bballCourt = CLLocationCoordinate2D(latitude: 42.350883, longitude:  -71.046777)
    let cornerOfPark = CLLocationCoordinate2D(latitude: 42.3509577, longitude: -71.0463357)
    let pointInTheNorth = CLLocationCoordinate2D(latitude: 79.738839, longitude: -71.566170)
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "toCamera"
        {
            if let arvc = segue.destinationViewController as? ARViewController
            {
                arvc.poiOpt = theAnnotation?.coordinate
            }
        }
    }
    
    var theAnnotation: MyAnnotation?
    // # handle long press
    func handleLongPress(gestureRecognizer: UIGestureRecognizer)
    {
        if gestureRecognizer.state != .Began
        {
            return
        }
        
        if let curAnnotation = theAnnotation
        {
            mapView.removeAnnotation(curAnnotation)
            theAnnotation = nil
        }
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MyAnnotation(title: "Zipcar Reservation", coordinate: touchMapCoordinate)
        theAnnotation = annotation
        mapView.addAnnotation(annotation)
    }
    
    let reuseId = "pin"
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let _ = annotation as? MKUserLocation
        {
            return nil
        }
        
        var pin: MKPinAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if (pin == nil)
        {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        
        pin.animatesDrop = true
        
        return pin
    }
    
    var hasSetRegion = false
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
       
        if !hasSetRegion
        {
            let delta = 0.005;
            let region = MKCoordinateRegionMake(mapView.userLocation.coordinate, MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta));
            mapView.setRegion(region, animated: true)
            hasSetRegion = true
        }
    }
    
}
