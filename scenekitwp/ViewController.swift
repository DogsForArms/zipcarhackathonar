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

class ViewController: UIViewController, CLLocationManagerDelegate
{

    
    @IBOutlet weak var dist: UILabel!
    @IBOutlet weak var dx: UILabel!
    @IBOutlet weak var dy: UILabel!
    @IBOutlet weak var dz: UILabel!
    
    
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var captureView: UIView!
    func setupVideoCapture()
    {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh// AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        print(devices)
        
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if let capDevice = captureDevice
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
    
    @IBOutlet weak var scnView: SCNView!
    func setupScene()
    {
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
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
        
        arrowNode = scene.rootNode.childNodeWithName("ship", recursively: true)!
        arrowNode.position = SCNVector3(x: 20, y: 0 , z: 0)
        
        
        arrowNode.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 0, z: 1, duration: 1)))
        
//        let arrowScale: Float = 1.0
//        arrowNode.scale = SCNVector3(x: arrowScale, y: arrowScale, z: arrowScale)
        
        scnView.scene = scene
        scnView.backgroundColor = UIColor.clearColor()
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
        motionManager.accelerometerUpdateInterval = 1/60
        
        //CMAttitudeReferenceFrameXTrueNorthZVertical
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XTrueNorthZVertical, toQueue: NSOperationQueue.mainQueue()) {
            motionDevice, error in
            
            if let attitude = motionDevice?.attitude
            {
                self.cameraNode.orientation = self.orientationFromCMQuaternion(attitude.quaternion)
            }
        }
    }

    let bballCourt = CLLocationCoordinate2D(latitude: 42.350883, longitude:  -71.046777)
    let pointInTheNorth = CLLocationCoordinate2D(latitude: 79.738839, longitude: -71.566170)
    
    var locationManager: CLLocationManager = CLLocationManager()
    func setupLocationManager()
    {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        locationManager.startUpdatingLocation()
        
    }
    
    
    var lastAccuracy = 80.0
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        guard let location = locations.last
        else
        {
            return
        }
        
        print("horizontal Accuracy \(location.horizontalAccuracy)")
        
        if (location.horizontalAccuracy <= lastAccuracy)
        {
            lastAccuracy = location.horizontalAccuracy
        }
        
        let accuracy = location.horizontalAccuracy
        
        print("Me: \(location.coordinate), \(location.altitude)")
        let meXyz = latLonToEcef(
            location.coordinate.latitude,
            lon: location.coordinate.longitude,
            alt: location.altitude)
        
//        self.dx.text = "dx \(dx)"
//        self.dy.text = "dy \(dy)"
//        self.dz.text = "dz \(dz)"
//        self.dist.text = "dist \(dist)"
        
        let bballXyz = latLonToEcef(bballCourt.latitude, lon: bballCourt.longitude, alt: location.altitude + 3)
        
        let degreeStep = 0.00001
        let northOfMe = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude + degreeStep,
            longitude: location.coordinate.longitude)
        let stepNorth = latLonToEcef(northOfMe.latitude, lon: northOfMe.longitude, alt: location.altitude)
        
        let westOfMe = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude - degreeStep)
        let stepWest = latLonToEcef(westOfMe.latitude, lon: westOfMe.longitude, alt: location.altitude)
        
        let stepUp = latLonToEcef(
            location.coordinate.latitude,
            lon: location.coordinate.longitude,
            alt: location.altitude + 1)
        
        //        let northIsh = (northXyz - meXyz).normalize().scale(30) + meXyz
//        print("dN \((stepNorth - meXyz).length())")
//        print("dW \((stepWest - meXyz).length())")
//        print("dU \((stepUp - meXyz).length())")
        
        
        let phoneX = (stepNorth - meXyz).normalize()
        let phoneY = (stepWest - meXyz).normalize()
        let phoneZ = (stepUp - meXyz).normalize()
        
//        print("x \(phoneX) length: \(phoneX.length())")
//        print("y \(phoneY) length: \(phoneY.length())")
//        print("z \(phoneZ) length: \(phoneZ.length())")
        
        let row1 = SCNVector3(phoneX.x, phoneX.y, phoneX.z)
        let row2 = SCNVector3(phoneY.x, phoneY.y, phoneY.z)
        let row3 = SCNVector3(phoneZ.x, phoneZ.y, phoneZ.z)
        
        
        let itRelativeToMe = bballXyz - meXyz
        let itRotatedRelativeToEarth = SCNVector3(
            row1.dotProduct(itRelativeToMe),
            row2.dotProduct(itRelativeToMe),
            row3.dotProduct(itRelativeToMe))

        
        arrowNode.position = itRotatedRelativeToEarth
        
    }

    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupVideoCapture()
        setupScene()
        setupMotionTracking()
        setupLocationManager()

        view.backgroundColor = UIColor.redColor()
        
    }
    
    

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

