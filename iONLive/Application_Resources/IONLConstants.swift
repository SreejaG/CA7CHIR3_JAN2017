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

@objc enum SnapCamSelectionMode : Int {
    
    case LiveStream
    case Photos
    case Video
    case CatchGif
    case Timelapse
    case iPhone
    case DefaultMode
    
    init() {
        self = .DefaultMode
    }
    
//    init(rawValue : String)
//    {
//        self = SnapCamSelectionMode(rawValue: rawValue)
//    }
}
