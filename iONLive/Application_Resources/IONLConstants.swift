//
//  IONLConstants.swift
//  iONLive
//
//  Created by Gadgeon on 11/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation
let userLoginIdKey = "userLoginIdKey"
let userAccessTockenKey = "userAccessTockenKey"

let apiErrorMessageKey = "errorMessage"

let startedStreaming = "StartedStreaming"
let streamingToken = "StreamingToken"

enum SnapCamSelectionMode {
    
    case cameraMode
    case liveStreamMode
    case defaultMode
    
    init() {
        self = .cameraMode
    }
}
