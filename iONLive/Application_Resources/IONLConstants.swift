
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
let vowzaIp = "130.211.135.170"

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


