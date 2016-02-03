//
//  iONLiveCameraConfigurationViewController.swift
//  iONLive
//
//  Created by Vinitha on 2/3/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCameraConfigurationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}
