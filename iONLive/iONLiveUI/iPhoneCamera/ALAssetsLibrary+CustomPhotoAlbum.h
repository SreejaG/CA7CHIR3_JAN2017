
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface ALAssetsLibrary (CustomPhotoAlbum)

- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
       completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)saveVideo:(NSURL *)videoUrl
          toAlbum:(NSString *)albumName
       completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)saveImageData:(NSData *)imageData
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
           completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
              failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)addAssetURL:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
         completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
            failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (void)loadAssetsForProperty:(NSString *)property
                    fromAlbum:(NSString *)albumName
                   completion:(void (^)(NSMutableArray *array, NSError *error))completion;

- (void)loadImagesFromAlbum:(NSString *)albumName
                 completion:(void (^)(NSMutableArray *images, NSError *error))completion;

@end
