//
//  PhotoUploadAndDownloadManager.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/17/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//
import UIKit
enum PhotoRecordState {
    case New, Downloaded,Uploaded, Failed
}
class PhotoRecord: NSObject {
    
    let name:String
    let url:NSURL
    var state = PhotoRecordState.New
    var image = UIImage(named: "Placeholder")
    
    init(name:String, url:NSURL) {
        self.name = name
        self.url = url
    }
    
    
    class PendingOperations: NSObject {
        lazy var downloadsInProgress = [NSIndexPath:NSOperation]()
        lazy var downloadQueue:NSOperationQueue = {
            var queue = NSOperationQueue()
            queue.name = "Download queue"
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        lazy  var uploadInProgress = [NSIndexPath:NSOperation]()
        lazy  var uploadQueue:NSOperationQueue = {
            var queue = NSOperationQueue()
            queue.name = "Upload queue"
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        
    }
    class ImageDownloader: NSOperation {
        //1
        let photoRecord: PhotoRecord
        
        //2
        init(photoRecord: PhotoRecord) {
            self.photoRecord = photoRecord
        }
        
        //3
        override func main() {
            //4
            if self.cancelled {
                return
            }
            //5
            let imageData = NSData(contentsOfURL:self.photoRecord.url)
            
            //6
            if self.cancelled {
                return
            }
            
            //7
            if imageData?.length > 0 {
                self.photoRecord.image = UIImage(data:imageData!)
                self.photoRecord.state = .Downloaded
            }
            else
            {
                self.photoRecord.state = .Failed
                self.photoRecord.image = UIImage(named: "Failed")
            }
        }
    }
    class ImageUploader: NSOperation {
        //1
        let photoRecord: PhotoRecord
        
        //2
        init(photoRecord: PhotoRecord) {
            self.photoRecord = photoRecord
        }
        
        //3
        override func main() {
            //4
            if self.cancelled {
                return
            }
            //5
            let imageData = NSData(contentsOfURL:self.photoRecord.url)
            
            //6
            if self.cancelled {
                return
            }
            
            //7
            if imageData?.length > 0 {
                self.photoRecord.image = UIImage(data:imageData!)
                self.photoRecord.state = .Downloaded
            }
            else
            {
                self.photoRecord.state = .Failed
                self.photoRecord.image = UIImage(named: "Failed")
            }
        }
    }

}
