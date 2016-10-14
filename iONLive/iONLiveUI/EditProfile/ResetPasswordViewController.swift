//
//  ResetPasswordViewController.swift
//  iONLive
//
//  Created by sreejesh on 10/12/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ResetPasswordViewController: UIViewController {
    static let identifier = "ResetPasswordViewController"
   var loadingOverlay: UIView?
    @IBOutlet weak var reEnterPasswordTextField: UITextField!
    @IBOutlet weak var resetPasswordTextfield: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ResetPasswordViewController.dismissKeyboard))
               view.addGestureRecognizer(tap)

        // Do any additional setup after loading the view.
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        resetPasswordTextfield.text = ""
        reEnterPasswordTextField.text = ""
        self.dismissViewControllerAnimated(false, completion: nil)
    }

    @IBAction func resetPasswordClicked(sender: AnyObject) {
        let text = resetPasswordTextfield.text!
        let reEnteredtext = reEnterPasswordTextField.text!

        
        if resetPasswordTextfield.text!.isEmpty
        {
            ErrorManager.sharedInstance.newPaswrdEmpty()
        }
        else if reEnterPasswordTextField.text!.isEmpty
        {
            ErrorManager.sharedInstance.confirmPaswrdEmpty()
        }
        else if(text != reEnteredtext){
            ErrorManager.sharedInstance.passwordMismatch()
            resetPasswordTextfield.text = ""
            reEnterPasswordTextField.text = ""

        }
        else
        {
            let chrSet = NSCharacterSet.decimalDigitCharacterSet()
            if((text.characters.count < 8) || (text.characters.count > 40))
            {
                ErrorManager.sharedInstance.InvalidPwdEnteredError()
                resetPasswordTextfield.text = ""
                reEnterPasswordTextField.text = ""
                resetPasswordTextfield.becomeFirstResponder()
                return
            }
            else if text.rangeOfCharacterFromSet(chrSet) == nil {
                ErrorManager.sharedInstance.noNumberInPassword()
                resetPasswordTextfield.text = ""
                reEnterPasswordTextField.text = ""
                resetPasswordTextfield.becomeFirstResponder()
                return
            }
            else{
                let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
                let  accessToken =  NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
                
                print(resetPasswordTextfield.text!)
                self.showOverlay()
                ProfileManager.sharedInstance.resetPassword(userId, accessToken: accessToken, resetPassword: resetPasswordTextfield.text!, success: { (response) in
                    print("success")
                    self.SuccessHandler(response!)
                }) { (error, code) in
                    print("failed")
                    self.removeOverlay()
                    ErrorManager.sharedInstance.failedToUpdatepassword()
                    
                    
                }
            }
        }
    }
    func SuccessHandler(response : AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let status = json["status"] as! Int
            if(status == 1){
                let alert = UIAlertController(title: "Success", message: "Password updated successfully", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    self.dismissViewControllerAnimated(false, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        else
        {
            ErrorManager.sharedInstance.failedToUpdatepassword()
        }

    }
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
