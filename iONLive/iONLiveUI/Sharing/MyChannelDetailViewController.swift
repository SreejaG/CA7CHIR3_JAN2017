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
 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
    }
}
