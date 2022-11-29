/*
See LICENSE folder for this sample’s licensing information.

Apple Abstract:
Camera view shows the feed from the camera
*/

import UIKit
import AVFoundation

class CameraView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
