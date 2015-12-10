//
//  PhotoViewerViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/3/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UIViewController {

    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    var dataSource:[String]?
    
    var thumbImagesDataSource = ["thumb1","thumb2","thumb3","thumb4","thumb5","thumb6" , "thumb7","thumb8","thumb9","thumb10","thumb11","thumb12"]
    
    static let identifier = "PhotoViewerViewController"
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = thumbImagesDataSource
        self.fullScrenImageView.image = UIImage(named: thumbImagesDataSource[0])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //PRAGMA MARK:- IBActions
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
                cell.thumbImageView.image = UIImage(named: dataSource[indexPath.row])
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
                self.fullScrenImageView.image = UIImage(named:dataSource[indexPath.row])
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
