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
    var dataSource:[[String:String]]?
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var dummyImagesDataSource = [[thumbImageKey:"photo1thmb",fullImageKey:"photoV1"],[thumbImageKey:"photo2thmb",fullImageKey:"photoV2"],[thumbImageKey:"photo3thmb",fullImageKey:"photo3"],[thumbImageKey:"photo4thmb",fullImageKey:"photo4"],[thumbImageKey:"photo5thmb",fullImageKey:"photo5"],[thumbImageKey:"photo6thmb",fullImageKey:"photo6"],[thumbImageKey:"photo7thmb",fullImageKey:"photo7"],[thumbImageKey:"photo8thmb",fullImageKey:"photo8"],[thumbImageKey:"photo9thmb",fullImageKey:"photo9"],[thumbImageKey:"photo10thmb",fullImageKey:"photo10"]]
        
        dataSource = dummyImagesDataSource
        self.fullScrenImageView.image = UIImage(named: dummyImagesDataSource[0][fullImageKey]!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        if let dataSource = dataSource
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoThumbCollectionViewCell", forIndexPath: indexPath) as! PhotoThumbCollectionViewCell
        
        //cell for live streams
        
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                var dict = dataSource[indexPath.row]
                if let thumpImage = dict[thumbImageKey]
                {
                    cell.thumbImageView.image = UIImage(named: thumpImage)
                }
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                var dict = dataSource[indexPath.row]
                if let fullImage = dict[fullImageKey]
                {
                     self.fullScrenImageView.image = UIImage(named:fullImage)
                }
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
