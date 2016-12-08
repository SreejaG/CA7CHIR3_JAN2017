
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
        let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/GCSCA7CH"
        do {
            try FileManager.default.createDirectory(atPath: documentsPath, withIntermediateDirectories: true, attributes: nil)
            flag = true
        } catch _ as NSError {
            flag = false
        }
        return flag
    }
    
    func getParentDirectoryPath() -> NSURL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/GCSCA7CH"
        return  NSURL(string: documentsPath)!
    }
    
    func fileExist(mediaPath: String) -> Bool
    {
        let flag : Bool
        var fileManager = FileManager.default
        if(fileManager.fileExists(atPath: mediaPath))
        {
            flag = true
        }
        else{
            flag = false
        }
        fileManager = FileManager()
        return flag
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func  saveImageToFilePath(mediaName: String, mediaImage: UIImage) -> Bool {
        let parentPath = getParentDirectoryPath().absoluteString
        let savingPath = parentPath! + "/" + mediaName
        let mediaSaveFlag : Bool
        if(mediaImage != UIImage())
        {
            if let image = UIImageJPEGRepresentation(mediaImage, 0.5)
            {
                do {
                    try image.write(to: URL(fileURLWithPath: savingPath), options: .atomic)
                    mediaSaveFlag = true
                } catch _ {
                    mediaSaveFlag = false
                }
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
        if(fileExist(mediaPath: mediaPath)){
            mediaimage = UIImage(contentsOfFile: mediaPath)!
        }
        else{
            mediaimage = UIImage()
        }
        return mediaimage
    }
    
    func deleteImageFromFilePath(mediaPath: String) -> Int {
        let mediaDeleteFlag : Int
        let fileManager = FileManager.default
        if(fileExist(mediaPath: mediaPath)){
            do {
                try fileManager.removeItem(atPath: mediaPath)
                mediaDeleteFlag = 1
            }
            catch _ as NSError {
                mediaDeleteFlag = 0
            }
        }
        else{
            mediaDeleteFlag = 0
        }
        return mediaDeleteFlag
    }
    
    func getLiveResolutionShortString(resolution: String) -> String
    {
        var retResolution = String()
        if(resolution == "352x240 (240p)"){
            retResolution = "240p"
        }
        else if(resolution == "480x360 (360p)"){
            retResolution = "360p"
        }
        else if(resolution == "850x480 (480p)"){
            retResolution = "480p"
        }
        else if(resolution == "1280x720 (720p)"){
            retResolution = "720p"
        }
        else if(resolution == "1920x1080 (1080p)"){
            retResolution = "1080p"
        }
        return retResolution
    }
    
    func getLiveResolutionLongString(resolution: String) -> String
    {
        var retResolution = String()
        if(resolution == "240p"){
            retResolution = "352x240 (240p)"
        }
        else if(resolution == "360p"){
            retResolution = "480x360 (360p)"
        }
        else if(resolution == "480p"){
            retResolution = "850x480 (480p)"
        }
        else if(resolution == "720p"){
            retResolution = "1280x720 (720p)"
        }
        else if(resolution == "1080p"){
            retResolution = "1920x1080 (1080p)"
        }
        return retResolution
    }
    
    func getArchiveDeleteShortString(resolution: String) -> String
    {
        var retResolution = String()
        if(resolution == "After 7 Days"){
            retResolution = "7 Days"
        }
        else if(resolution == "After 30 Days"){
            retResolution = "30 Days"
        }
        else if(resolution == "Never"){
            retResolution = "Never"
        }
        return retResolution
    }
    
    func getArchiveDeleteLongString(resolution: String) -> String
    {
        var retResolution = String()
        if(resolution == "7 Days"){
            retResolution = "After 7 Days"
        }
        else if(resolution == "30 Days"){
            retResolution = "After 30 Days"
        }
        else if(resolution == "Never"){
            retResolution = "Never"
        }
        return retResolution
    }
    
    func years(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year ?? 0
    }
    
    func months(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month ?? 0
    }
    
    func weeks(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: fromDate, to: fromDate).weekOfYear ?? 0
    }
    
    func days(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day ?? 0
    }
    
    func hours(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour ?? 0
    }
    
    func minutes(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute ?? 0
    }
    
    func seconds(fromDate: Date, toDate: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: fromDate, to: toDate).second ?? 0
    }
    
    func offset(fromDate: Date, toDate: Date ) -> String {
        if years(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(years(fromDate: fromDate, toDate: toDate))year ago"
        }
        if months(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(months(fromDate: fromDate, toDate: toDate))month ago"
        }
        if weeks(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(weeks(fromDate: fromDate, toDate: toDate))week ago"
        }
        if days(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(days(fromDate: fromDate, toDate: toDate))day ago"
        }
        if hours(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(hours(fromDate: fromDate, toDate: toDate))hour ago"
        }
        if minutes(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(minutes(fromDate: fromDate, toDate: toDate))min ago"
        }
        if seconds(fromDate: fromDate, toDate: toDate) > 0
        {
            return "\(seconds(fromDate: fromDate, toDate: toDate))sec ago"
        }
        return ""
    }
    
    func  getTimeDifference(dateStr:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
        let cloudDate = dateFormatter.date(from: dateStr)
        let localDateStr = dateFormatter.string(from: NSDate() as Date)
        let localDate = dateFormatter.date(from: localDateStr)
        let differenceString = offset(fromDate: cloudDate!, toDate: localDate!)
        return differenceString
    }
    
    func getVideoDurationInProperFormat(duration: String) -> String {
        let durationSplitArr = duration.characters.split{$0 == ":"}.map(String.init)
        var hourDuration = String()
        var minuteDuration = String()
        if(durationSplitArr[0] == "00")
        {
            hourDuration = durationSplitArr[1] + ":" + durationSplitArr[2]
            var hourDurationSplitArr = hourDuration.characters.split{$0 == ":"}.map(String.init)
            if(hourDurationSplitArr[0] == "00")
            {
                minuteDuration = "0"
            }
            else if(hourDurationSplitArr[0].hasPrefix("0")) {
                minuteDuration = String(hourDurationSplitArr[0].characters.dropFirst())
            }
            else{
                minuteDuration = hourDurationSplitArr[0]
            }
            hourDuration = minuteDuration + ":" + durationSplitArr[2]
        }
        else if(durationSplitArr[0].hasPrefix("0"))
        {
            minuteDuration = String(durationSplitArr[0].characters.dropFirst())
            hourDuration = minuteDuration + ":" + durationSplitArr[1] + ":" + durationSplitArr[2]
        }
        else{
            hourDuration = duration
        }
        return hourDuration
    }
    
    func getProfileImage(profileNameURL: String) -> UIImage
    {
        var profileImage : UIImage = UIImage()
        do {
            let url: NSURL = convertStringtoURL(url: profileNameURL)
            let data = try NSData(contentsOf: url as URL,options: NSData.ReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData as Data)
                {
                    profileImage = mediaImage1
                }
                else{
                    profileImage = UIImage(named: "dummyUser")!
                }
            }
            else
            {
                profileImage = UIImage(named: "dummyUser")!
            }
            
        } catch {
            profileImage = UIImage(named: "dummyUser")!
        }
        return profileImage
    }
}
