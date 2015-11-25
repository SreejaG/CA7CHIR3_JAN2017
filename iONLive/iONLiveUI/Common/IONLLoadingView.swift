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
    //MARK: ViewLifeCycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //        initLoader()
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
    
    //    func initLoader() {
    //        var screenWidth = UIScreen.mainScreen().bounds.width
    //        var screenHeight = UIScreen.mainScreen().bounds.height
    //
    //        var preloaderContainer = UIView(frame: CGRectMake(0, 0,screenWidth,screenHeight))
    //        preloaderContainer.center = CGPointMake(screenWidth/2, screenHeight/2)
    //        preloaderContainer.backgroundColor = UIColor.lightGrayColor()
    //        preloaderContainer.alpha = 0.5
    //
    //        let indicator:UIActivityIndicatorView = UIActivityIndicatorView (activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
    //        indicator.frame = CGRectMake(0.0, 0.0, 10.0, 10.0)
    //        indicator.center = preloaderContainer.center
    //        preloaderContainer.addSubview(indicator)
    //        self.view.addSubview(preloaderContainer)
    //
    //        indicator.bringSubviewToFront(preloaderContainer)
    //        indicator.startAnimating()
    //    }
}