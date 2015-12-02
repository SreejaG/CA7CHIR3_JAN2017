//
//  SnapCamSelectViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/1/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SnapCamSelectViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    static let identifier = "SnapCamSelectViewController"
    @IBOutlet weak var snapCamSettingsTableView: UITableView!
    var streamingDelegate:StreamingProtocol?
    var cameraMode : Bool = false

    var dataSource = ["Live Stream", "Photos", "Video" , "Catch gif", "Time lapse", "Switch to iPhone"]
   
    override func viewDidLoad() {
        super.viewDidLoad()
        snapCamSettingsTableView.separatorStyle = .None
    }
    
    override func viewWillDisappear(animated: Bool) {
        
//        let presentingViewController :UIViewController! = self.presentingViewController;
//        let vc:MovieViewController = presentingViewController as! MovieViewController
//        vc.initialiseDecoder()

    }
    
    // Blur for ios 8
    
    //    override func viewWillAppear(animated: Bool) {
    //            self.view.backgroundColor = UIColor.clearColor()
    //            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
    //            let blurEffectView = UIVisualEffectView(effect: blurEffect)
    //            //always fill the view
    //            blurEffectView.frame = self.view.bounds
    //            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    //            self.view.addSubview(blurEffectView)
    //            self.view.bringSubviewToFront(snapCamSettingsTableView)//if you have more UIViews, use an insertSubview API to place it where needed
    //        }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //PRAGMA MARK:- TableView datasource, delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let count = dataSource.count
        if count > 0
        {
            return count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
       let cell = tableView.dequeueReusableCellWithIdentifier(SnapCamTableViewCell.identifier, forIndexPath: indexPath) as! SnapCamTableViewCell
        if dataSource.count > indexPath.row
        {
            cell.optionlabel.text = dataSource[indexPath.row]
        }
        if indexPath.row == 0
        {
            customizeCellBasedOnSnapCamSelectionMode(cell)
        }
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
       let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
       switch(indexPath.row)
       {
       case 0 :
        cameraMode = !cameraMode
        customizeCellBasedOnSnapCamSelectionMode(selectedCell);
//        if cameraMode
//        {
//            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
//            selectedCell.setSelected(true, animated: true)
//            cameraMode = false
//        }
//        else
//        {
//            selectedCell.contentView.backgroundColor = UIColor.clearColor()
//            selectedCell.setSelected(false, animated: true)
//
//            cameraMode = true
//        }
        
        streamingDelegate?.cameraSelectionMode(cameraMode)
//        
//            let streamingStoryboard = UIStoryboard(name:"Streaming" , bundle: nil)
//            let uploadStreamViewController = streamingStoryboard.instantiateViewControllerWithIdentifier(UploadStreamViewController.identifier)
//            
//            self.presentViewController(uploadStreamViewController, animated: true, completion: { () -> Void in
//            })
        
            break
        
       case 1:
            cameraMode =  true;
//            self.dismissViewControllerAnimated(true, completion: { () -> Void in
//        })

       default :
            cameraMode = true;
            break
       }
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
        //return snapCamSettingsTableView.bounds.height / CGFloat(dataSource.count)

    }
    
    
    func customizeCellBasedOnSnapCamSelectionMode(selectedCell:UITableViewCell)
    {
        if cameraMode == false
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
            selectedCell.setSelected(true, animated: true)
//            cameraMode = false
        }
        else
        {
            selectedCell.contentView.backgroundColor = UIColor.clearColor()
            selectedCell.setSelected(false, animated: true)
            
//            cameraMode = true
        }
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func settingsbuttonClicked(sender: AnyObject)
    {
        
    }
    @IBAction func snapcamButtonClicked(sender: AnyObject)
    {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}





