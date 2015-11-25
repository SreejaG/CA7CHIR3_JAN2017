//
//  UrlManager.swift
//  iONLive
//
//  Created by Gadgeon on 11/24/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation
class UrlManager {
    
    let baseUrl = "http://104.197.159.157:3000"
    
    class var sharedInstance: UrlManager {
        struct Singleton {
            static let instance = UrlManager()
        }
        return Singleton.instance
    }
    
    func usersLoginAPIUrl() -> (String) {
        let userLoginAPI = baseUrl+"/login"
        return userLoginAPI
    }
    
   func liveStreamingAPIUrl() -> String{
       let liveStreamingAPI = baseUrl+"/api/v1/livestream"
       return liveStreamingAPI
   }
    
}
    