//
//  IPhoneCameraViewController.h
//  iONLive
//
//  Created by Vinitha on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <Photos/Photos.h>


@interface IPhoneCameraViewController : UIViewController

-(NSMutableDictionary *) displayIphoneCameraSnapShots ;
-(UIImage *)thumbnaleImage:(UIImage *)image scaledToFillSize:(CGSize)size;
-(void) deleteIphoneCameraSnapShots;
-(void) uploadprogress:(float) progress;
-(void) loggedInDetails:(NSDictionary *) detailArray userImages : (NSArray *) userImages;

@property (weak, nonatomic) IBOutlet UIImageView *latestSharedMediaImage;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UILabel *sharedUserCount;
@property (strong, nonatomic) IBOutlet UIImageView *playiIconView;

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
@end
