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
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        let ship = scene.rootNode.childNodeWithName("ship", recursively: true)!
        ship.position = SCNVector3(x: 0, y: 0 , z: -20)
        
        
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
    
    

    
    func latLonToEcef(lat: Double, lon: Double, alt: Double) -> (x: Double, y:Double, z:Double)
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
        
        return (x, y, z)
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
    
    
    
    var locationManager: CLLocationManager = CLLocationManager()
    func setupLocationManager()
    {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        guard let location = locations.last
        else
        {
            return
        }
        
        let accuracy = location.horizontalAccuracy
        
        print("\(location.coordinate.latitude), \(location.coordinate.longitude), \(location.altitude)")
        let xyz = latLonToEcef(location.coordinate.latitude, lon: location.coordinate.longitude, alt: location.altitude)
        print(xyz)
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

