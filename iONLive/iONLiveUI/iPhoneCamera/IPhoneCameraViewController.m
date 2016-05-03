//
//  IPhoneCameraViewController.m
//  iONLive
//
//  Created by Vinitha on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//
@import AVFoundation;
@import Photos;

#import <UIKit/UIKit.h>
#import "IPhoneCameraViewController.h"
#import "AAPLPreviewView.h"
#import "iONLive-Swift.h"
#import "VCSimpleSession.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>




static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

NSString* selectedFlashOption = @"selectedFlashOption";
int thumbnailSize = 50;



typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface IPhoneCameraViewController ()<AVCaptureFileOutputRecordingDelegate , StreamingProtocol,  VCSessionDelegate>

{
    SnapCamSelectionMode _snapCamMode;
    
}


//Video Core Session
@property (nonatomic, retain) VCSimpleSession* liveSteamSession;

// For use in the storyboards.
@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *startCameraActionButton;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (strong, nonatomic) IBOutlet UIView *topView;
// Utilities.
@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (strong, nonatomic) IBOutlet UIView *bottomView;

//Flash settings
@property (nonatomic) AVCaptureFlashMode currentFlashMode;

@property (strong, nonatomic) IBOutlet UIImageView *activityImageView;
@property (strong, nonatomic) IBOutlet UILabel *noDataFound;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *_activityIndicatorView;
@property (strong, nonatomic) IBOutlet UIView *activitView;
@property (strong, nonatomic) IBOutlet UIButton *iphoneCameraButton;

@end

@implementation IPhoneCameraViewController

NSMutableDictionary * snapShotsDict;
IPhoneLiveStreaming * liveStreaming;
NSMutableDictionary *ShotsDict;


- (void)viewDidLoad {
    
 
    [super viewDidLoad];
    SetUpView *viewSet = [[SetUpView alloc]init];
    [viewSet getValue];
    [self initialiseView];
    [_uploadActivityIndicator setHidden:YES];
    PhotoViewerInstance.iphoneCam = self;
    [_uploadProgressCameraView setHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

}
-(void) loggedInDetails:(NSDictionary *) detailArray{
    
        NSString * sharedUserCount = detailArray[@"sharedUserCount"];
        NSArray * sharedUserThumbnail = detailArray[@"sharedUserThumbnails"];
        NSString * mediaSharedCount =  detailArray[@"mediaSharedCount"];
        NSString * latestSharedMediaThumbnail =   detailArray[@"latestSharedMediaThumbnail"];
        NSString * latestCapturedMediaThumbnail =detailArray[@"latestCapturedMediaThumbnail"];
        NSString *latestSharedMediaType =   detailArray[@"latestSharedMediaType"];
        NSString *latestCapturedMediaType  =  detailArray[@"latestCapturedMediaType"];
        
    _sharedUserCount.text = sharedUserCount;
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: latestCapturedMediaThumbnail]];
        if ( data == nil )
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            // WARNING: is the cell still using the same data by this point??
            if([latestCapturedMediaType  isEqual: @"video"])
            {
                self.playiIconView.hidden = false;
            }
             self.thumbnailImageView.image= [UIImage imageWithData: data];
        });
      
    });
    
    if([mediaSharedCount  isEqual: @"0"])
    {
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: latestSharedMediaThumbnail]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                // WARNING: is the cell still using the same data by this point??
                if([latestCapturedMediaType  isEqual: @"video"])
                {
                    self.playiIconView.hidden = false;
                }
                self.latestSharedMediaImage.image= [UIImage imageWithData: data];
            });
            
        });
    }
    else{
     //   _countLabel.hidden= false;
       // _countLabel.text = mediaSharedCount;
    }

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.activitView.hidden = true;
    NSInteger shutterActionMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"shutterActionMode"];

    if (! [self isStreamStarted]) {
    if (shutterActionMode == SnapCamSelectionModeLiveStream)
    {
        self.previewView.session = nil;
        self.previewView.hidden = true;
        _liveSteamSession = [[VCSimpleSession alloc] initWithVideoSize:[[UIScreen mainScreen]bounds].size frameRate:30 bitrate:1000000 useInterfaceOrientation:YES];
        //    _session.orientationLocked = YES;
        AVCaptureVideoPreviewLayer  *ptr;
        [_liveSteamSession getCameraPreviewLayer:(&ptr)];
//        _liveSteamSession.delegate = self;
        [self.view addSubview:_liveSteamSession.previewView];
        _liveSteamSession.previewView.frame = self.view.bounds;
        _liveSteamSession.delegate = self;
        [self.view bringSubviewToFront:self.bottomView];
        [self.view bringSubviewToFront:self.topView];
    }
    else{
        [_liveSteamSession.previewView removeFromSuperview];
        [self removeObservers];

        self.session = [[AVCaptureSession alloc] init];
        //
        self.previewView.hidden = false;
        [self configureCameraSettings];

        //    // Setup the preview view.
        self.previewView.session = self.session;
    //}

    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
    }
    }
}
-(void) uploadprogress :(float) progress
{
 

    [ self.thumbnailImageView setAlpha:1.0];
    if (!_playiIconView.hidden)
    {
        [_playiIconView setAlpha:1.0];

    }
    [_uploadProgressCameraView setHidden:YES];
    if (progress == 1.0 || progress == 1)
    {
        [_uploadActivityIndicator stopAnimating];
        [_uploadActivityIndicator setHidden:YES];
        [_uploadProgressCameraView setHidden:YES];
        
    }
   // _uploadProgressCameraView.progress = progress;
   
}

#pragma mark initialise View

-(void)initialiseView
{
    _countLabel.layer.cornerRadius = 5;
    _countLabel.layer.masksToBounds = true;
    
    _noDataFound.hidden = true;
    _activityImageView.hidden = true;
    __activityIndicatorView.hidden = true;
    [_startCameraActionButton setImage:[UIImage imageNamed:@"camera_Button_ON"] forState:UIControlStateHighlighted];
    
    [_playiIconView setHidden:YES];
    
    liveStreaming = [[IPhoneLiveStreaming alloc]init];
    
    _snapCamMode = SnapCamSelectionModeiPhone;
    _currentFlashMode = AVCaptureFlashModeOff;
    
    self.navigationController.navigationBarHidden = true;
    [self.topView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.4]];
    
    [self deleteIphoneCameraSnapShots];
     [self checkCountForLabel];
    self.thumbnailImageView.image = [self readImageFromDataBase];
    
    
   
}

-(void) checkCountForLabel
{
    
    NSArray *mediaArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"Shared"];
    NSInteger count = 0;
    
    for (int i=0;i< mediaArray.count;i++)
    {
        count = count + [ mediaArray[i][@"total_no_media_shared"] integerValue];
    }
    if(count==0)
    {
        _countLabel.hidden= true;
    }
    else
    {
        _countLabel.hidden= false;
        _countLabel.text = [NSString stringWithFormat:@"%ld",(long)count];
    }
    NSLog(@"%ld",(long)count);
}

-(void)showProgressBar
{
    dispatch_async( dispatch_get_main_queue(), ^{
        
        [_iphoneCameraButton setImage:[UIImage imageNamed:@"Live_now_off_mode"] forState:UIControlStateNormal];

        _activityImageView.image =  [UIImage animatedImageNamed:@"loader-" duration:1.0f];
        _activityImageView.hidden = false;
        [__activityIndicatorView startAnimating];
        __activityIndicatorView.hidden = false;
        _noDataFound.text = @"Initializing Stream";
        _noDataFound.hidden = false;
        _liveSteamSession.previewView.hidden = true;
    
    } );
   
    
    [self setUpInitialBlurView];
}

-(void)hideProgressBar
{
    dispatch_async( dispatch_get_main_queue(), ^{
    
        [_iphoneCameraButton setImage:[UIImage imageNamed:@"Live_now_mode"] forState:UIControlStateNormal];

        _activityImageView.hidden = true;
        [__activityIndicatorView stopAnimating];
        __activityIndicatorView.hidden = true;
        _noDataFound.hidden = true;
        self.activitView.hidden = true;
        _liveSteamSession.previewView.hidden = false;
        [self.bottomView setUserInteractionEnabled:YES];
        } );
   
}

-(UIImage*)readImageFromDataBase
{
    snapShotsDict = [[NSMutableDictionary alloc]init];
    snapShotsDict = [self displayIphoneCameraSnapShots];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    UIImage * thumbNailImage = [[UIImage alloc]init];
    if([snapShotsDict count] > 0){
        NSLog(@"SnapshotDict=%@",snapShotsDict);
        NSMutableArray *dateArray=[[NSMutableArray alloc]init];
        NSArray *snapShotKeys=[[NSArray alloc]init];
        snapShotKeys = [snapShotsDict allKeys];
        for(int i=0; i<[snapShotKeys count]; i++){
            [dateFormat setDateFormat:@"dd_MM_yyyy_HH_mm_ss"];
            NSDate *date = [dateFormat dateFromString:snapShotKeys[i]];
            dateArray[i]=date;
        }
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:NO];
        NSArray *dateArray1 = [dateArray sortedArrayUsingDescriptors:@[sd]];
        
        thumbNailImage = [self thumbnaleImage:[UIImage imageWithData:[NSData dataWithContentsOfFile:[snapShotsDict valueForKey:[NSString stringWithFormat:@"%@",[dateFormat stringFromDate:dateArray1[0]]]]] ] scaledToFillSize:CGSizeMake(thumbnailSize, thumbnailSize)];
    }
    else{
        thumbNailImage = [UIImage imageNamed:@"photo1"];
    }
    return thumbNailImage;
}

#pragma mark KVO and Notifications

- (void)addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    [self.stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.layer.opacity = 1.0;
                }];
            } );
        }
    }
    else if ( context == SessionRunningContext ) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            // Only enable the ability to change camera if the device has more than one camera.
            self.cameraButton.enabled = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
//            self.recordButton.enabled = isSessionRunning;
//            self.stillButton.enabled = isSessionRunning;
        } );
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    // Otherwise, enable the user to try to resume the session running.
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
            else {
                dispatch_async( dispatch_get_main_queue(), ^{
//                    self.resumeButton.hidden = NO;
                } );
            }
        } );
    }
    else {
//        self.resumeButton.hidden = NO;
    }
}


- (void)dealloc {
    AVCaptureInput* input = [_session.inputs objectAtIndex:0];
    [_session removeInput:input];
    AVCaptureVideoDataOutput* output = [_session.outputs objectAtIndex:0];
    [_session removeOutput:output];
    [_session stopRunning];
}


- (void)sessionWasInterrupted:(NSNotification *)notification
{
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCam,
    // then the user can let AVCam resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    BOOL showResumeButton = NO;
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    if ( &AVCaptureSessionInterruptionReasonKey ) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            showResumeButton = YES;
        }
        else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
            // Simply fade-in a label to inform the user that the camera is unavailable.
//            self.cameraUnavailableLabel.hidden = NO;
//            self.cameraUnavailableLabel.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
//                self.cameraUnavailableLabel.alpha = 1.0;
            }];
        }
    }
    else {
        NSLog( @"Capture session was interrupted" );
        showResumeButton = ( [UIApplication sharedApplication].applicationState == UIApplicationStateInactive );
    }
    
    if ( showResumeButton ) {
        // Simply fade-in a button to enable the user to try to resume the session running.
//        self.resumeButton.hidden = NO;
//        self.resumeButton.alpha = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
//            self.resumeButton.alpha = 1.0;
        }];
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog( @"Capture session interruption ended" );
    
//    if ( ! self.resumeButton.hidden ) {
//        [UIView animateWithDuration:0.25 animations:^{
//            self.resumeButton.alpha = 0.0;
//        } completion:^( BOOL finished ) {
//            self.resumeButton.hidden = YES;
//        }];
//    }
//    if ( ! self.cameraUnavailableLabel.hidden ) {
//        [UIView animateWithDuration:0.25 animations:^{
//            self.cameraUnavailableLabel.alpha = 0.0;
//        } completion:^( BOOL finished ) {
//            self.cameraUnavailableLabel.hidden = YES;
//        }];
//    }
}

#pragma mark File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    // Enable the Record button to let the user stop the recording.
    dispatch_async( dispatch_get_main_queue(), ^{
        self.cameraButton.enabled = YES;
        self.startCameraActionButton.enabled = YES;
//        [self.recordButton setTitle:NSLocalizedString( @"Stop", @"Recording button stop title") forState:UIControlStateNormal];
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    dispatch_async( dispatch_get_main_queue(), ^{
        self.cameraButton.enabled = YES;
        self.startCameraActionButton.enabled = YES;
    } );
    // Note that currentBackgroundRecordingID is used to end the background task associated with this recording.
    // This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's isRecording property
    // is back to NO — which happens sometime after this method returns.
    // Note: Since we use a unique file path for each recording, a new recording will not overwrite a recording currently being saved.
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
//    dispatch_block_t cleanup = ^{
//        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
//        if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
//            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
//        }
//    };
//    
    BOOL success = YES;
    
    if ( error ) {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if ( success ) {
        
        // Check authorization status.
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
            if ( status == PHAuthorizationStatusAuthorized ) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSData *imageData = [[NSData alloc]init];
                    imageData = [self getThumbNail:outputFileURL];
                  //  [_uploadActivityIndicator setHidden:NO];
                    
                //    [_uploadActivityIndicator startAnimating];
                    self.thumbnailImageView.image = [self thumbnaleImage:[UIImage imageWithData:imageData] scaledToFillSize:CGSizeMake(thumbnailSize, thumbnailSize)];
                    [_playiIconView setHidden:NO];
                  //  [ self.thumbnailImageView setAlpha:0.4];
                //    [_playiIconView setAlpha:0.4];

                    [self saveImage:imageData];
                    [self moveVideoToDocumentDirectory:outputFileURL];

//                    cleanup();
                });
                
                
                
                // Save the movie file to the photo library and cleanup.
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                    // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                    if ( [PHAssetResourceCreationOptions class] ) {
                        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                        options.shouldMoveFile = YES;
                        PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                        [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                    }
                    else {
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                    }
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                        NSLog( @"Could not save movie to photo library: %@", error );
                    }
                   // cleanup();
                }];
            }
            else {
              //  cleanup();
            }
        }];
    }
    else {
       // cleanup();
    }
    // Enable the Camera and Record buttons to let the user switch camera and start another recording.
    dispatch_async( dispatch_get_main_queue(), ^{
        // Only enable the ability to change camera if the device has more than one camera.
        self.cameraButton.enabled = ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
//        self.recordButton.enabled = YES;
//        [self.recordButton setTitle:NSLocalizedString( @"Record", @"Recording button record title" ) forState:UIControlStateNormal];
    });
}

-(void) moveVideoToDocumentDirectory : (NSURL *) path
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"dd_MM_yyyy_HH_mm_ss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSURL *fileURL = [self grabFileURL:[NSString stringWithFormat:@"%@%@",dateString,@".mov"]];
    NSData *movieData = [NSData dataWithContentsOfURL:path];
 //  BOOL success =  [movieData writeToURL:fileURL atomically:YES];
    
    NSLog(@"&&&&&&&&&%@",fileURL);
   // [self saveIphoneCameraSnapShots:dateString path:[fileURL path]];
  [self loaduploadManager : path ];
    // save it to the Camera Roll
    UISaveVideoAtPathToSavedPhotosAlbum([path path], nil, nil, nil);
//    if(success)
//    {
//  //  [self loaduploadManager : fileURL];
//    }
//    else{
//        NSLog(@"%@ failed to write");
//    }
    
}



- (NSURL*)grabFileURL:(NSString *)fileName {
    
    // find Documents directory
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    // append a file name to it
    documentsURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    return documentsURL;
}
#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}
#pragma mark take photo or record movie

-(void)takePicture
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        
        // Update the orientation on the still image output video connection before capturing.
        connection.videoOrientation = previewLayer.connection.videoOrientation;
        
        
        [IPhoneCameraViewController setFlashMode:self.currentFlashMode forDevice:self.videoDeviceInput.device];
        
        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( imageDataSampleBuffer ) {
                // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    if ( status == PHAuthorizationStatusAuthorized ) {
                        
                        //create and show thumbnail
                        dispatch_async( dispatch_get_main_queue(), ^{
                          //  [_uploadActivityIndicator setHidden:NO];

                        //   [_uploadActivityIndicator startAnimating];
                           // [ self.thumbnailImageView setAlpha:0.4];

                            self.thumbnailImageView.image = [self thumbnaleImage:[UIImage imageWithData:imageData] scaledToFillSize:CGSizeMake(thumbnailSize, thumbnailSize)];
                            
                            [self saveImage:imageData];
                            
                        //    [self loaduploadManager];
                          [self loaduploadManagerForImage];
                            
                        } );
                    }
                }];
            }
            else {
                NSLog( @"Could not capture still image: %@", error );
            }
        }];
    } );
}
-(UIImage*) drawImage:(UIImage*) fgImage
              inImage:(UIImage*) bgImage
              atPoint:(CGPoint)  point
{
    UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
    [bgImage drawInRect:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];
    [fgImage drawInRect:CGRectMake(bgImage.size.width - fgImage.size.width, bgImage.size.height - fgImage.size.height, fgImage.size.width, fgImage.size.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}
- (void)startMovieRecording
{
    // Disable the Camera button until recording finishes, and disable the Record button until recording starts or finishes. See the
    // AVCaptureFileOutputRecordingDelegate methods.
    self.cameraButton.enabled = NO;
    self.startCameraActionButton.enabled = NO;
    
    dispatch_async( self.sessionQueue, ^{
        if ( ! self.movieFileOutput.isRecording ) {
            if ( [UIDevice currentDevice].isMultitaskingSupported ) {
                // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                // callback is not received until AVCam returns to the foreground unless you request background execution time.
                // This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                // To conclude this background execution, -endBackgroundTask is called in
                // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            
            // Update the orientation on the movie file output video connection before starting recording.
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            
            [IPhoneCameraViewController setFlashMode:AVCaptureFlashModeOn forDevice:self.videoDeviceInput.device];
            //			[AAPLCameraViewController setFlashMode:self.currentFlashMode forDevice:self.videoDeviceInput.device];
            
            // Start recording to a temporary file.
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        }
        else {
            [self.movieFileOutput stopRecording];
        }
    } );
}

#pragma mark save Image to DataBase

-(void)saveImage:(NSData *)imageData
{
    NSArray *paths= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath=@"";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"dd_MM_yyyy_HH_mm_ss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    filePath = [documentsDirectory stringByAppendingPathComponent:dateString];
    BOOL s = [imageData writeToFile:filePath atomically:YES];
    
    NSLog(@"BOOl%@",filePath);
    [self saveIphoneCameraSnapShots:dateString path:filePath];
    
   ShotsDict = [[NSMutableDictionary alloc]init];
   [ShotsDict setValue:filePath forKey:dateString];
}

-(void) saveIphoneCameraSnapShots :(NSString *)imageName path:(NSString *)path{
    
    AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = appDel.managedObjectContext;
    NSManagedObject *newSnapShots =[NSEntityDescription insertNewObjectForEntityForName:@"SnapShots" inManagedObjectContext:context];
    
    [newSnapShots setValue:imageName forKey:@"imageName"];
    [newSnapShots setValue:path forKey:@"path"];
    [context save:nil];
}

-(NSMutableDictionary *) displayIphoneCameraSnapShots {
    
    AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = appDel.managedObjectContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"SnapShots"];
    request.returnsObjectsAsFaults=false;
    
    NSMutableDictionary *snapShotsDict = [[NSMutableDictionary alloc]init];
    NSArray *snapShotsArray = [[NSArray alloc]init];
    snapShotsArray = [context executeFetchRequest:request error:nil];
    
    NSLog(@"Array%@",snapShotsArray);
    
    if([snapShotsArray count] > 0){
    
        for(NSString *snapShotValue in snapShotsArray)
        {
            NSString *snapImageName =[snapShotValue valueForKey:@"imageName"];
            NSString *snapImagePath = [snapShotValue valueForKey:@"path"];
            [snapShotsDict setValue:snapImagePath forKey:snapImageName];
        }
    }
    
    NSLog(@"Dictionary%@",snapShotsDict);
    return snapShotsDict;
}

-(void) deleteIphoneCameraSnapShots{
    AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = appDel.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"SnapShots"];
    request.returnsObjectsAsFaults=false;
    NSArray *snapShotsArray = [[NSArray alloc]init];
    snapShotsArray = [context executeFetchRequest:request error:nil];
    NSFileManager *defaultManager = [[NSFileManager alloc]init];
    for(int i=0;i<[snapShotsArray count];i++){
        if(![defaultManager fileExistsAtPath:[snapShotsArray[i] valueForKey:@"path"]]){
            NSManagedObject * obj = snapShotsArray[i];
            [context deleteObject:obj];
        }
    }
    [context save:nil];
}

#pragma mark Button Actions

- (IBAction)didTapsCameraActionButton:(id)sender
{
    NSInteger shutterActionMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"shutterActionMode"];
    if (shutterActionMode == SnapCamSelectionModePhotos) {
        [_playiIconView setHidden:YES];
        [self takePicture];
    }
    else if (shutterActionMode == SnapCamSelectionModeVideo)
    {
        [self startMovieRecording];
    }
    else if (shutterActionMode == SnapCamSelectionModeLiveStream)
    {
      
        switch(_liveSteamSession.rtmpSessionState) {
            case VCSessionStateNone:
            case VCSessionStatePreviewStarted:
            case VCSessionStateEnded:
            case VCSessionStateError:
            {
                [liveStreaming startLiveStreaming:_liveSteamSession];
                [self showProgressBar];
                break;
            }
            default:
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [liveStreaming stopStreamingClicked];
                [_liveSteamSession endRtmpSession];
                break;
        }
    }
}

-(void)setUpInitialBlurView
{
    UIGraphicsBeginImageContext(CGSizeMake(self.view.bounds.size.width, (self.view.bounds.size.height+67.0)));
    NSLog(@"glView.bounds%f",self.view.bounds.size.height);
    [[UIImage imageNamed:@"live_stream_blur.png"] drawInRect:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, (self.view.bounds.size.height+67.0))];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    self.activitView.hidden =false;
    [self.bottomView setUserInteractionEnabled:NO];
}


- (IBAction)didTapChangeCamera:(id)sender
{
    self.cameraButton.enabled = NO;
//    self.recordButton.enabled = NO;
//    self.stillButton.enabled = NO;
    // flip camera view
    [UIView transitionWithView:_previewView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:nil completion:^(BOOL finished) {
    }];
    
    dispatch_async( self.sessionQueue, ^{
        
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                
                preferredPosition = AVCaptureDevicePositionBack;
                [self showFlashImage:true];
                break;
                
            case AVCaptureDevicePositionBack:
                
                preferredPosition = AVCaptureDevicePositionFront;
                [self showFlashImage:false];

                break;
        }
        
        AVCaptureDevice *videoDevice = [IPhoneCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [self.session beginConfiguration];
        
        // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
        [self.session removeInput:self.videoDeviceInput];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [IPhoneCameraViewController setFlashMode:self.currentFlashMode forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        }
        else {
            [self.session addInput:self.videoDeviceInput];
        }
        
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( connection.isVideoStabilizationSupported ) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        
        [self.session commitConfiguration];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            self.cameraButton.enabled = YES;
//            self.recordButton.enabled = YES;
//            self.stillButton.enabled = YES;
            
        } );
    } );
}

- (IBAction)didTapCamSelectionButton:(id)sender
{
//    [self stopLiveStreaming];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    SnapCamSelectViewController *snapCamSelectVC = (SnapCamSelectViewController*)[storyboard instantiateViewControllerWithIdentifier:@"SnapCamSelectViewController"];
    snapCamSelectVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    snapCamSelectVC.streamingDelegate = self;
    snapCamSelectVC.snapCamMode = [self getCameraSelectionMode];
    snapCamSelectVC.toggleSnapCamIPhoneMode = SnapCamSelectionModeiPhone;
    //[self getCameraSelectionMode];
    [self presentViewController:snapCamSelectVC animated:YES completion:nil];
    
}

- (IBAction)didTapSharingListIcon:(id)sender
{
    UIStoryboard *sharingStoryboard = [UIStoryboard storyboardWithName:@"sharing" bundle:nil];
    UIViewController *mysharedChannelVC = [sharingStoryboard instantiateViewControllerWithIdentifier:@"MySharedChannelsViewController"];
    
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:mysharedChannelVC];
    navController.navigationBarHidden = true;
    
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:navController animated:true completion:^{
    }];
//    [self presentViewController:mysharedChannelVC animated:true completion:^{
//        
//    }];
}

- (IBAction)didTapPhotoViewer:(id)sender {
        
    [self loadPhotoViewer];
}

- (IBAction)didTapStreamThumb:(id)sender {

    [self loadStreamsGalleryView];
}

- (IBAction)didTapFlashImage:(id)sender {
    
    if (_currentFlashMode == AVCaptureFlashModeOn) {
        
        [self.flashButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
        _currentFlashMode = AVCaptureFlashModeOff;
    }
    else{
        
        [self.flashButton setImage:[UIImage imageNamed:@"flash_On"] forState:UIControlStateNormal]; //Need to update the icon once available.
        _currentFlashMode = AVCaptureFlashModeOn;
    }
}

#pragma mark Load views

-(void) loadPhotoViewer
{
    snapShotsDict = [self displayIphoneCameraSnapShots];
    
    UIStoryboard *streamingStoryboard = [UIStoryboard storyboardWithName:@"PhotoViewer" bundle:nil];
    
    PhotoViewerViewController *photoViewerViewController =( PhotoViewerViewController*)[streamingStoryboard instantiateViewControllerWithIdentifier:@"PhotoViewerViewController"];
    
    photoViewerViewController.snapShots = snapShotsDict;
  //  PhotoViewerViewController.ShotsDictionary =ShotsDict;
    photoViewerViewController.ShotsDictionary =ShotsDict;
    

    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:photoViewerViewController];
    navController.navigationBarHidden = true;
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navController animated:true completion:^{
        
    }];
}
-(void) loaduploadManager : (NSURL *)filePath
{
     snapShotsDict = [self displayIphoneCameraSnapShots];
    upload *uploadManager =[[upload alloc]init];
    uploadManager.snapShots = snapShotsDict;
    
   uploadManager.shotDict = ShotsDict;

    uploadManager.media = @"video";
    NSLog(@"%@", filePath);
    uploadManager.videoPath =filePath;
    [uploadManager uploadMedia];
   
}
-(void) loaduploadManagerForImage
{
    snapShotsDict = [self displayIphoneCameraSnapShots];
    upload *uploadManager =[[upload alloc]init];
    uploadManager.snapShots = snapShotsDict;
    uploadManager.shotDict = ShotsDict;
    uploadManager.media = @"image";
    [uploadManager uploadMedia];
}
-(void) loadStreamsGalleryView
{
    UIStoryboard *streamingStoryboard = [UIStoryboard storyboardWithName:@"Streaming" bundle:nil];
    StreamsGalleryViewController *streamsGalleryViewController = [streamingStoryboard instantiateViewControllerWithIdentifier:@"StreamsGalleryViewController"];
    [self.navigationController pushViewController:streamsGalleryViewController animated:false];
}

-(void)showFlashImage:(BOOL)show
{
    if (show) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.flashButton.hidden = false;
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.flashButton.hidden = true;
        });
    }
    
}


-(BOOL) isStreamStarted
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return  [defaults boolForKey:@"StartedStreaming"];//defaults.boolForKey("StartedStreaming")
}

#pragma mark : VCSessionState Delegate
- (void) connectionStatusChanged:(VCSessionState) state
{

    switch(state) {
            
        case VCSessionStateStarting:
            NSLog(@"Connecting");
            break;
        case VCSessionStateStarted:
            [self hideProgressBar];
            NSLog(@"Disconnect");
            break;
        case VCSessionStateEnded:
            [[NSUserDefaults standardUserDefaults] setValue:false forKey:@"StartedStreaming"];
             [_iphoneCameraButton setImage:[UIImage imageNamed:@"iphone"] forState:UIControlStateNormal];
            NSLog(@"End Stream");
            break;
        case VCSessionStateError:
            [[NSUserDefaults standardUserDefaults] setValue:false forKey:@"StartedStreaming"];
         //   [[ErrorManager sharedInstance] alert:@"Error" message:@"Send Invalid Request"];
            [_iphoneCameraButton setImage:[UIImage imageNamed:@"iphone"] forState:UIControlStateNormal];
            [liveStreaming stopStreamingClicked];
            NSLog(@"VCSessionStateError");
            break;
        default:
            NSLog(@"Connect");
            break;
    }
}



#pragma mark :- StreamingProtocol delegates

-(void)cameraSelectionMode:(SnapCamSelectionMode)selectionMode
{
    _snapCamMode = selectionMode;
}

-(SnapCamSelectionMode)getCameraSelectionMode
{
    return _snapCamMode;
}

#pragma mark :- Private Methods

-(void)startLiveStreaming
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    /*
     rtmp://stream.ioncameras.com:1935/live/stream?ionlive&ion#Ca7hDec11%Live;
     rtmp://stream.ioncameras.com:1935/live?ionlive&ion#Ca7hDec11%Live/stream
     rtmp://stream.ioncameras.com:1935/live/stream?username=ionlive&password=ion#Ca7hDec11%Live
     rtmp://stream.ioncameras.com:1935/live?username=ionlive&password=ion#Ca7hDec11%Live/stream
     */
    
NSString * url  = @"rtsp://192.168.16.33:1935/live";
    
//NSString * url  = @"rtmp://stream.ioncameras.com:1935/live?ionlive&ion#Ca7hDec11%Live";
//NSString * url  = @"rtmp://stream.ioncameras.com:1935/live";
//NSString * url  = @"rtmp://stream.ioncameras.com:1935/live?username=ionlive&password=ion#Ca7hDec11%Live";
//    NSDate * now = [NSDate date];
//    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
//    [outputFormatter setDateFormat:@"HH:mm:ss"];
//    NSString *streamName = [outputFormatter stringFromDate:now];
//    NSString * url = @"rtsp://192.168.16.33:1935/live";+
//    NSString * url = @"rtsp://ionlive:ion#Ca7hDec11%Live@stream.ioncameras.com:1935/live";
//    NSString * url = @"rtsp://priyesh:priyesh@192.168.16.33:1935/live";
    
    [_liveSteamSession startRtmpSessionWithURL:url andStreamKey:@"iPhoneliveStreaming"];
}

-(void)stopLiveStreaming
{
    NSInteger shutterActionMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"shutterActionMode"];
    if (shutterActionMode == SnapCamSelectionModeLiveStream)
    {
        switch(_liveSteamSession.rtmpSessionState) {
            case VCSessionStateNone:
            case VCSessionStatePreviewStarted:
            case VCSessionStateEnded:
            case VCSessionStateError:
                break;
            default:
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [_liveSteamSession endRtmpSession];
                break;
        }
    }
    
}

-(void)configureCameraSettings
{
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult = AVCamSetupResultSuccess;
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult != AVCamSetupResultSuccess ) {
            return;
        }
        
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [IPhoneCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if ( ! videoDeviceInput ) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                // can only be manipulated on the main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                // -[viewWillTransitionToSize:withTransitionCoordinator:].
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
                previewLayer.connection.videoOrientation = initialVideoOrientation;
            } );
        }
        else {
            NSLog( @"Could not add video device input to the session" );
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if ( ! audioDeviceInput ) {
            NSLog( @"Could not create audio device input: %@", error );
        }
        
        if ( [self.session canAddInput:audioDeviceInput] ) {
            [self.session addInput:audioDeviceInput];
        }
        else {
            NSLog( @"Could not add audio device input to the session" );
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ( [self.session canAddOutput:movieFileOutput] ) {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ( connection.isVideoStabilizationSupported ) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        else {
            NSLog( @"Could not add movie file output to the session" );
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ( [self.session canAddOutput:stillImageOutput] ) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
        }
        else {
            NSLog( @"Could not add still image output to the session" );
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    } );
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

# pragma mark:- Thumbnail generator

- (UIImage *)thumbnaleImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    //crop uper and lower part
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSData *)thumbnailFromVideoAtURL:(NSURL *)contentURL {
    UIImage *theImage = nil;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:contentURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generator copyCGImageAtTime:time actualTime:NULL error:&err];
    theImage = [[UIImage alloc] initWithCGImage:imgRef];
    CGImageRelease(imgRef);
    NSData *imageData = [[NSData alloc] init];
    imageData = UIImageJPEGRepresentation(theImage, 1.0);
    // get image cropped from to and bottom
    return imageData;
}
-(NSData *)getThumbNail:(NSURL*)stringPath
{
    UIImage *firstImage =[[UIImage alloc] init];
   // AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:stringPath options:nil];
    //stringPath is a path of stored video file from document directory
    NSURL *videoURL = [NSURL fileURLWithPath:[stringPath path]];
    AVPlayerItem *SelectedItem = [AVPlayerItem playerItemWithURL:stringPath];
    
    CMTime duration = SelectedItem.duration;
    float seconds = CMTimeGetSeconds(duration);
    NSLog(@"duration: %.2f", seconds);
    AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:stringPath options:nil];
    AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
    generate1.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(0.0,600);
    CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *one = [[UIImage alloc] initWithCGImage:oneRef];
   
    UIImage *result  =  [self drawImage:[UIImage imageNamed:@"Circled Play"] inImage:one atPoint:CGPointMake(50, 50)];

    NSData *imageData = [[NSData alloc] init];
    imageData = UIImageJPEGRepresentation(result,1.0);
    // get image cropped from to and bottom
    return imageData;
   // return theImage;
}




@end
