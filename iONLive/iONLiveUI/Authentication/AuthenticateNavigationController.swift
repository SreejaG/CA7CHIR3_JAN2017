//
//  AuthenticateNavigationController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/16/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class AuthenticateNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        customise()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func customise()
    {
         if #available(iOS 8.2, *) {
             UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(18, weight: UIFontWeightRegular),NSForegroundColorAttributeName: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)]
         }
         else
         {
             UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue-Regular", size: 18)!,NSForegroundColorAttributeName: UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)]
         }
        
       UINavigationBar.appearance().tintColor = UIColor(red: 44.0/255, green: 214.0/255, blue: 229.0/255, alpha: 1.0)
        UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = UIImage()
    }
}
