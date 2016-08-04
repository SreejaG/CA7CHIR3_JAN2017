//
//  StreamsGalleryViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/2/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class StreamsGalleryViewController: UITabBarController {
    static let identifier = "StreamsGalleryViewController"
    
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var limit: Int = Int()
    var count: Int = Int()
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsGalleryViewController.callNextDownload), name: "stream", object:nil)
         
        if GlobalStreamList.sharedInstance.GlobalStreamDataSource.count == 0
        {
            limit = 20
            count = 0
            GlobalStreamList.sharedInstance.initialiseCloudData(count ,endValueLimit: limit)
        }
        
    }
    func  callNextDownload()
    {
        if (ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count == 0)
        {
            let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
            let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
            //   ChannelSharedListAPI.sharedInstance.getChannelSharedDetails(userId, token: accessToken)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.addTabBarItems()
    }
    func addTabBarItems()
    {
        NSUserDefaults.standardUserDefaults().objectForKey("SelectedTab")
        self.selectedIndex = NSUserDefaults.standardUserDefaults().integerForKey("SelectedTab")
        let tabBarItems = self.tabBar.items
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
