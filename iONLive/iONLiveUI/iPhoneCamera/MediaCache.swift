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
        // Dispose of any resources that can be recreated.
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
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/ca7ch"
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
         let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/ca7ch"
       // let documentsURL = documentsPath.URLByAppendingPathComponent("ca7ch")
        return  NSURL(string: documentsPath)!
    }
    func saveImage (image: UIImage, path: String ) -> Bool{
        
//          let documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as ns
//        let documentsURL = documentsFolderPath.URLByAppendingPathComponent("ca7ch")
//        let fm2 = NSFileManager.defaultManager()
//        do {
//            let items = try fm2.contentsOfDirectoryAtPath(String(documentsURL))
//            
//            for item in items {
//                print("Items before------> \(item)")
//            }
//        } catch {
//            // failed to read directory – bad permissions, perhaps?
//        }

        let pngImageData = UIImageJPEGRepresentation(image, 0.5)
        //let jpgImageData = UIImageJPEGRepresentation(image, 1.0)   // if you want to save as JPEG
        let result = pngImageData!.writeToFile(path, atomically: true)
        
        return result
        
    }
    func fileExist(path: String) -> Bool
    {
//        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
//        let documentsURL = documentsPath.URLByAppendingPathComponent("ca7ch")
//        let mediaPath = documentsDirectoryPath + "everythingswift.txt"
        let fileManager = NSFileManager.defaultManager()

        if(fileManager.fileExistsAtPath(path))
        {
            return true
        }
        return false
    }
    func loadImageFromPath(path: String) -> UIImage? {
        
        let image = UIImage(contentsOfFile: path)
        
        if image == nil {
            
            print("missing image at: \(path)")
        }
        print("Loading image from path: \(path)") // this is just for you to see the path in case you want to go to the directory, using Finder.
        return image
        
    }
    func setResponse(dic : NSMutableDictionary)
    {
       // Dict.removeAllObjects()
        Dict = dic
        print(Dict)
    }
    func getResponse() -> NSMutableDictionary
    {
        return Dict
    }
        
}
