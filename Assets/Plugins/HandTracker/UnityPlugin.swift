//
//  UnityPlugin.swift
//  HandPose
//
//  Created by Ontario Britton on 11/25/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit

/*
Abstract:
Unity Plugin provides Swift access to start hand tracking and fetch tracked joints
*/
@objc public class UnityPlugin : NSObject {
    var camViewController = CameraViewController()
    
    //Singleton access to this class
    @objc public static let shared = UnityPlugin()
    
    /*
     initializeHandTracker sets up the CameraViewController's preview,
        which in turns starts hand tracking
     */
    @objc public func initializeHandTracker() {
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
    }
    
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
            return camViewController.orderedWristJointsStr
        case 2:
            //TODO: implement return of finger tip joints in CameraViewController
            return camViewController.orderedFingerTipJointsStr
        default:
            //TODO: implment return of all joints in CameraViewController
            return camViewController.orderedAllJointsStr
        }
    }
}
