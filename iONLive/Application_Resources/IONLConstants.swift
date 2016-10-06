
import Foundation
let userLoginIdKey = "userLoginIdKey"
let userAccessTockenKey = "userAccessTockenKey"
let userBucketName = "userBucketName"
let archiveId = "archiveId"
let ArchiveCount =  "archiveMediaCount"
let apiErrorMessageKey = "errorMessage"
let apiErrorCodeKey = "errorCode"
let pullTorefreshKey = "channel_media_detail_id"
let infiniteScrollIdKey = "channel_media_detail_id"
let startedStreaming = "StartedStreaming"
let streamingToken = "StreamingToken"
let initializingStream = "InitializingStream"
let subChannelIdKey = "channel_sub_detail_id"
let apiDeveloperFailureMessage = "developerMsg"

//let vowzaIp = "104.197.92.137" //test

let vowzaIp = "104.154.69.174" //production

//channel details

let channelIdKey = "channel_detail_id"
let channelNameKey = "channel_name"
let totalMediaKey = "total_media_count"
let createdTimeKey = "created_timeStamp"
let sharedOriginalKey = "orgSelected"
let sharedTemporaryKey = "tempSelected"

//media details

let mediaIdKey = "media_detail_id"
let tImageKey = "thumbImage"
let tImageURLKey = "thumbImage_URL"
let fImageURLKey = "fullImage_URL"
let notifTypeKey = "notification_type"
let mediaTypeKey = "media_type"
let progressKey = "upload_progress"
let channelMediaIdKey = "channel_media_detail_id"


@objc enum SnapCamSelectionMode : Int {
    
    case LiveStream = 0
    case Photos
    case Video
    case CatchGif
    case Timelapse
    case iPhone
    case TestAPI
    case SnapCam
    
    init() {
        self = .Photos
    }

}


