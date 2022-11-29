/*
See LICENSE folder for this sample’s licensing information.

Apple Abstract:
The app's main view controller object.
 Based largely on Apple's sample code "Detecting Hand Poses with Vision"
 https://developer.apple.com/documentation/vision/detecting_hand_poses_with_vision
*/

import UIKit
import AVFoundation
import Vision

/*
Abstract:
CameraViewController holds the camera view to be shown behind the Unity view,
    and sets up the VNDetectHumanHandPoseRequest to fetch all hand joints in the camera feed
*/
class CameraViewController: UIViewController {

    private var cameraView: CameraView { view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var wristPoint = CGPoint(x: -1, y: -1)      //Wrist
    private var indexMcpPoint = CGPoint(x: -1, y: -1)   //Index finger bottom knuckle, aka Index MCP
    private var littleMcpPoint = CGPoint(x: -1, y: -1)  //Little finger bottom knuckle, aka Little MCP
    
    private let trackingConfidenceCutoff : Double = 0.3
    private let sigfigRoundingFactor = 1000.0
    
    //Wrist supporting joints ordered as wrist, index finger bottom knuckle, little finger bottom knuckle
    var orderedWristJointsStr : String {
        get {
            return "\(wristPoint.x),\(wristPoint.y)|\(indexMcpPoint.x),\(indexMcpPoint.y)|\(littleMcpPoint.x), \(littleMcpPoint.y)"
        }
    }
    
    //TODO: implement return of finger tip joints
    let orderedFingerTipJointsStr = ""
    //TODO: implment return of all joints
    let orderedAllJointsStr = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = CameraView()
        // This sample app detects one hand only.
        handPoseRequest.maximumHandCount = 1
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    /*
     setupAVSession prepares and starts an AVCapturSession
     */
    func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            return
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            return
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    /*
     captureOutput is the delegate method for handling each frame,
        defined in AVCaptureVideoDataOutputSampleBufferDelegate
     */
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            let indexPoints = try observation.recognizedPoints(.indexFinger)
            let indexMcpPos = knucklePos(fingerJoints: indexPoints, jointName: .indexMCP)
            self.indexMcpPoint = createRoudedCGPoint(x: indexMcpPos.x, y: indexMcpPos.y)
            
            let littlePoints = try observation.recognizedPoints(.littleFinger)
            let littleMcpPos = knucklePos(fingerJoints: littlePoints, jointName: .littleMCP)
            self.littleMcpPoint = createRoudedCGPoint(x: littleMcpPos.x, y: littleMcpPos.y)
            
            let wristPoint = try observation.recognizedPoint(.wrist)
            self.wristPoint = createRoudedCGPoint(x: wristPoint.x, y: wristPoint.y)
        } catch {
            cameraFeedSession?.stopRunning()
            return
        }
    }
    
    /*
     knucklePos returns the named joint in a dictionary of related joints
        with components rounded to 3-sigdigs
        @param fingerJoints is a dictionary of related joints
        @param jointName is the VNHumanHandPoseObservation key of the desired joint
        @return the CGPoint location of the joint from fingerJoints for the key jointName
     */
    func knucklePos(fingerJoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint],
                      jointName: VNHumanHandPoseObservation.JointName) -> CGPoint {
        guard let fingerTipPoint = fingerJoints[jointName], fingerTipPoint.confidence > trackingConfidenceCutoff else {
            return CGPoint(x: -1, y: -1)
        }
        
        return createRoudedCGPoint(x: fingerTipPoint.x, y: fingerTipPoint.y)
    }
    
    /*
     createRoundedCGPoint calculates a CGPoint rounded to 3-sigdigs
        @param x is a float for the coord's x component
        @param y is a float for the coord's y component
        @return a CGPoint with x and y rounded to 3-sigdigs
     */
    func createRoudedCGPoint(x: Double, y: Double) -> CGPoint {
        return CGPoint(x: round(x * sigfigRoundingFactor) / sigfigRoundingFactor,
                       y: round (y * sigfigRoundingFactor) / sigfigRoundingFactor)
    }
}

