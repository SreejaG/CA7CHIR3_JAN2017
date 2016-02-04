//
//  UrlManager.swift
//  iONLive
//
//  Created by Gadgeon on 11/24/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation
class UrlManager {
    
    let baseUrl = "http://bpe.ioncameras.com:3000"
    let iONLiveCamUrl = "http://192.168.42.1:8888"
    
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
    
    func usersSignUpAPIUrl() -> (String) {
        let userLoginAPI = baseUrl+"/newUser"
        return userLoginAPI
    }
    
   func liveStreamingAPIUrl() -> String{
       let liveStreamingAPI = baseUrl+"/api/v1/livestream"
       return liveStreamingAPI
   }
    
    func iONLiveCamGetPictureUrl(scale: String!, burstCount: String!,burstInterval:String!,quality:String!) -> String
    {
        var getPictureUrl = iONLiveCamUrl+"/picture"
        if  scale?.isEmpty == false
        {
            getPictureUrl = getPictureUrl + "?scale=\(scale)"
        }
        if let burstCount = burstCount
        {
            if burstCount.isEmpty == false
            {
                getPictureUrl = getPictureUrl + "?burstCount=\(burstCount)"
            }
        }
        if burstInterval?.isEmpty == false
        {
            getPictureUrl = getPictureUrl + "?burstInterval=\(burstInterval)"
        }
        if quality?.isEmpty == false
        {
            getPictureUrl = getPictureUrl + "?quality=\(quality)"
        }
        return getPictureUrl
    }
    
    func getIONLiveCameraStatusUrl() -> String
    {
        return iONLiveCamUrl+"/status"
    }
    
    func getIONLiveCameraConfigUrl(scale: String!, quality: String!,singleClick:String?,doubleClick:String?) -> String
    {
        var getConfigUrl = iONLiveCamUrl+"/config"
        if scale.isEmpty == false
        {
            getConfigUrl = getConfigUrl + "?scale=\(scale)"
        }
        if quality?.isEmpty == false
        {
            getConfigUrl = getConfigUrl + "?quality=\(quality)"
        }
        if singleClick?.isEmpty == false
        {
            getConfigUrl = getConfigUrl + "?singleClick=\(singleClick)"
        }
        if doubleClick?.isEmpty == false
        {
            getConfigUrl = getConfigUrl + "?doubleClick=\(doubleClick)"
        }
        return getConfigUrl
    }
    
    func iONLiveCamDeletePictureUrl(cancelSnap: Bool, burstId: String?) -> String
    {
        var getPictureUrl = iONLiveCamUrl+"/picture"
        if cancelSnap == true
        {
            getPictureUrl = getPictureUrl + "?cancelSnaps"
        }
        else if let burstId = burstId
        {
            getPictureUrl = getPictureUrl + "?burstID=\(burstId)"
        }
        
        return getPictureUrl
    }
    
    func getiONLiveCamImageDownloadUrl(burstId:String) ->String
    {
        let getPictureUrl = iONLiveCamUrl+"/picture/\(burstId).jpg"
        return getPictureUrl
    }
    
    func getiONLiveVideoUrl()->String
    {
        let getVideoUrl = iONLiveCamUrl+"/video"
        return getVideoUrl
    }
    
    func getiONLiveVideom3u8Url(hlsId:String)->String
    {
        let getVideoUrl = iONLiveCamUrl+"/video/\(hlsId).m3u8"
        return getVideoUrl
    }
}
    