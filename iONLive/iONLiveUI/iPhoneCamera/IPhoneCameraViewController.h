//
//  IPhoneCameraViewController.h
//  iONLive
//
//  Created by Vinitha on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IPhoneCameraViewController : UIViewController

-(NSMutableDictionary *) displayIphoneCameraSnapShots ;
-(UIImage *)thumbnaleImage:(UIImage *)image scaledToFillSize:(CGSize)size;

@end
