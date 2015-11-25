//
//  ViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/16/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userNameTextfield: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInBottomConstraint: NSLayoutConstraint!
    //@IBOutlet weak var contentScrollView: UIScrollView!
    //@IBOutlet weak var contentScrollViewToBottomConstraint: NSLayoutConstraint!
    var loadingOverlay: UIView?
    
    let requestManager = RequestManager.sharedInstance
    let authenticationManager = AuthenticationManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "LOG IN"
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
        
        userNameTextfield.attributedPlaceholder = NSAttributedString(string: "Username",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor(),NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password",
            attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor() ,NSFontAttributeName: UIFont.italicSystemFontOfSize(14.0)])
        userNameTextfield.autocorrectionType = UITextAutocorrectionType.No
        passwordTextField.autocorrectionType = UITextAutocorrectionType.No
        addObserver()
    }
    
    func addObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name:UIKeyboardDidShowNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "KeyboardDidHide:", name:UIKeyboardWillHideNotification , object: nil)
    }
    
    //PRAGMA MARK:- keyboard notification handler
    
    func keyboardDidShow(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if logInBottomConstraint.constant == 0
        {
            logInBottomConstraint.constant += keyboardFrame.size.height
        }
    }
    
    func KeyboardDidHide(notification: NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if logInBottomConstraint.constant != 0
        {
            logInBottomConstraint.constant -= keyboardFrame.size.height
        }
    }
    //    func keyboardDidShow(notification:NSNotification) {
    //
    //        var userInfo = notification.userInfo!
    //        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
    //        contentScrollViewToBottomConstraint.constant += keyboardFrame.size.height
    //    }
    //
    //    func KeyboardDidHide(notification:NSNotification) {
    //        contentScrollViewToBottomConstraint.constant = 0
    //    }
    //
    
    
    // PRAGMA MARK:- textField delegates
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    
    func loadUploadStreamingView()
    {
        let streamingStoryboard = UIStoryboard(name:"Streaming" , bundle: nil)
        let uploadStreamViewController = streamingStoryboard.instantiateViewControllerWithIdentifier(UploadStreamViewController.identifier)
        self.navigationController?.pushViewController(uploadStreamViewController, animated: true)
    }
    
    func loadStreamsListView()
    {
        let streamingStoryboard = UIStoryboard(name:"Streaming" , bundle: nil)
        let streamsListViewController = streamingStoryboard.instantiateViewControllerWithIdentifier(StreamsListViewController.identifier)
        self.navigationController?.pushViewController(streamsListViewController, animated: true)
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func forgetPasswordClicked(sender: AnyObject)
    {
        
    }
    
    @IBAction func tapGestureRecognized(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func loginClicked(sender: AnyObject)
    {
        if userNameTextfield.text!.isEmpty
        {
            ErrorManager.sharedInstance.loginNoEmailEnteredError()
        }
        else if passwordTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.loginNoPasswordEnteredError()
        }
        else
        {
            self.loginUser(self.userNameTextfield.text!, password: self.passwordTextField.text!, withLoginButton: true)
        }
    }
    
    
    //PRAGMA MARK:- Helper functions
    
    func isEmail(email:String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive)
        return regex?.firstMatchInString(email, options: [], range: NSMakeRange(0, email.characters.count)) != nil
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    
    //PRAGMA MARK:- API handlers
    func loginUser(email: String, password: String, withLoginButton: Bool)
    {
        //check for valid email
        let isEmailValid = isEmail(email) as Bool!
        if isEmailValid == false
        {
            ErrorManager.sharedInstance.loginInvalidEmail()
            return
        }
        
        //authenticate through authenticationManager
        showOverlay()
        authenticationManager.authenticate(email: email, password: password, success: { (response) -> () in
           self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, message: message)
                return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        self.passwordTextField.text = ""
        self.removeOverlay()
        loadLiveStreamView()
//        self.loadUploadStreamingView()
        //self.loadStreamsListView()
        if let json = response as? [String: AnyObject]
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            print("success = \(json["status"]),\(json["token"]),\(json["user"])")
            if let tocken = json["token"]
            {
                defaults.setValue(tocken, forKey: userAccessTockenKey)
            }
            if let userId = json["user"]
            {
                defaults.setValue(userId, forKey: userLoginIdKey)
            }
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }

    }
    
    func authenticationFailureHandler(error: NSError?, message: String)
    {
        self.removeOverlay()
        print("message = \(message)")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false {
            ErrorManager.sharedInstance.alert("Login Error", message:message)
        }
        else{
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://184.72.239.149/vod/mp4:BigBuckBunny_115k.mov"/*"rtsp://192.168.42.1:554/live"*/, parameters: nil , liveVideo: true) as! UIViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

