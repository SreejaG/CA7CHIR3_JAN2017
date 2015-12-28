//
//  StreamingProtocol.swift
//  iONLive
//
//  Created by Vinitha on 12/2/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation

@objc protocol StreamingProtocol {
    
    func updateStreamingStatus()
    func cameraSelectionMode(selection:SnapCamSelectionMode)
}