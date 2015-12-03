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

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.selectedIndex = 1
        let tabBarItems = self.tabBar.items
        if let items = tabBarItems
         {
            items[0].image = UIImage(named:"channels")?.imageWithRenderingMode(.AlwaysOriginal)
            items[0].setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.darkGrayColor()], forState: .Normal)
         }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
