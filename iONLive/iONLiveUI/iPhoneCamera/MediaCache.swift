//
//  MediaCache.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/30/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit
var Dict : NSMutableDictionary = NSMutableDictionary()

class MediaCache: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    class var sharedInstance: MediaCache {
        struct Singleton {
            static let instance = MediaCache()
        }
        return Singleton.instance
    }
    
    func createCa7chDirectory()-> Bool
    {
        let flag:Bool
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(documentsPath, withIntermediateDirectories: true, attributes: nil)
            flag = true
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
            flag = false
        }
        return flag
    }
    
    func getDocumentsURL() -> NSURL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        return  NSURL(string: documentsPath)!
    }
    
    func saveImage (image: UIImage, path: String ) -> Bool{
        let pngImageData = UIImageJPEGRepresentation(image, 0.5)
        let result = pngImageData!.writeToFile(path, atomically: true)
        return result
    }
    
    func fileExist(path: String) -> Bool
    {
        let fileManager = NSFileManager.defaultManager()
        if(fileManager.fileExistsAtPath(path))
        {
            return true
        }
        return false
    }
    
    func loadImageFromPath(path: String) -> UIImage? {
        
        let image = UIImage(contentsOfFile: path)
        return image
    }
    
    func setResponse(dic : NSMutableDictionary)
    {
        Dict = dic
    }
    
    func getResponse() -> NSMutableDictionary
    {
        return Dict
    }
    
}
