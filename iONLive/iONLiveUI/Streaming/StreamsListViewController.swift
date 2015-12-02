//
//  StreamsListViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class StreamsListViewController: UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    static let identifier = "StreamsListViewController"
    
    var loadingOverlay: UIView?
    
    @IBOutlet weak var liveStreamListTableView: UITableView!
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    
    var dataSource:[[String:String]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "STREAMS"
        getAllLiveStreams()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        showNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        
//        if let viewControllers = self.navigationController?.viewControllers as [UIViewController]! {
//            
//            if viewControllers.contains(self) == false{
//                
//                let vc:MovieViewController = self.navigationController?.topViewController as! MovieViewController
//                
//                vc.initialiseDecoder()
//            }
//        }
    }
    
    func showNavigationBar()
    {
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.translucent = false
        
    }
    //PRAGMA MARK-: TableView dataSource and Delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell : UITableViewCell?
        cell = tableView.dequeueReusableCellWithIdentifier("CELL")
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "CELL")
        }
        cell?.accessoryType = .DisclosureIndicator
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                var streamDict = dataSource[indexPath.row]
                if let streamDesc = streamDict["streamDescription"]
                {
                    cell!.textLabel!.text = streamDesc
                }
                
            }
        }
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var tocken:String?
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                var streamDict = dataSource[indexPath.row]
                if let streamTocken = streamDict["streamToken"]
                {
                    tocken = streamTocken
                }
            }
        }
        
        if let streamtocken = tocken
        {
            self.loadLiveStreamView(streamtocken)
        }
        else
        {
            ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
        }
        
    }
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtmp://104.197.159.157:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        
        self.presentViewController(vc, animated: true) { () -> Void in
            
        }
//        print("rtmp://192.168.16.64:1935/live/\(streamTocken)")
    }
    
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            showOverlay()
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
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            print("success = \(json["liveStreams"])")
            self.dataSource = json["liveStreams"] as? [[String:String]]
            if dataSource?.count == 0
            {
                ErrorManager.sharedInstance.alert("No Streams", message: "Sorry! you don't have any live streams")
            }
            self.liveStreamListTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func getAllStreamFailureHandler(error: NSError?, message: String)
    {
        self.removeOverlay()
        print("message = \(message)")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false {
            ErrorManager.sharedInstance.alert("Live Streams Fetching Error", message:message)
        }
        else{
            ErrorManager.sharedInstance.liveStreamFetchingError()
        }
    }
    
    
    //Loading Overlay Methods
    func showOverlay()
    {
        if self.loadingOverlay != nil{
            self.loadingOverlay?.removeFromSuperview()
            self.loadingOverlay = nil
        }
        
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
}
