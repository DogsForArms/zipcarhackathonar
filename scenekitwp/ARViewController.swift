//
//  ViewController.swift
//  scenekitwp
//
//  Created by Ethan Sherr on 1/13/16.
//  Copyright © 2016 Ethan Sherr. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation
import CoreMotion
import CoreLocation

class ARViewController: UIViewController, CLLocationManagerDelegate
{
//
    @IBOutlet weak var dist: UILabel!
    @IBOutlet weak var dx: UILabel!
    @IBOutlet weak var dy: UILabel!
    @IBOutlet weak var dz: UILabel!
    
    
    var poiOpt: CLLocationCoordinate2D?
    
    var captureDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var captureView: UIView!
    func setupVideoCapture()
    {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh// AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        print(devices)
        
        let videoDevices = devices.filter
        {
            return $0.hasMediaType(AVMediaTypeVideo) &&
                    $0.position == .Back &&
                    ($0 as? AVCaptureDevice != nil)
        } as! [AVCaptureDevice]
        
        captureDevice = videoDevices.first
        if let _ = captureDevice
        {
            try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
    
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.view.layer.insertSublayer(previewLayer!, atIndex: 1)//(previewLayer!)
            
            previewLayer?.frame = self.view.layer.frame
            captureSession.startRunning()
        }
    }
    
    var cameraNode: SCNNode!
    var arrowNode: SCNNode!
    var arrowPosition: SCNVector3!
    var timer: CADisplayLink!
    
    @IBOutlet weak var scnView: SCNView!
    func setupScene()
    {
        let scene = SCNScene(named: "art.scnassets/arrow.scn")!
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.automaticallyAdjustsZRange = true
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x:0, y:0, z:0)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: -10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        arrowNode = scene.rootNode.childNodeWithName("arrow", recursively: true)!
        arrowPosition = SCNVector3(x: 0, y: 5 , z: -20)
        arrowNode.rotation = SCNVector4(1, 0.0, 0.0, Float(M_PI/2))
//        drawArrow()
//        animateArrow()
        
        arrowNode.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 0, z: 1, duration: 1)))
        let arrowScale: Float = 4.0
        arrowNode.scale = SCNVector3(x: arrowScale, y: arrowScale, z: arrowScale)
        
        scnView.scene = scene
        scnView.backgroundColor = UIColor.clearColor()
        
        timer = CADisplayLink(target: self, selector: Selector("animLoop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    var arrowZ: Float = 0
    var arrowZSeeds: Float = 0
    func animLoop()
    {
        arrowZSeeds += 0.1
        arrowZ = 3 * sinf(arrowZSeeds)
//        print("\(arrowZSeeds), \(arrowZ)")
//        drawArrow()
    }
    
    func orientationFromCMQuaternion(q: CMQuaternion) -> SCNQuaternion
    {
        let gq1 =  GLKQuaternionMakeWithAngleAndAxis(0, 1, 0, 0) // add a rotation of the pitch 90 degrees
        let gq2:GLKQuaternion =  GLKQuaternionMake(Float(q.x), Float(q.y), Float(q.z), Float(q.w)) // the current orientation
        let qp  =  GLKQuaternionMultiply(gq1, gq2) // get the "new" orientation
        let rq =   (x: qp.x, y: qp.y, z: qp.z, w: qp.w)

        return SCNVector4Make(rq.x, rq.y, rq.z, rq.w);
    }
    
    func latLonToEcef(lat: Double, lon: Double, alt: Double) -> SCNVector3
    {
        let degreesToRadians = M_PI/180.0
        let WGS84_A = 6378137.0             //  WGS 84 semi-major axis const in meters
        let WGS84_E = 8.1819190842622e-2    //  WGS 84 eccentricity
        
        let clat = cos(lat * degreesToRadians);
        let slat = sin(lat * degreesToRadians);
        let clon = cos(lon * degreesToRadians);
        let slon = sin(lon * degreesToRadians);
    
        let N = WGS84_A / sqrt(1.0 - WGS84_E * WGS84_E * slat * slat);
        
        let x = (N + alt) * clat * clon;
        let y = (N + alt) * clat * slon;
        let z = (N * (1.0 - WGS84_E * WGS84_E) + alt) * slat;
        
        return SCNVector3(x: Float(x), y: Float(y), z: Float(z))
    }
    
    let motionManager: CMMotionManager = CMMotionManager()
    func setupMotionTracking()
    {
        let updateInterval = 1/30.0
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.deviceMotionUpdateInterval = updateInterval
        
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(
            .XTrueNorthZVertical,
            toQueue: NSOperationQueue.mainQueue()) {
            motionDevice, error in
            
            if let attitude = motionDevice?.attitude
            {
                self.cameraNode.orientation = self.orientationFromCMQuaternion(attitude.quaternion)
            }
        }
    }


    
    var locationManager: CLLocationManager = CLLocationManager()
    func setupLocationManager()
    {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        locationManager.startUpdatingLocation()
    }
    
    var lastLocation: CLLocation?
    var lastPosition: SCNVector3?
    var lastAccuracy = 1000.0
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        guard let location = locations.last, poi = poiOpt where location.horizontalAccuracy <= lastAccuracy
                                                                || location.horizontalAccuracy <= 50
        else
        {
            return
        }
        
        print("horizontal Accuracy \(location.horizontalAccuracy) \(location.verticalAccuracy)")
        
        let altitude = location.altitude
        
        lastAccuracy = location.horizontalAccuracy

        let meXyz = latLonToEcef(
            location.coordinate.latitude,
            lon: location.coordinate.longitude,
            alt: altitude)
        
        let poiXyz = latLonToEcef(poi.latitude, lon: poi.longitude, alt: altitude + 3)
        
        let degreeStep = 0.1
        let northOfMe = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude + degreeStep,
            longitude: location.coordinate.longitude)
        let stepNorth = latLonToEcef(northOfMe.latitude, lon: northOfMe.longitude, alt: altitude)
        
        let westOfMe = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude - degreeStep)
        let stepWest = latLonToEcef(westOfMe.latitude, lon: westOfMe.longitude, alt: altitude)
        
        let stepUp = latLonToEcef(
            location.coordinate.latitude,
            lon: location.coordinate.longitude,
            alt: altitude + 1)

        
        let phoneX = (stepNorth - meXyz).normalize()
        let phoneY = (stepWest - meXyz).normalize()
        let phoneZ = (stepUp - meXyz).normalize()
        
        let row1 = SCNVector3(phoneX.x, phoneX.y, phoneX.z)
        let row2 = SCNVector3(phoneY.x, phoneY.y, phoneY.z)
        let row3 = SCNVector3(phoneZ.x, phoneZ.y, phoneZ.z)
        

        print(poi, altitude)
        print(poiXyz)
//        print(row1)
//        print(row2)
//        print(row3)
        
        let itRelativeToMe = poiXyz - meXyz
        let itRotatedRelativeToEarf = SCNVector3(
            row1.dotProduct(itRelativeToMe),
            row2.dotProduct(itRelativeToMe),
            row3.dotProduct(itRelativeToMe))

        arrowPosition = itRotatedRelativeToEarf
        
        
        let currentLocation = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
        
        if let last = lastPosition
        {
            print("diff \((last - arrowPosition).length())")
            
        }

        if let lastLoc = lastLocation
        {
            print("other distance \(currentLocation.distanceFromLocation(lastLoc))")
        }
        
        lastLocation = currentLocation
        lastPosition = arrowPosition
        
        animateArrow()
//        print("arrowZ: \( arrowZ )")
    }
    
    func drawArrow()
    {
//        arrowNode.position = arrowPosition
        arrowNode.position.z = arrowZ
    }
    func animateArrow()
    {
//                arrowNode.position = arrowPosition
        arrowNode.runAction(SCNAction.moveTo(arrowPosition, duration: 0.2))
    }

    
    //view controller and interactions
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupVideoCapture()
        setupScene()
        setupMotionTracking()
        setupLocationManager()

        view.backgroundColor = UIColor.redColor()
    }
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        captureSession?.stopRunning()
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        timer.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func back(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    deinit
    {
        print("GONE")
    }
    


}

