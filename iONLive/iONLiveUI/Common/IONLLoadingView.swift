//
//  IONLLoadingView.swift
//  iONLive
//
//  Created by Gadgeon on 11/20/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation
class IONLLoadingView: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nil)
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func startLoading(){
        activityIndicator.startAnimating()
    }
    
    func stopLoading(){
        activityIndicator.stopAnimating()
    }
}