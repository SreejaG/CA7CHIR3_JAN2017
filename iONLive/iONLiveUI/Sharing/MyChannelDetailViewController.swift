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
        let index =  NSUserDefaults.standardUserDefaults().valueForKey("tabToAppear")
        print(index)
        self.selectedIndex = index as! Int
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
//        let index =  NSUserDefaults.standardUserDefaults().valueForKey("tabToAppear")
//        print(index)
//        self.selectedIndex = index as! Int
 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
    }
}
