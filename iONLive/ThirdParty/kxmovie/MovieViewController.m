//
//  MovieViewController.m
//  LiveStreamingKXMovie
//
//  Created by Vinitha on 11/20/15.
//  Copyright © 2015 Vinitha K S. All rights reserved.
//

#import "MovieViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import "KxMovieDecoder.h"
#import "KxAudioManager.h"
#import "KxMovieGLView.h"
#import "KxLogger.h"

NSString * const KxMovieParameterMinBufferedDuration = @"KxMovieParameterMinBufferedDuration";
NSString * const KxMovieParameterMaxBufferedDuration = @"KxMovieParameterMaxBufferedDuration";
NSString * const KxMovieParameterDisableDeinterlacing = @"KxMovieParameterDisableDeinterlacing";

////////////////////////////////////////////////////////////////////////////////

static NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);
    
    NSInteger s = seconds;
    NSInteger m = s / 60;
    NSInteger h = m / 60;
    
    s = s % 60;
    m = m % 60;
    
    NSMutableString *format = [(isLeft && seconds >= 0.5 ? @"-" : @"") mutableCopy];
    if (h != 0) [format appendFormat:@"%d:%0.2d", h, m];
    else        [format appendFormat:@"%d", m];
    [format appendFormat:@":%0.2d", s];
    
    return format;
}

////////////////////////////////////////////////////////////////////////////////

enum {
    
    KxMovieInfoSectionGeneral,
    KxMovieInfoSectionVideo,
    KxMovieInfoSectionAudio,
    KxMovieInfoSectionSubtitles,
    KxMovieInfoSectionMetadata,
    KxMovieInfoSectionCount,
};

enum {
    
    KxMovieInfoGeneralFormat,
    KxMovieInfoGeneralBitrate,
    KxMovieInfoGeneralCount,
};

////////////////////////////////////////////////////////////////////////////////

static NSMutableDictionary * gHistory;

#define LOCAL_MIN_BUFFERED_DURATION   0.2
#define LOCAL_MAX_BUFFERED_DURATION   0.4
#define NETWORK_MIN_BUFFERED_DURATION 2.0
#define NETWORK_MAX_BUFFERED_DURATION 4.0

@interface MovieViewController ()
{
    
    IBOutlet UIImageView *imageView;
    IBOutlet UIView *topView;
    IBOutlet KxMovieGLView *glView;
    IBOutlet UIView *mainView;
    IBOutlet UIView *bottomView;
    IBOutlet UIButton *topViewButton;
    IBOutlet UIButton *backButton;
    IBOutlet UIButton *uploadStream;
    IBOutlet UIButton *cameraButton;

    BOOL                _interrupted;
    
    KxMovieDecoder      *_decoder;
    dispatch_queue_t    _dispatchQueue;
    NSMutableArray      *_videoFrames;
    NSMutableArray      *_audioFrames;
    NSData              *_currentAudioFrame;
    NSUInteger          _currentAudioFramePos;
    CGFloat             _moviePosition;
    BOOL                _disableUpdateHUD;
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    NSUInteger          _tickCounter;
//    BOOL                _fullscreen;
//    BOOL                _hiddenHUD;
    BOOL                _fitMode;
    BOOL                _infoMode;
    BOOL                _restoreIdleTimer;
    BOOL                _liveVideo;

    CGFloat             _bufferedDuration;
    CGFloat             _minBufferedDuration;
    CGFloat             _maxBufferedDuration;
    BOOL                _buffered;
    IBOutlet UIActivityIndicatorView *_activityIndicatorView;
    
    BOOL                _savedIdleTimer;
    
    NSDictionary        *_parameters;
    
    //Should be removed
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    UITapGestureRecognizer *_doubleTapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;


}

@property (readwrite) BOOL playing;
@property (readwrite) BOOL decoding;
@property (readwrite, strong) KxArtworkFrame *artworkFrame;

@end


@implementation MovieViewController

+ (void)initialize
{
    if (!gHistory)
        gHistory = [NSMutableDictionary dictionary];
}
- (IBAction)touchBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (BOOL)prefersStatusBarHidden { return YES; }

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                liveVideo:(BOOL)live
{
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];
    [audioManager activateAudioSession];
        return [[MovieViewController alloc] initWithContentPath: path parameters: parameters liveVideo:live];
}

- (id) initWithContentPath: (NSString *) path
                parameters: (NSDictionary *) parameters
                 liveVideo:(BOOL)live

{
    self = [super initWithNibName:@"MovieViewController" bundle:nil];

    if (self) {
        _liveVideo = live;

        _parameters = nil;
        
        __weak MovieViewController *weakSelf = self;
        
        KxMovieDecoder *decoder = [[KxMovieDecoder alloc] init];
        
        decoder.interruptCallback = ^BOOL(){
            
            __strong MovieViewController *strongSelf = weakSelf;
            return strongSelf ? [strongSelf interruptDecoder] : YES;
        };
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSError *error = nil;
            [decoder openFile:path error:&error];
            
            __strong MovieViewController *strongSelf = weakSelf;
            if (strongSelf) {
                
                dispatch_sync(dispatch_get_main_queue(), ^{

                    [strongSelf setMovieDecoder:decoder withError:error];
                });
            }
        });
    }
    return self;
}

- (void) dealloc
{
    [self pause];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (_dispatchQueue) {
        // Not needed as of ARC.
        //        dispatch_release(_dispatchQueue);
        _dispatchQueue = NULL;
    }

    LoggerStream(1, @"%@ dealloc", self);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setUpInitialView];
    [self customizeUploadStreamButton];

    if (_decoder) {

        [self setupPresentView];
    }
}

-(void)setUpInitialView
{
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];
    [topView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.4]];
    topView.hidden = true;
    bottomView.hidden = true;
}

-(void)setUpViewForLiveAndStreaming
{
    if (_liveVideo == true) {
        [self customiseViewForLive];
    }
    else
    {
        [self customiseViewForStreaming];
    }
}

-(void)customizeUploadStreamButton
{
    uploadStream.clipsToBounds = YES;
    uploadStream.layer.cornerRadius = 15;
}

-(void)customiseViewForLive
{
    bottomView.hidden = false;
    topView.hidden = false;
    uploadStream.hidden = false;
    topViewButton.hidden = false;
    backButton.hidden = true;
}

-(void)customiseViewForStreaming
{
    uploadStream.hidden = true;
    bottomView.hidden = true;
    topView.hidden = false;
    backButton.hidden = false;
    topViewButton.hidden = true;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:true];

}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if (self.playing) {

        [self pause];
        [self freeBufferedFrames];

        if (_maxBufferedDuration > 0) {

            _minBufferedDuration = _maxBufferedDuration = 0;
            [self play];

            LoggerStream(0, @"didReceiveMemoryWarning, disable buffering and continue playing");

        } else {

            // force ffmpeg to free allocated memory
            [_decoder closeFile];
            [_decoder openFile:nil error:nil];

            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                        message:NSLocalizedString(@"Out of memory", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                              otherButtonTitles:nil] show];
        }

    } else {

        [self freeBufferedFrames];
        [_decoder closeFile];
        [_decoder openFile:nil error:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _savedIdleTimer = [[UIApplication sharedApplication] isIdleTimerDisabled];
    

//TODO make _interrupted No ,click on back button
    _interrupted = NO;
    if (_decoder) {
        
        [self restorePlay];
        
    } else {
        
        [_activityIndicatorView startAnimating];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:[UIApplication sharedApplication]];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [_activityIndicatorView stopAnimating];
    
    if (_decoder) {
        
        [self pause];
        
        if (_moviePosition == 0 || _decoder.isEOF)
            [gHistory removeObjectForKey:_decoder.path];
        else if (!_decoder.isNetwork)
            [gHistory setValue:[NSNumber numberWithFloat:_moviePosition]
                        forKey:_decoder.path];
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_savedIdleTimer];
    
    [_activityIndicatorView stopAnimating];
    _buffered = NO;
    _interrupted = YES;
    
    LoggerStream(1, @"viewWillDisappear %@", self);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) applicationWillResignActive: (NSNotification *)notification
{
    [self pause];
    
    LoggerStream(1, @"applicationWillResignActive");
}

#pragma mark - public

-(void) play
{
    if (self.playing)
        return;

    if (!_decoder.validVideo &&
        !_decoder.validAudio) {

        return;
    }

    if (_interrupted)
        return;

    self.playing = YES;
    _interrupted = NO;
    _disableUpdateHUD = NO;
    _tickCorrectionTime = 0;
    _tickCounter = 0;


    [self asyncDecodeFrames];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self tick];
    });

    if (_decoder.validAudio)
        [self enableAudio:YES];

    LoggerStream(1, @"play movie");
}

- (void) pause
{
    if (!self.playing)
        return;

    self.playing = NO;
    //_interrupted = YES;
    [self enableAudio:NO];
    LoggerStream(1, @"pause movie");
}


#pragma mark - private

- (void) setMovieDecoder: (KxMovieDecoder *) decoder
               withError: (NSError *) error
{
    LoggerStream(2, @"setMovieDecoder");

    if (!error && decoder) {

        _decoder        = decoder;
        _dispatchQueue  = dispatch_queue_create("KxMovie", DISPATCH_QUEUE_SERIAL);
        _videoFrames    = [NSMutableArray array];
        _audioFrames    = [NSMutableArray array];

        if (_decoder.isNetwork) {

            _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;

        } else {

            _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
            _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
        }

        if (!_decoder.validVideo)
            _minBufferedDuration *= 10.0; // increase for audio

        // allow to tweak some parameters at runtime
        if (_parameters.count) {

            id val;

            val = [_parameters valueForKey: KxMovieParameterMinBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _minBufferedDuration = [val floatValue];

            val = [_parameters valueForKey: KxMovieParameterMaxBufferedDuration];
            if ([val isKindOfClass:[NSNumber class]])
                _maxBufferedDuration = [val floatValue];

            val = [_parameters valueForKey: KxMovieParameterDisableDeinterlacing];
            if ([val isKindOfClass:[NSNumber class]])
                _decoder.disableDeinterlacing = [val boolValue];

            if (_maxBufferedDuration < _minBufferedDuration)
                _maxBufferedDuration = _minBufferedDuration * 2;
        }

        LoggerStream(2, @"buffered limit: %.1f - %.1f", _minBufferedDuration, _maxBufferedDuration);

        if (self.isViewLoaded) {

            [self setupPresentView];

            if (_activityIndicatorView.isAnimating) {

                [_activityIndicatorView stopAnimating];
                [self restorePlay];
            }
        }

    } else {

        if (self.isViewLoaded && self.view.window) {

            [_activityIndicatorView stopAnimating];
            if (!_interrupted)
                [self handleDecoderMovieError: error];
        }
    }
}

- (void) restorePlay
{
    [self play];
}

- (void) setupPresentView
{
    BOOL isGlView = false;

    if (_decoder.validVideo) {

        _activityIndicatorView.hidden = true;
        [self setUpViewForLiveAndStreaming];
//        topView.hidden = false;
//        bottomView.hidden = false;
//        cameraButton.hidden = false;
        isGlView = [glView initWithDecoder:_decoder];

        if (isGlView == false)
            glView = nil;
    }

    if (isGlView == false) {

        LoggerVideo(0, @"fallback to use RGB video frame and UIKit");
        [_decoder setupVideoFrameFormat:KxVideoFrameFormatRGB];
    }

    UIView *frameView = [self frameView];

    frameView.contentMode = UIViewContentModeScaleAspectFill;
    frameView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;

    [self.view bringSubviewToFront:frameView];
}

- (UIView *) frameView
{
    return glView ? glView : imageView;
}

- (void) audioCallbackFillData: (float *) outData
                     numFrames: (UInt32) numFrames
                   numChannels: (UInt32) numChannels
{
    //fillSignalF(outData,numFrames,numChannels);
    //return;

    if (_buffered) {
        memset(outData, 0, numFrames * numChannels * sizeof(float));
        return;
    }

    @autoreleasepool {

        while (numFrames > 0) {

            if (!_currentAudioFrame) {

                @synchronized(_audioFrames) {

                    NSUInteger count = _audioFrames.count;

                    if (count > 0) {

                        KxAudioFrame *frame = _audioFrames[0];

#ifdef DUMP_AUDIO_DATA
                        LoggerAudio(2, @"Audio frame position: %f", frame.position);
#endif
                        if (_decoder.validVideo) {

                            const CGFloat delta = _moviePosition - frame.position;

                            if (delta < -0.1) {

                                memset(outData, 0, numFrames * numChannels * sizeof(float));
                                //#ifdef DEBUG
                                //                                LoggerStream(0, @"desync audio (outrun) wait %.4f %.4f", _moviePosition, frame.position);
                                //                                _debugAudioStatus = 1;
                                //                                _debugAudioStatusTS = [NSDate date];
                                //#endif
                                break; // silence and exit
                            }

                            [_audioFrames removeObjectAtIndex:0];

                            if (delta > 0.1 && count > 1) {

                                //#ifdef DEBUG
                                //                                LoggerStream(0, @"desync audio (lags) skip %.4f %.4f", _moviePosition, frame.position);
                                //                                _debugAudioStatus = 2;
                                //                                _debugAudioStatusTS = [NSDate date];
                                //#endif
                                continue;
                            }

                        } else {

                            [_audioFrames removeObjectAtIndex:0];
                            _moviePosition = frame.position;
                            _bufferedDuration -= frame.duration;
                        }

                        _currentAudioFramePos = 0;
                        _currentAudioFrame = frame.samples;
                    }
                }
            }

            if (_currentAudioFrame) {

                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(float);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;

                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;

                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;

            } else {

                memset(outData, 0, numFrames * numChannels * sizeof(float));
                //LoggerStream(1, @"silence audio");
                //#ifdef DEBUG
                //                _debugAudioStatus = 3;
                //                _debugAudioStatusTS = [NSDate date];
                //#endif
                break;
            }
        }
    }
}

- (void) enableAudio: (BOOL) on
{
    id<KxAudioManager> audioManager = [KxAudioManager audioManager];

    if (on && _decoder.validAudio) {

        audioManager.outputBlock = ^(float *outData, UInt32 numFrames, UInt32 numChannels) {

            [self audioCallbackFillData: outData numFrames:numFrames numChannels:numChannels];
        };

        [audioManager play];

        LoggerAudio(2, @"audio device smr: %d fmt: %d chn: %d",
                    (int)audioManager.samplingRate,
                    (int)audioManager.numBytesPerSample,
                    (int)audioManager.numOutputChannels);

    } else {

        [audioManager pause];
        audioManager.outputBlock = nil;
    }
}

- (BOOL) addFrames: (NSArray *)frames
{
    if (_decoder.validVideo) {

        @synchronized(_videoFrames) {

            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeVideo) {
                    [_videoFrames addObject:frame];
                    _bufferedDuration += frame.duration;
                }
        }
    }

    if (_decoder.validAudio) {

        @synchronized(_audioFrames) {

            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeAudio) {
                    [_audioFrames addObject:frame];
                    if (!_decoder.validVideo)
                        _bufferedDuration += frame.duration;
                }
        }

        if (!_decoder.validVideo) {

            for (KxMovieFrame *frame in frames)
                if (frame.type == KxMovieFrameTypeArtwork)
                    self.artworkFrame = (KxArtworkFrame *)frame;
        }
    }

    return self.playing && _bufferedDuration < _maxBufferedDuration;
}

- (BOOL) decodeFrames
{
    //NSAssert(dispatch_get_current_queue() == _dispatchQueue, @"bugcheck");

    NSArray *frames = nil;

    if (_decoder.validVideo ||
        _decoder.validAudio) {

        frames = [_decoder decodeFrames:0];
    }

    if (frames.count) {
        return [self addFrames: frames];
    }
    return NO;
}

- (void) asyncDecodeFrames
{
    if (self.decoding)
        return;

    __weak MovieViewController *weakSelf = self;
    __weak KxMovieDecoder *weakDecoder = _decoder;

    const CGFloat duration = _decoder.isNetwork ? .0f : 0.1f;

    self.decoding = YES;
    dispatch_async(_dispatchQueue, ^{

        {
            __strong MovieViewController *strongSelf = weakSelf;
            if (!strongSelf.playing)
                return;
        }

        BOOL good = YES;
        while (good) {

            good = NO;

            @autoreleasepool {

                __strong KxMovieDecoder *decoder = weakDecoder;

                if (decoder && (decoder.validVideo || decoder.validAudio)) {

                    NSArray *frames = [decoder decodeFrames:duration];
                    if (frames.count) {

                        __strong MovieViewController *strongSelf = weakSelf;
                        if (strongSelf)
                            good = [strongSelf addFrames:frames];
                    }
                }
            }
        }

        {
            __strong MovieViewController *strongSelf = weakSelf;
            if (strongSelf) strongSelf.decoding = NO;
        }
    });
}

- (void) tick
{
    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || _decoder.isEOF)) {

        _tickCorrectionTime = 0;
        _buffered = NO;
        [_activityIndicatorView stopAnimating];
    }

    CGFloat interval = 0;
    if (!_buffered)
        interval = [self presentFrame];

    if (self.playing) {

        const NSUInteger leftFrames =
        (_decoder.validVideo ? _videoFrames.count : 0) +
        (_decoder.validAudio ? _audioFrames.count : 0);

        if (0 == leftFrames) {

            if (_decoder.isEOF) {

                [self pause];
                return;
            }

            if (_minBufferedDuration > 0 && !_buffered) {

                _buffered = YES;
                [_activityIndicatorView startAnimating];
            }
        }

        if (!leftFrames ||
            !(_bufferedDuration > _minBufferedDuration)) {

            [self asyncDecodeFrames];
        }

        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.01);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self tick];
        });
    }

    if ((_tickCounter++ % 3) == 0) {
        //        [self updateHUD];
    }
}

- (CGFloat) tickCorrection
{
    if (_buffered)
        return 0;

    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    if (!_tickCorrectionTime) {

        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }

    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;

    if (correction > 1.f || correction < -1.f) {

        LoggerStream(1, @"tick correction reset %.2f", correction);
        correction = 0;
        _tickCorrectionTime = 0;
    }

    return correction;
}

- (CGFloat) presentFrame
{
    CGFloat interval = 0;

    if (_decoder.validVideo) {

        KxVideoFrame *frame;

        @synchronized(_videoFrames) {

            if (_videoFrames.count > 0) {

                frame = _videoFrames[0];
                [_videoFrames removeObjectAtIndex:0];
                _bufferedDuration -= frame.duration;
            }
        }

        if (frame)
            interval = [self presentVideoFrame:frame];

    } else if (_decoder.validAudio) {

        //interval = _bufferedDuration * 0.5;

        if (self.artworkFrame) {

            imageView.image = [self.artworkFrame asImage];
            self.artworkFrame = nil;
        }
    }

    return interval;
}

- (CGFloat) presentVideoFrame: (KxVideoFrame *) frame
{
    if (glView) {

        [glView render:frame];

    } else {

        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
        imageView.image = [rgbFrame asImage];
    }

    _moviePosition = frame.position;

    return frame.duration;
}
- (IBAction)didTapUploadStream:(id)sender {
    
    [self loadUploadStreamingView];
}

-(void)loadUploadStreamingView
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Streaming" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"UploadStreamViewController"];
    [self.navigationController pushViewController:vc animated:true];
}

- (IBAction)didTapStreamThumb:(id)sender {
    
    [self loadStreamsListView];
}

-(void) loadStreamsListView
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Streaming" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"StreamsListViewController"];
    [self.navigationController pushViewController:vc animated:true];
}

- (void) freeBufferedFrames
{
    @synchronized(_videoFrames) {
        [_videoFrames removeAllObjects];
    }
    
    @synchronized(_audioFrames) {
        
        [_audioFrames removeAllObjects];
        _currentAudioFrame = nil;
    }

    _bufferedDuration = 0;
}

- (void) handleDecoderMovieError: (NSError *) error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
                                                        message:[error localizedDescription]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                              otherButtonTitles:nil];

    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self.navigationController popViewControllerAnimated:true];
    }
}


- (BOOL) interruptDecoder
{
    //if (!_decoder)
    //    return NO;
    return _interrupted;
}

@end