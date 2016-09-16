
#import <UIKit/UIKit.h>

@class KxMovieDecoder;

extern NSString * const KxMovieParameterMinBufferedDuration;    // Float
extern NSString * const KxMovieParameterMaxBufferedDuration;    // Float
extern NSString * const KxMovieParameterDisableDeinterlacing;   // BOOL

@interface MovieViewController : UIViewController < NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate >

+ (id) movieViewControllerWithContentPath: (NSString *) path
                               parameters: (NSDictionary *) parameters
                                liveVideo:(BOOL) live;

+ (id) movieViewControllerWithImageVideo: (NSString *) mediaUrl
                                channelName: (NSString *) channelName
                                channelId: (NSString *) channelId
                                userName: (NSString *) userName
                                mediaType: (NSString *) mediaType
                                profileImage: (UIImage *) profileImage
                                VideoImageUrl: (UIImage *) VideoImageUrl
                                notifType: (NSString *) notifType
                                 mediaId: (NSString *) mediaId
                                timeDiff: (NSString *) timeDiff
                               likeCountStr: (NSString *) likeCountStr;

-(void) successFromSetUpView:( NSString *) count;
-(void) closeView;
-(void) mediaDeletedErrorMessage;

@property (readonly) BOOL playing;

@end
