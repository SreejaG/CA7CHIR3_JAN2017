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

    ////PRAGMA MARK:-OutLets
    @IBOutlet var resultsView: UIView!
    @IBOutlet var numberOfSegementsLabel: UILabel!
    @IBOutlet var videoID: UILabel!
    var tField: UITextField!

    //PRAGMA MARK:- load View
    override func viewDidLoad() {
        super.viewDidLoad()

        initialiseView()
    }

    //PRAGMA MARK:- Initializers
    func initialiseView()
    {
        resultsView.hidden = true
    }
    
    //PRAGMA MARK :- API calls
    func stopIONLiveCamVideo()
    {
        iONLiveCameraVideoCaptureManager.stopIONLiveCameraVideo({ (response) -> () in

            self.iONLiveCamGetVideoSuccessHandler(response)
            print("success")

            }) { (error, code) -> () in

                print("failure")
        }
    }

    func updateSegements(numSegements:Int)
    {
        iONLiveCameraVideoCaptureManager.updateVideoSegements(numSegments:numSegements, success: { (response) -> () in

            ErrorManager.sharedInstance.alert("Updated Video Segements", message: "Successfully Updated Video Segements")
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

    func startVideo()
    {
        iONLiveCameraVideoCaptureManager.getiONLiveCameraVideoID({ (response) -> () in

            self.iONLiveCamGetVideoSuccessHandler(response)

            print("success")
            }) { (error, code) -> () in

                print("failure")
        }
    }

    //PRAGMA MARK:- API Handlers
    func iONLiveCamStopVideoSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            ErrorManager.sharedInstance.alert(" Video Stopped", message: "Successfully  Stopped Video")
            print("Show Alert")
        }
    }

    func iONLiveCamGetVideoSuccessHandler(response:AnyObject?)
    {
        resultsView.hidden = false
        print("entered capture video")
        if let json = response as? [String: AnyObject]
        {
            print("success")
            if let videoId = json["hlsID"]
            {
                self.videoAPIResult["videoID"] = videoId as? String
                videoID.text =  "videoID = " + videoAPIResult["videoID"]!
            }
            if let numSegments = json["numSegments"]
            {
                let id:String = numSegments as! String
                self.videoAPIResult["numSegments"] = id
                numberOfSegementsLabel.text = "No: of Segements = " + videoAPIResult["numSegments"]!
            }
            if let type = json["Type"]
            {
                let id:String = type as! String
                self.videoAPIResult["type"] = id
            }
        }
    }

    func downLoadm3u8Video()
    {
        iONLiveCameraVideoCaptureManager.downloadm3u8Video(hlsID: videoAPIResult["videoID"]!, success: { (response) -> () in

            ErrorManager.sharedInstance.alert("downloaded m3u8 Video", message: "Successfully downloaded Video ")

            }) { (error, code) -> () in

            ErrorManager.sharedInstance.alert("Download Video", message: "Failure to download Video ")
        }
    }

    func configurationTextField(textField: UITextField!)
    {
        print("generating the TextField")
        textField.placeholder = "Enter number of Segements"
        textField.keyboardType = UIKeyboardType.NumberPad
        tField = textField
    }

    func handleCancel(alertView: UIAlertAction!)
    {
        print("Cancelled !!")
    }

    func showAlert()
    {
        let alert = UIAlertController(title: "Enter number of Segements", message: "", preferredStyle: UIAlertControllerStyle.Alert)

        alert.addTextFieldWithConfigurationHandler(configurationTextField)
        alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler:{ (UIAlertAction)in
            if let numSeg = Int(self.tField.text!)
            {
                self.updateSegements(numSeg)
            }
            print("Done !!")
            print("Item : \(self.tField.text)")
        }))
        self.presentViewController(alert, animated: true, completion: {
            print("completion block")
        })

    }

    //PRAGMA MARK :- Actions
    @IBAction func didTapStartVideo(sender: AnyObject) {

        startVideo()
    }

    @IBAction func didTapDeleteVideo(sender: AnyObject) {

        deleteVideo()
    }

    @IBAction func didTapStopVideo(sender: AnyObject) {

        stopIONLiveCamVideo()
    }

    @IBAction func didTapUpdateVideoAPI(sender: AnyObject) {

        showAlert()
    }

    @IBAction func didTapDownloadVideo(sender: AnyObject) {
        downLoadm3u8Video()
    }

    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}


