//
//  StreamsGalleryViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/2/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class StreamsGalleryViewController: UITabBarController {

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
        if let items = tabBarItems
        {
            print(items)
//            items[0].image = UIImage(named:"channels")?.imageWithRenderingMode(.AlwaysOriginal)
//            items[0].setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.darkGrayColor()], forState: .Normal)
        }
    }
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        //This method will be called when user changes tab.
        
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
