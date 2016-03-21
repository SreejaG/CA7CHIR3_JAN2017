//
//  PendingOperations.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/17/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

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
