//
//  MovieViewController.h
//  LiveStreamingKXMovie
//
//  Created by Vinitha on 11/20/15.
//  Copyright © 2015 Vinitha K S. All rights reserved.
//

#import <UIKit/UIKit.h>
@class KxMovieDecoder;

extern NSString * const KxMovieParameterMinBufferedDuration;    // Float
extern NSString * const KxMovieParameterMaxBufferedDuration;    // Float
extern NSString * const KxMovieParameterDisableDeinterlacing;   // BOOL

@interface MovieViewController : UIViewController

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                liveVideo:(BOOL) live;
//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@property (readonly) BOOL playing;

- (void) play;
- (void) pause;

@end
