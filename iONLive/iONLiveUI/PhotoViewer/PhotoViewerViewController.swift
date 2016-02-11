//
//  PhotoViewerViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/3/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UIViewController {

    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
     static let identifier = "PhotoViewerViewController"
    
    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    var dataSource:[[String:UIImage]] = [[String:UIImage]]()
   
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readImageFromDataBase()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func readImageFromDataBase()
    {
        let cameraController = IPhoneCameraViewController()
        if snapShots.count > 0
        {
            let snapShotsKeys = snapShots.allKeys as NSArray
            var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
            let screenRect : CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let checkValidation = NSFileManager.defaultManager()
            for var index = 0; index < snapShotsKeys.count; index++
            {
                if let thumbNailImagePath = snapShots.valueForKey(snapShotsKeys[index] as! String)
                {
                    if (checkValidation.fileExistsAtPath(thumbNailImagePath as! String))
                    {
                        let imageToConvert = UIImage(data: NSData(contentsOfFile: thumbNailImagePath as! String)!)
                        let sizeThumb = CGSizeMake(50,50)
                        let sizeFull = CGSizeMake(screenWidth*2,screenHeight)
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
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 1, 0, 1)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
}
