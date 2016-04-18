//
//  StreamsListViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class StreamsListViewController: UIViewController{
    
    let streamTockenKey = "wowza_stream_token" //"streamToken"
    let imageKey = "image"
    let typeKey = "type"
    let imageType = "imageType"
    static let identifier = "StreamsListViewController"
    
    
    //var loadingOverlay: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var dataSource:[[String:String]]?
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    
    //for temp image along with streams and stream thumbanes
    var dummyImagesArray:[String] = ["thumb1","thumb2","thumb3","thumb4","thumb5","thumb6" , "thumb7","thumb8","thumb9","thumb10","thumb11","thumb12"]
    var dummyImageListingDataSource = [[String:String]]()
    
    @IBOutlet weak var streamListCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.streamListCollectionView.addSubview(refreshControl)
        self.streamListCollectionView.alwaysBounceVertical = true
        self.view.bringSubviewToFront(activityIndicator)
        
        dummyImageListingDataSource = [[imageKey:dummyImagesArray[0],typeKey:imageType],[imageKey:dummyImagesArray[1],typeKey:imageType],[imageKey:dummyImagesArray[2],typeKey:imageType],[imageKey:dummyImagesArray[3],typeKey:imageType],[imageKey:dummyImagesArray[4],typeKey:imageType],[imageKey:dummyImagesArray[5],typeKey:imageType],[imageKey:dummyImagesArray[6],typeKey:imageType],[imageKey:dummyImagesArray[7],typeKey:imageType],[imageKey:dummyImagesArray[8],typeKey:imageType],[imageKey:dummyImagesArray[9],typeKey:imageType],[imageKey:dummyImagesArray[10],typeKey:imageType],[imageKey:dummyImagesArray[11],typeKey:imageType]]
        self.dataSource = dummyImageListingDataSource
        getAllLiveStreams()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        activityIndicator.hidden = true
        self.view.bringSubviewToFront(activityIndicator)
        
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    override func viewWillDisappear(animated: Bool) {
    //
    //        if let viewControllers = self.navigationController?.viewControllers as [UIViewController]! {
    //
    //            if viewControllers.contains(self) == false{
    //
    //                let vc:MovieViewController = self.navigationController?.topViewController as! MovieViewController
    //
    //                vc.initialiseDecoder()
    //            }
    //        }
    //    }
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.196.15.240:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        
        self.presentViewController(vc, animated: true) { () -> Void in
            
        }
    }
    
    func pullToRefresh()
    {
        pullToRefreshActive = true
        getAllLiveStreams()
    }
    
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            if pullToRefreshActive == false
            {
                activityIndicator.hidden = false
            }
            else
            {
                activityIndicator.hidden = true
            }
            
            livestreamingManager.getAllLiveStreams(loginId:loginId as! String , accesstocken:accessTocken as! String ,success: { (response) -> () in
                self.getAllStreamSuccessHandler(response)
                }, failure: { (error, message) -> () in
                    self.getAllStreamFailureHandler(error, message: message)
                    return
            })
        }
        else
        {
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    
    func getAllStreamSuccessHandler(response:AnyObject?)
    {
        activityIndicator.hidden = true
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        if let json = response as? [String: AnyObject]
        {
            print("success = \(json["liveStreams"])")
            let liveStreamDataSource = json["liveStreams"] as? [[String:String]]
            self.createDataSource(liveStreamDataSource)
            self.streamListCollectionView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func getAllStreamFailureHandler(error: NSError?, message: String)
    {
        activityIndicator.hidden = true
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
       // self.streamListCollectionView.reloadData()
        print("message = \(message)")
        
        if !self.requestManager.validConnection() {
            //clearing all live streams
            loadStaticImagesOnly()
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false
        {
            if message == "WOWZA001"  // live stream list empty
            {
                loadStaticImagesOnly()
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
            }
        }
        else{
            ErrorManager.sharedInstance.liveStreamFetchingError()
        }
    }
    
    func loadStaticImagesOnly()
    {
         self.dataSource = dummyImageListingDataSource
         self.streamListCollectionView.reloadData()
    }
    
    @IBAction func customBackButtonClicked(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    //PRAGMA MARK:- dummy image helper functions
    
    func createDataSource(liveStreamDataSource:[[String:String]]?)
    {
        self.dataSource = dummyImageListingDataSource
        if let liveStreams = liveStreamDataSource
        {
            var count = 0
            for eachLiveStream in liveStreams
            {
                if dataSource?.count > count
                {
                    dataSource?[count] = eachLiveStream
                    count = count + 1
                }
            }
        }
    }
}

    
extension StreamsListViewController:UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("StreamListCollectionViewCell", forIndexPath: indexPath) as! StreamListCollectionViewCell
        
        //cell for live streams
     
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                //image stream cell
                var dict = dataSource[indexPath.row]
                if let streamType = dict[typeKey]
                {
                    if streamType == imageType
                    {
                        cell.liveStatusLabel.hidden = true
                        cell.liveNowIcon.hidden = true
                        if let imageName = dict[imageKey]
                        {
                            cell.streamThumbnaleImageView.image = UIImage(named: imageName)
                        }
                    }
                }
                else   //live stream cell
                {
                    cell.liveStatusLabel.hidden = false
                    cell.liveNowIcon.hidden = false
                    
                    var imageIndexPath = 0
                    if dummyImagesArray.count > indexPath.row
                    {
                        imageIndexPath = indexPath.row
                    }
                    cell.streamThumbnaleImageView.image = UIImage(named: dummyImagesArray[imageIndexPath])
                }
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                var dict = dataSource[indexPath.row]
                if let _ = dict[typeKey]
                {
                    //not clickable as of now
                }
                else
                {
                    //live stream click
                    if let streamTocken = dict[streamTockenKey]
                    {
                        self.loadLiveStreamView(streamTocken)
                    }
                    else
                    {
                        ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
                    }
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 1, 0, 1)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
         return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-2, 100)
    }
}

