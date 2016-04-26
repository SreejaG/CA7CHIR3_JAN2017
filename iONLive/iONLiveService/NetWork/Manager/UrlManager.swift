//
//  UrlManager.swift
//  iONLive
//
//  Created by Gadgeon on 11/24/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation
class UrlManager {
    
    let baseUrl = "http://104.196.113.247:3000";
//    let baseUrl = "http://192.168.16.60:3000";
    //"http://bpe.ioncameras.com:3000"
    let iONLiveCamUrl = "http://192.168.42.1:8888"
    
    class var sharedInstance: UrlManager {
        struct Singleton {
            static let instance = UrlManager()
        }
        return Singleton.instance
    }
    
    func usersLoginAPIUrl() -> (String) {
        let userLoginAPI =  baseUrl+"/api/v1/session"    //baseUrl+"/login"
        return userLoginAPI
    }
    
    func usersSignUpAPIUrl() -> (String) {
        let userLoginAPI =  baseUrl+"/api/v1/user"     // baseUrl+"/newUser"
        return userLoginAPI
    }
    
    func contactAPIUrl() -> (String) {
        let contactAPI =  baseUrl+"/api/v1/contacts"
        return contactAPI
    }
    
   func liveStreamingAPIUrl() -> String{
       let liveStreamingAPI = baseUrl+"/api/v1/livestream"
       return liveStreamingAPI
   }
    
    func channelAPIUrl() -> String{
        let channelAPI = baseUrl+"/api/v1/channel"
        return channelAPI
    }
    func mediaUploadUrl() -> String{
        
        let mediaUrl="https://abdulmanafcjbucket.commondatastorage.googleapis.com/shamly.png?GoogleAccessId=signedurl@ion-live-1120.iam.gserviceaccount.com&Expires=1458125385&Signature=d6bx5yAPd5c6TWNV4qQoniyIsoaCfSX8ppJamP8dlIz6NSLSYJf81lUjgDDZJPUp63MKhXVCC3A01eveVxGG6KwTWV0z9dFeHBZjLXYlVKT3%2F8FliNCBckvmCP7e8YC8ITKfY44r41xO6Qk2EBdT0PeEty0pgRDxnluTKnTCBkgxo6h4Q8qUTNLHFPw274QtYrDpXnrSBaj7%2FsdhvnrPhRaQ1gRYFBQhREGfQuVMhjSeXbDBWj5b8VtYohqe1ObhnOiIpP8ci4Kn2z6NmwPyYxVcTLHQ2H5YoiB3d3Do91s6K8UZKHj5vtPp23lhO8Gifo9a8jiekpbW1eKz30CHOQ%3D%3D";
        return mediaUrl
        
    }
    func getChannelMediaDetails(channelId : String, userName: String, accessToken: String , limit : String , offset : String) -> String
    {
        let getchannelMediaDetailsAPI = baseUrl+"/api/v1/media" + "/" + channelId + "/"  + userName + "/" + accessToken + "/" + limit + "/" + offset
        return getchannelMediaDetailsAPI
    }
    func getSubscribedChannelMediaDetails(userName: String, accessToken: String , limit : String , offset : String) -> String
    {
        let getchannelSubscribedMediaDetailsAPI = baseUrl+"/api/v1/media" + "/" + userName + "/" + accessToken + "/" + limit + "/" + offset
        return getchannelSubscribedMediaDetailsAPI
    }
    func defaultCHannelMediaMapping(objectName: String) -> String
    {
        let defaultCHannelMediaMapping = baseUrl+"/api/v1/media" + "/" + objectName
        return defaultCHannelMediaMapping
    }
    func gesMediaObjectCreationUrl() -> String
    {
        let gesMediaObjectCreationUrl = baseUrl+"/api/v1/media"
        return gesMediaObjectCreationUrl
    }
    func MediaInteractionUrl() -> String{
        let mediaInteractionAPI = baseUrl+"/api/v1/mediaInteraction"
        return mediaInteractionAPI
    }
    func SubscribedChannelUrl() -> String{
        let SubscribedChannelAPI = baseUrl+"/api/v1/sharedChannel"
        return SubscribedChannelAPI
    }
    func SubscribedChannelMediaUrl() -> String{
        let SubscribedChannelAPI = baseUrl+"/api/v1/media"
        return SubscribedChannelAPI
    }
    func MediaByChannelAPIUrl(userName: String, accessToken: String) -> String
    {
        let MediaByChannelAPI = gesMediaObjectCreationUrl() + "/" + userName + "/" + accessToken
        return MediaByChannelAPI
    }
    func getUserRelatedDataAPIUrl(userName: String) -> String
    {
        let getUserRelatedDataAPI = usersSignUpAPIUrl() + "/" + userName
        return getUserRelatedDataAPI
    }
    func getProfileDataAPIUrl(userName: String, accessToken: String) -> String
    {
        let getProfileDataAPI = usersSignUpAPIUrl() + "/" + userName + "/" + accessToken
        return getProfileDataAPI
    }
    func getContactDataAPIUrl(userName: String, accessToken: String) -> String
    {
        let getContactDataAPI = contactAPIUrl() + "/" + userName + "/" + accessToken
        return getContactDataAPI
    }
    func getProfileImageAPIUrl(userName: String, accessToken: String) -> String
    {
        let getProfileImageAPI = usersSignUpAPIUrl() + "/" + userName + "/" + accessToken
        return getProfileImageAPI
    }
    func getAllChannelsAPIUrl(userName: String, accessToken: String) -> String
    {
        let getAllChannelsAPI = channelAPIUrl() + "/" + userName + "/" + accessToken
        return getAllChannelsAPI
    }
    func getAllContactsChannelAPIUrl(channelId: String, userName: String, accessToken: String) -> String
    {
        let getAllContactsChannelAPI = channelAPIUrl() + "/" + channelId  + "/" + userName + "/" + accessToken
        return getAllContactsChannelAPI
    }
    func getDeleteContactChannelAPIUrl(channelId: String, userName: String, accessToken: String, contactName:String) -> String
    {
        let getDeleteContactChannelAPI = channelAPIUrl() + "/" + channelId  + "/" + contactName + "/" + userName + "/" + accessToken
        return getDeleteContactChannelAPI
    }
    
    func getNonContactsChannelAPIUrl(channelId: String, userName: String, accessToken: String) -> String
    {
        let getNonContactsChannelAPI = contactAPIUrl() + "/" + channelId  + "/" + userName + "/" + accessToken
        return getNonContactsChannelAPI
    }
    func inviteContactsChannelAPIUrl(channelId: String) -> String
    {
        let inviteContactsChannelAPI = channelAPIUrl() + "/" + channelId
        return inviteContactsChannelAPI
    }
    
    func getMediaInteractionNotifications(userName: String, accessToken: String) -> String
    {
        let mediaInteractionNotification = MediaInteractionUrl() + "/" + userName + "/" + accessToken
        return mediaInteractionNotification
    }
    
    func getChannelSharedDetails(userName: String, accessToken: String) -> String
    {
        let channelSharedAPI = SubscribedChannelUrl() + "/" + userName + "/" + accessToken
        return channelSharedAPI
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
    
    func iONLiveCamDeletePictureUrl(burstId: String!) -> String
    {
        var getPictureUrl = iONLiveCamUrl+"/picture"
        
        if burstId.isEmpty == false
        {
            let stringArray = burstId.componentsSeparatedByString(".")
            
            let burstIdUrl = stringArray[0]
            
            getPictureUrl = getPictureUrl + "?burstID=\(burstIdUrl)"
        }
        return getPictureUrl
        
    }
    
    func iONLiveCamDeleteAllPictureUrl() -> String
    {
        let getPictureUrl = iONLiveCamUrl+"/picture?burstID=*"
        
        return getPictureUrl
    }
    
    func iONLiveCamCancelSnapsUrl() -> String
    {
        let getPictureUrl = iONLiveCamUrl+"/picture?cancelSnaps"
        
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

    func getiONLiveVideoUrlWithHlsId(hlsId:String)->String
    {
        var getVideoUrl = iONLiveCamUrl+"/video"
        
        if hlsId.isEmpty == false
        {
            let stringArray = hlsId.componentsSeparatedByString(".")
            
            let vldIdUrl = stringArray[0]
            
            getVideoUrl = getVideoUrl + "?hlsID=\(vldIdUrl)"
        }
        return getVideoUrl
    }
    
    func getAlliONLiveVideoUrl()->String
    {
        let getVideoUrl = iONLiveCamUrl+"/video?hlsID=*"
        return getVideoUrl
    }
    
    func getiONLiveVideom3u8Url(hlsId:String)->String
    {
        let getVideoUrl = iONLiveCamUrl+"/video/\(hlsId).m3u8"
        return getVideoUrl
    }
    
}
    