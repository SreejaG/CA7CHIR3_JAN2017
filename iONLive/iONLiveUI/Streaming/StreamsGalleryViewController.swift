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
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.addTabBarItems()
    }
    
    func addTabBarItems()
    {
        self.selectedIndex = 1
        let tabBarItems = self.tabBar.items
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
