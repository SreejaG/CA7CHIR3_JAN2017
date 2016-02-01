//
//  iONCamPictureAPIViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit



class iONCamPictureAPIViewController: UIViewController {

    static let identifier = "iONCamPictureAPIViewController"
    
    @IBOutlet weak var cameraCapturedImageView: UIImageView!
     var loadingOverlay: UIView?
    
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    let requestManager = RequestManager.sharedInstance
    let iOnLiveCameraPictureCaptureManager = iOnLiveCameraPictureCapture.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageLoadingIndicator.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func deleteButtonClicked(sender: AnyObject)
    {
        self.deleteiONLiveCamImage(true, burstId: nil)
    }
    @IBAction func getButtonClicked(sender: AnyObject)
    {
        self.captureiONLiveCamImage(nil, burstCount:nil, burstInterval:nil, quality:nil)
    }
    
    /////////For testing iOnLiveCamPictureCapture API
    func captureiONLiveCamImage(scale: String?, burstCount: String?,burstInterval:String?,quality:String?)
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.getiONLiveCameraPictureId(scale, burstCount: burstCount, burstInterval: burstInterval, quality: quality, success: { (response) -> () in
            ErrorManager.sharedInstance.alert("Success BurstId found", message:"\(response as? [String: AnyObject])")
            self.iONLiveCamGetPictureSuccessHandler(response)
            
            }) { (error, message) -> () in
                self.iONLiveCamGetPictureFailureHandler(error, code: message)
                return
        }
    }
    
    
    func iONLiveCamGetPictureSuccessHandler(response:AnyObject?)
    {
        print("entered download pic")
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            if let burstId = json["burstID"]
            {
                let id:String = burstId as! String
                // push result VC and load image
                let apiStoryBoard = UIStoryboard(name:"iONCamPictureAPITest", bundle: nil)
                let resultVC = apiStoryBoard.instantiateViewControllerWithIdentifier(iONCamPictureAPIResultViewController.identifier) as! iONCamPictureAPIResultViewController
                resultVC.imageBurstId = id
                self.navigationController?.pushViewController(resultVC, animated: true)
                
            }
            
                
                
//                cameraCapturedImageView.image = nil
//                //cameraCapturedImageView.setImageWithURL( NSURL(string: UrlManager.sharedInstance.getiONLiveCamImageDownloadUrl(id))!)
//                imageLoadingIndicator.hidden = false
//                cameraCapturedImageView.setImageWithURLRequest(NSURLRequest(URL: NSURL(string: UrlManager.sharedInstance.getiONLiveCamImageDownloadUrl(id))!), placeholderImage: nil, success: { (request, response, image) -> Void in
//                    self.cameraCapturedImageView.image = image
//                    print("success")
//                    self.imageLoadingIndicator.hidden = true
//                    }, failure: { (request, resonse, error) -> Void in
//                        print(error)
//                        ErrorManager.sharedInstance.alert("Image Download Error", message:"\(error.localizedDescription)")
//                        self.imageLoadingIndicator.hidden = true
//                })
//            }
//
//            print("success = \(json["burstID"]))")
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func iONLiveCamGetPictureFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.loginError()
        }
    }
    ////////////////////////////////////////////////
    
    /////////For testing iOnLiveCamPictureDelete API
    func deleteiONLiveCamImage(cancelBurst: Bool, burstId: String?)
    {
        showOverlay()
        iOnLiveCameraPictureCaptureManager.deleteiONLiveCameraPicture(cancelBurst, burstID: burstId, success: { (response) -> () in
            self.iONLiveCamDeletePictureSuccessHandler(response)
            }) { (error, message) -> () in
                self.iONLiveCamDeletePictureFailureHandler(error, code: message)
                return
        }
    }
    
    
    func iONLiveCamDeletePictureSuccessHandler(response:AnyObject?)
    {
        self.removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            print("success = \(json["burstID"]))")
        }
        else
        {
            ErrorManager.sharedInstance.loginError()
        }
    }
    
    func iONLiveCamDeletePictureFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.loginError()
        }
    }
    ////////////////////////////////////////////////
    
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


}
