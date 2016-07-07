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
        if(mediaImage != UIImage())
        {
            if let image = UIImageJPEGRepresentation(mediaImage, 0.5)
            {
    
                print(savingPath)
                let result = image.writeToFile(savingPath, atomically: true)
                mediaSaveFlag = result
            }
            else{
                mediaSaveFlag = false
            }
        }
        else{
            mediaSaveFlag = false
        }
        return mediaSaveFlag
    }
    
    func getImageFromFilePath(mediaPath: String) -> UIImage? {
        var mediaimage : UIImage = UIImage()
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
        if(fileExist(mediaPath)){
            do {
                try fileManager.removeItemAtPath(mediaPath)
                mediaDeleteFlag = 1
            }
            catch let error as NSError {
                mediaDeleteFlag = 0
            }
        }
        else{
            mediaDeleteFlag = 0
        }
        return mediaDeleteFlag
    }
    
    func yearsFrom(date:NSDate, todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: todate, options: []).year
    }
    func monthsFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: todate, options: []).month
    }
    func weeksFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: todate, options: []).weekOfYear
    }
    func daysFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: todate, options: []).day
    }
    func hoursFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: todate, options: []).hour
    }
    func minutesFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: todate, options: []).minute
    }
    func secondsFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: todate, options: []).second
    }
    func offsetFrom(date:NSDate,todate:NSDate) -> String {
        if yearsFrom(date,todate:todate)   > 0 { return "\(yearsFrom(date,todate:todate))year ago"   }
        if monthsFrom(date,todate:todate)  > 0 { return "\(monthsFrom(date,todate:todate))month ago"  }
        if weeksFrom(date,todate:todate)   > 0 { return "\(weeksFrom(date,todate:todate))week ago"   }
        if daysFrom(date,todate:todate)    > 0 { return "\(daysFrom(date,todate:todate))day ago"    }
        if hoursFrom(date,todate:todate)   > 0 { return "\(hoursFrom(date,todate:todate))hour ago"   }
        if minutesFrom(date,todate:todate) > 0 { return "\(minutesFrom(date,todate:todate))min ago" }
        if secondsFrom(date,todate:todate) > 0 { return "\(secondsFrom(date,todate:todate))sec ago" }
        return ""
    }
    func  getTimeDifference(dateStr:String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        
        let cloudDate = dateFormatter.dateFromString(dateStr)
        
        let localDateStr = dateFormatter.stringFromDate(NSDate())
        let localDate = dateFormatter.dateFromString(localDateStr)
        
        let differenceString =  offsetFrom(cloudDate!, todate: localDate!)
        return differenceString
    }
    
}
