//
//  iONLiveCamVideoViewController.swift
//  iONLive
//
//  Created by Vinitha on 2/1/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCamVideoViewController: UIViewController {
    
    static let identifier = "iONLiveCamVideoViewController"

    var videoAPIResult =  [String : String]()
    let iONLiveCameraVideoCaptureManager = iONLiveCameraVideoCapture.sharedInstance

    @IBOutlet var numberOfSegementsLabel: UILabel!
    @IBOutlet var videoID: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoID.text =  "videoID = " + videoAPIResult["videoID"]!
        numberOfSegementsLabel.text = "No: of Segements = " + videoAPIResult["numSegments"]!
    }
    
    //PRAGMA MARK :-
    func stopIONLiveCamVideo()
    {
        iONLiveCameraVideoCaptureManager.stopIONLiveCameraVideo({ (response) -> () in
            
            self.iONLiveCamGetVideoSuccessHandler(response)
            print("success")
            
            }) { (error, code) -> () in
                
            print("failure")
        }
    }
    
    func updateSegements()
    {
        iONLiveCameraVideoCaptureManager.updateVideoSegements(numSegments: 2, success: { (response) -> () in
            
            ErrorManager.sharedInstance.alert("Updated Video Segements", message: "Successfully Updated Video Segements to 2")
            print("Success")
            
            }) { (error, code) -> () in
                
                ErrorManager.sharedInstance.alert("Updated Video Segements", message: "Fauilure to Update Video Segements...")
                print("failure")
        }
    }
    func deleteVideo()
    {
        iONLiveCameraVideoCaptureManager.deleteVideo(hlsID: videoAPIResult["videoID"]!, success: { (response) -> () in
            
            ErrorManager.sharedInstance.alert("Delete Video", message: "Successfully Deleted Video ")
            }) { (error, code) -> () in
                
                ErrorManager.sharedInstance.alert("Delete Video", message: "failure to Delete Video")

        }
    }
    
    func iONLiveCamGetVideoSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            ErrorManager.sharedInstance.alert(" Video Stopped", message: "Successfully  Stopped Video")
            print("Show Alert")
        }
    }

    @IBAction func didTapDeleteVideo(sender: AnyObject) {
        
        deleteVideo()
    }
    
    @IBAction func didTapStopVideo(sender: AnyObject) {
        
        stopIONLiveCamVideo()

    }
    
    @IBAction func didTapUpdateVideoAPI(sender: AnyObject) {
        
        updateSegements()
    }
    
    @IBAction func didTapDownloadVideo(sender: AnyObject) {

    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}


