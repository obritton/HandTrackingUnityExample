//
//  UnityPluginBridge.mm
//  HandPose
//
//  Created by Ontario Britton on 11/25/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "UnityFramework/UnityFramework-Swift.h"

/*
Abstract:
UnityPluginBridge exposes passthrough calls from C# to objective-C,
    and convenieicne functions for formatting from objective-C to C
*/
extern "C" {

char* convertNSStringToCString(const NSString* nsString){
    if(nsString == NULL ) {
        return NULL;
    }
    
    const char* nsStringUtf8 = [nsString UTF8String];
    char* cString = (char*)malloc(strlen(nsStringUtf8) + 1);
    strcpy(cString, nsStringUtf8);
    
    return cString;
}

void _initializeHandTracker(){
    [[HandJointsServer shared] initializeHandTracker];
}

char* _getHandJoints(int jointElection){
    NSString* result = [[HandJointsServer shared] getHandJointsWithJointElection:jointElection];
    return convertNSStringToCString(result);
}

}
