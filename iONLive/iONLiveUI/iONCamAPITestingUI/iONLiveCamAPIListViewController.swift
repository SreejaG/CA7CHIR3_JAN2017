//
//  iONLiveCamAPIListViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCamAPIListViewController: UIViewController {
    
    @IBOutlet weak var testingAPIListTableView: UITableView!
    static let identifier = "iONLiveCamAPIListViewController"
    
    let requestManager = RequestManager.sharedInstance
    let iONLiveCameraVideoCaptureManager = iONLiveCameraVideoCapture.sharedInstance

    var wifiButtonSelected = true
    var dataSource:[String]?
    var wifiAPIList = ["Image capture","Video capture","Camera configuration","Live streaming configuration","Cloud connectivity configuration","Camera status","System information and modification","Download Image file","Download HLS playlist","Download video file","Download HLS segment"]
    var bleAPIList = [""]
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        if wifiButtonSelected
        {
            dataSource = wifiAPIList
        }
        else
        {
            dataSource = bleAPIList
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //PRAGMA MARK:- IBActions
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    @IBAction func wifiButtonClicked(sender: AnyObject)
    {
        wifiButtonSelected = true
        dataSource = wifiAPIList
        testingAPIListTableView.reloadData()
    }
    
    @IBAction func bleButtonClicked(sender: AnyObject)
    {
        wifiButtonSelected = false
        dataSource = bleAPIList
        testingAPIListTableView.reloadData()
    }
}

extension iONLiveCamAPIListViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataSource != nil ? (dataSource!.count) :0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                let cell = UITableViewCell(style:.Default, reuseIdentifier:"Cell")
                cell.textLabel?.text = dataSource[indexPath.row]
                cell.selectionStyle = .None
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        switch indexPath.row
        {
        case 0:
            loadPictureAPIViewController()
            break;
        case 1:
            loadIONLiveCamVideo()
            break;
        case 2:
            loadCameraConfiguration()
        case 5:
            loadCameraStatus()
        default:
            break;
        }
    }
}

//PRAGMA MARK:- load test API views
extension iONLiveCamAPIListViewController{
    
    func loadPictureAPIViewController()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let pictureApiVC = apiTestStoryboard.instantiateViewControllerWithIdentifier(iONCamPictureAPIViewController.identifier) as! iONCamPictureAPIViewController
        self.navigationController?.pushViewController(pictureApiVC, animated: true)
    }
    
    func getVideoAPIViewController() -> iONLiveCamVideoViewController
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let videoApiVC = apiTestStoryboard.instantiateViewControllerWithIdentifier(iONLiveCamVideoViewController.identifier) as! iONLiveCamVideoViewController
        return videoApiVC
    }
    
//    func loadVideoViewController(vc:iONLiveCamVideoViewController)
//    {
//        self.navigationController?.pushViewController(vc, animated: true)
//    }

    func loadCameraStatus()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewControllerWithIdentifier(iONLiveCameraStatusViewController.identifier) as! iONLiveCameraStatusViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
    }

    func loadCameraConfiguration()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewControllerWithIdentifier(iONLiveCameraConfigurationViewController.identifier) as! iONLiveCameraConfigurationViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
    }
    //PRAGMA MARK:- Test API call

    func loadIONLiveCamVideo()
    {
        let apiTestStoryboard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
        let statusVC = apiTestStoryboard.instantiateViewControllerWithIdentifier(iONLiveCamVideoViewController.identifier) as! iONLiveCamVideoViewController
        self.navigationController?.pushViewController(statusVC, animated: true)
//        iONLiveCameraVideoCaptureManager.getiONLiveCameraVideoID({ (response) -> () in
//            
//            self.iONLiveCamGetVideoSuccessHandler(response)
//            print("success")
//            }) { (error, code) -> () in
//                
//                print("failure")
//        }
    }
    
//    func iONLiveCamGetVideoSuccessHandler(response:AnyObject?)
//    {
//        let iONLiveCamVideoVC = self.getVideoAPIViewController()
//        
//        print("entered capture video")
//        if let json = response as? [String: AnyObject]
//        {
//            print("success")
//            if let videoId = json["hlsID"]
//            {
//                iONLiveCamVideoVC.videoAPIResult["videoID"] = videoId as? String
//            }
//            if let numSegments = json["numSegments"]
//            {
//                let id:String = numSegments as! String
//                iONLiveCamVideoVC.videoAPIResult["numSegments"] = id
//            }
//            if let type = json["Type"]
//            {
//                let id:String = type as! String
//                iONLiveCamVideoVC.videoAPIResult["type"] = id
//            }
//        }
//        self.loadVideoViewController(iONLiveCamVideoVC)
//    }

}


