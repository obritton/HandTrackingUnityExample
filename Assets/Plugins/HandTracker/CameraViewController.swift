/*
See LICENSE folder for this sample’s licensing information.

Apple Abstract:
The app's main view controller object.
 Based largely on Apple's sample code "Detecting Hand Poses with Vision"
 https://developer.apple.com/documentation/vision/detecting_hand_poses_with_vision
*/

import UIKit
import AVFoundation

/*
Abstract:
CameraViewController holds the camera view to be shown behind the Unity view,
    and sets up the VNDetectHumanHandPoseRequest to fetch all hand joints in the camera feed
*/
class CameraViewController: UIViewController {    
    private var cameraView: CameraView { view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    
    public var videoDataDelegate : AVCaptureVideoDataOutputSampleBufferDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = CameraView()
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
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else { return }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        guard session.canAddOutput(dataOutput) else { return }
        session.addOutput(dataOutput)
        // Add a video data output.
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        guard let delegate = videoDataDelegate else { return }
        dataOutput.setSampleBufferDelegate(delegate, queue: videoDataOutputQueue)
        
        session.commitConfiguration()
        cameraFeedSession = session
    }
}
