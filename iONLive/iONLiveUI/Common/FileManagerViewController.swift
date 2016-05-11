//
//  FileManagerViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 30/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class FileManagerViewController: UIViewController {
    
    class var sharedInstance: FileManagerViewController {
        struct Singleton {
            static let instance = FileManagerViewController()
        }
        return Singleton.instance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func createParentDirectory() -> Bool
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
    
    func getParentDirectoryPath() -> NSURL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        return  NSURL(string: documentsPath)!
    }
    
    func fileExist(mediaPath: String) -> Bool
    {
        let flag : Bool
        print(mediaPath)
        let fileManager = NSFileManager.defaultManager()
        if(fileManager.fileExistsAtPath(mediaPath))
        {
            flag = true
        }
        else{
            flag = false
        }
        return flag
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func  saveImageToFilePath(mediaName: String, mediaImage: UIImage) -> Bool {
        let parentPath = getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaName)"
        let mediaSaveFlag : Bool
        print(savingPath)
        if(mediaImage != UIImage())
        {
            let image = UIImageJPEGRepresentation(mediaImage, 0.5)
            let result = image!.writeToFile(savingPath, atomically: true)
            mediaSaveFlag = result
        }
        else{
            mediaSaveFlag = false
        }
        return mediaSaveFlag
    }
    
    func getImageFromFilePath(mediaPath: String) -> UIImage? {
        var mediaimage : UIImage = UIImage()
        print(mediaPath)
        if(fileExist(mediaPath)){
            mediaimage = UIImage(contentsOfFile: mediaPath)!
        }
        else{
            mediaimage = UIImage()
        }
        return mediaimage
    }
    
    
    func deleteImageFromFilePath(mediaPath: String) -> Int {
        let mediaDeleteFlag : Int
        let fileManager = NSFileManager.defaultManager()
        print(mediaPath)
        if(fileExist(mediaPath)){
            do {
                try fileManager.removeItemAtPath(mediaPath)
                mediaDeleteFlag = 1
            }
            catch let error as NSError {
                mediaDeleteFlag = 0
                print("Ooops! Something went wrong: \(error)")
            }
        }
        else{
            mediaDeleteFlag = 0
        }
        if(fileExist(mediaPath)){
            print("hi exist")
        }
        else{
            print("no file")
        }
        
        return mediaDeleteFlag
    }
}
