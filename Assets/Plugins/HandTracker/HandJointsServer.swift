//
//  HandJointsServer.swift
//
//  Created by Ontario Britton on 11/25/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Vision

/*
Abstract:
 Hand Joints Server provides Swift access to start hand tracking and fetch a subset of tracked joints
*/
@objc public class HandJointsServer : NSObject {
    
    //Singleton access to this class
    @objc public static let shared = HandJointsServer()
    
    //Access to the ViewController the displays the camera feed and queries the join tracking on it
    var camViewController = CameraViewController()
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private let trackingConfidenceCutoff : Float = 0.3
    private let sigfigRoundingFactor = 1000.0
    
    private var wristPoint = CGPoint(x: -1, y: -1)      //Wrist
    private var indexMcpPoint = CGPoint(x: -1, y: -1)   //Index finger bottom knuckle, aka Index MCP
    private var littleMcpPoint = CGPoint(x: -1, y: -1)  //Little finger bottom knuckle, aka Little MCP
    
    /*
     initializeHandTracker sets up the CameraViewController's preview,
        which in turns starts hand tracking
     */
    @objc public func initializeHandTracker() {
        //TODO: migreat view configuration into camViewController
        guard let appDelegate = UIApplication.shared.delegate,
        let window = appDelegate.window,
        let rootView = window?.rootViewController?.view else { return }

        camViewController.view.translatesAutoresizingMaskIntoConstraints = false
        let frame = CGRect(x: 0, y: 0, width: rootView.frame.size.height, height: rootView.frame.size.width)
        camViewController.view.frame = frame
        camViewController.view.center = rootView.center
        window?.insertSubview(camViewController.view, at: 0)
        camViewController.view.transform = CGAffineTransform(rotationAngle: .pi/2)
        rootView.isOpaque = false
        rootView.backgroundColor = UIColor.clear
        
        camViewController.videoDataDelegate = self
        handPoseRequest.maximumHandCount = 1
    }
    
    //Wrist supporting joints ordered as wrist, index finger bottom knuckle, little finger bottom knuckle
    var orderedWristJointsStr : String {
        get {
            return "\(wristPoint.x),\(wristPoint.y)|\(indexMcpPoint.x),\(indexMcpPoint.y)|\(littleMcpPoint.x), \(littleMcpPoint.y)"
        }
    }
    //TODO: implement return of finger tip joints
    let orderedFingerTipJointsStr = ""
    //TODO: implement return of all joints
    let orderedAllJointsStr = ""
    
    /*
     getHandJoints fetches a formatted string of related, desired joints
        @param jointElection is an Int for choosing wrist joints, fingertip joints, or all joints
        @return a formatted string for requested joints,
            e.g. "x1,y1|x2,y2|n1,n2"
     */
    @objc public func getHandJoints(jointElection: Int) -> String {
        switch(jointElection)
        {
        case 1:
            return orderedWristJointsStr
        case 2:
            //TODO: implement return of finger tip joints in CameraViewController
            return orderedFingerTipJointsStr
        default:
            //TODO: implment return of all joints in CameraViewController
            return orderedAllJointsStr
        }
    }
}
//TODO: migrate Delgation out of CameraViewController to here
extension HandJointsServer: AVCaptureVideoDataOutputSampleBufferDelegate {
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
//            cameraFeedSession?.stopRunning() //TODO: move out
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
