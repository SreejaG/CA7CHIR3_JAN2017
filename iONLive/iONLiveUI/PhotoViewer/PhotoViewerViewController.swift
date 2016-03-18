//
//  PhotoViewerViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/3/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate {

    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
     static let identifier = "PhotoViewerViewController"
    
    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    var dataSource:[[String:UIImage]] = [[String:UIImage]]()
   
    @IBOutlet var fullScreenZoomView: UIImageView!
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        readImageFromDataBase()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        
//        let kKeychainItemName: String = "ion-live-1120"
//        let kMyClientID: String = "821885679497-88oi8625g6g9kmpojmi5edv8t6qibu59.apps.googleusercontent.com"
//        let kMyClientSecret: String = "YjoqEGOdqEKuQHVuDxH0bYgW"
//        let kScope: String = "signedurl@ion-live-1120.iam.gserviceaccount.com"
        
        fullScreenZoomView.userInteractionEnabled = true
        fullScreenZoomView.hidden = true
        fullScrenImageView.userInteractionEnabled = true
        
        let enlargeImageViewRecognizer = UITapGestureRecognizer(target: self, action: "enlargeImageView:")
        enlargeImageViewRecognizer.numberOfTapsRequired = 1
        fullScrenImageView.addGestureRecognizer(enlargeImageViewRecognizer)
        
        let shrinkImageViewRecognizer = UITapGestureRecognizer(target: self, action: "shrinkImageView:")
        shrinkImageViewRecognizer.numberOfTapsRequired = 1
        fullScreenZoomView.addGestureRecognizer(shrinkImageViewRecognizer)
    
//        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
//        lpgr.minimumPressDuration = 0.5
//        lpgr.delaysTouchesBegan = true
//        lpgr.delegate = self
//        self.photoThumpCollectionView.addGestureRecognizer(lpgr)
        
    }

    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = false
    }
    
    func shrinkImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = true
    }
    
//    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
//        if gestureReconizer.state != UIGestureRecognizerState.Ended {
//            return
//        }
//        
//        let p = gestureReconizer.locationInView(self.photoThumpCollectionView)
//        let indexPath = self.photoThumpCollectionView.indexPathForItemAtPoint(p)
//        
//        if let index = indexPath {
//            let cell = self.photoThumpCollectionView.cellForItemAtIndexPath(index)
//            cell?.layer.borderWidth = 1.0
//            cell?.layer.borderColor = UIColor.blueColor().CGColor
//            
//            let singleTapImageViewRecognizer = UITapGestureRecognizer(target: self, action: "singleTap:")
//            singleTapImageViewRecognizer.numberOfTapsRequired = 1
//            cell!.addGestureRecognizer(singleTapImageViewRecognizer)
//            
//            print(index.row)
//        } else {
//            print("Could not find index path")
//        }
//    }
//
//    func singleTap(Recognizer:UITapGestureRecognizer){
//        let p = Recognizer.locationInView(self.photoThumpCollectionView)
//        let indexPath = self.photoThumpCollectionView.indexPathForItemAtPoint(p)
//        
//        if let index = indexPath {
//            let cell = self.photoThumpCollectionView.cellForItemAtIndexPath(index)
//            cell?.layer.borderColor = UIColor.clearColor().CGColor
//            cell?.removeGestureRecognizer(Recognizer)
//        }
//    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        let storyboard = UIStoryboard(name:"MyChannel" , bundle: nil)
        let addChannelVC = storyboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        addChannelVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(addChannelVC, animated: false)
    }
    func readImageFromDataBase()
    {
        let cameraController = IPhoneCameraViewController()
        
        if snapShots.count > 0
        {
            let snapShotsKeys = snapShots.allKeys as NSArray
            
            let descriptor: NSSortDescriptor = NSSortDescriptor(key: nil, ascending: false)
            let sortedSnapShotsKeys: NSArray = snapShotsKeys.sortedArrayUsingDescriptors([descriptor])
            
            var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
            let screenRect : CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let checkValidation = NSFileManager.defaultManager()
            for var index = 0; index < sortedSnapShotsKeys.count; index++
            {
                if let thumbNailImagePath = snapShots.valueForKey(sortedSnapShotsKeys[index] as! String)
                {
                    if (checkValidation.fileExistsAtPath(thumbNailImagePath as! String))
                    {
                        let imageToConvert = UIImage(data: NSData(contentsOfFile: thumbNailImagePath as! String)!)
                        let sizeThumb = CGSizeMake(50,50)
                        let sizeFull = CGSizeMake(screenWidth*4,screenHeight*3)
                        let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                        let imageAfterConversionFullscreen = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeFull)
                        dummyImagesDataSource.append([thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageAfterConversionFullscreen!])
                    }
                }
            }
            
            dataSource = dummyImagesDataSource
            if dummyImagesDataSource.count > 0
            {
                if let imagePath = dummyImagesDataSource[0][fullImageKey]
                {
                
                    self.fullScrenImageView.image = imagePath
                    self.fullScreenZoomView.image = imagePath
                }
            }
        }
    }
    //PRAGMA MARK:- IBActions

    @IBAction func channelButtonClicked(sender: AnyObject)
    {
        let myChannelStoryboard = UIStoryboard(name:"MyChannel" , bundle: nil)
        let myChannelVC = myChannelStoryboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier)
        myChannelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(myChannelVC, animated: true)
    }
    @IBAction func donebuttonClicked(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
}

extension PhotoViewerViewController:UICollectionViewDelegate,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return dataSource.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoThumbCollectionViewCell", forIndexPath: indexPath) as! PhotoThumbCollectionViewCell
        
        //cell for live streams
        
        if dataSource.count > indexPath.row
        {
            var dict = dataSource[indexPath.row]
            if let thumpImage = dict[thumbImageKey]
            {
                cell.thumbImageView.image = thumpImage
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if dataSource.count > indexPath.row
        {
            var dict = dataSource[indexPath.row]
            
            if let fullImage = dict[fullImageKey]
            {
                self.fullScrenImageView.image = fullImage
                self.fullScreenZoomView.image = fullImage
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 1, 1, 1)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
}
