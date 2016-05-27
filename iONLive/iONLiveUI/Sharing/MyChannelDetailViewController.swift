//
//  MyChannelDetailViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelDetailViewController: UITabBarController {
    
    static let identifier = "MyChannelDetailViewController"
    
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    
    var allItemTitleText = ""
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.selectedIndex = 1
        let tabBarItems = self.tabBar.items
        if let items = tabBarItems
        {
                items[1].image = UIImage(named:"friend_avatar")?.imageWithRenderingMode(.AlwaysOriginal)
            items[1].setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.darkGrayColor()], forState: .Normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
}
