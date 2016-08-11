
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

#if !__has_feature(objc_arc)
#error This class requires automatic reference counting (ARC).
#endif

@interface ALAssetsLibrary (Private)

- (ALAssetsLibraryWriteImageCompletionBlock)_resultBlockOfAddingToAlbum:(NSString *)albumName
                                                             completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
                                                                failure:(ALAssetsLibraryAccessFailureBlock)failure;

- (ALAssetsLibraryAssetForURLResultBlock)_assetForURLResultBlockWithGroup:(ALAssetsGroup *)group
                                                                 assetURL:(NSURL *)assetURL
                                                               completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
                                                                  failure:(ALAssetsLibraryAccessFailureBlock)failure;

@end


@implementation ALAssetsLibrary (CustomPhotoAlbum)

#pragma mark - Private Method

- (ALAssetsLibraryWriteImageCompletionBlock)_resultBlockOfAddingToAlbum:(NSString *)albumName
                                                             completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
                                                                failure:(ALAssetsLibraryAccessFailureBlock)failure
{
  return ^(NSURL *assetURL, NSError *error) {
    if (error != nil) {
      if (failure) failure(error);
      return;
    }
    
    [self addAssetURL:assetURL
              toAlbum:albumName
           completion:completion
              failure:failure];
  };
}

- (ALAssetsLibraryAssetForURLResultBlock)_assetForURLResultBlockWithGroup:(ALAssetsGroup *)group
                                                                 assetURL:(NSURL *)assetURL
                                                               completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
                                                                  failure:(ALAssetsLibraryAccessFailureBlock)failure
{
  return ^(ALAsset *asset) {
    if ([group addAsset:asset]) {
      if (completion) completion(assetURL, nil);
    }
    else {
      NSString * message = [NSString stringWithFormat:@"ALAssetsGroup failed to add asset: %@.", asset];
      if (failure) failure([NSError errorWithDomain:@"LIB_ALAssetsLibrary_CustomPhotoAlbum"
                                               code:0
                                           userInfo:@{NSLocalizedDescriptionKey : message}]);
    }
  };
}

#pragma mark - Public Method

- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
       completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure
{
  [self writeImageToSavedPhotosAlbum:image.CGImage
                         orientation:(ALAssetOrientation)image.imageOrientation 
                     completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                            completion:completion
                                                               failure:failure]];
}

- (void)saveVideo:(NSURL *)videoUrl
          toAlbum:(NSString *)albumName
       completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
          failure:(ALAssetsLibraryAccessFailureBlock)failure
{
    [self writeVideoAtPathToSavedPhotosAlbum:videoUrl
                             completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                    completion:completion
                                                                       failure:failure]];
}

- (void)saveImageData:(NSData *)imageData
              toAlbum:(NSString *)albumName
             metadata:(NSDictionary *)metadata
           completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
              failure:(ALAssetsLibraryAccessFailureBlock)failure
{
  [self writeImageDataToSavedPhotosAlbum:imageData
                                metadata:metadata
                         completionBlock:[self _resultBlockOfAddingToAlbum:albumName
                                                                completion:completion
                                                                   failure:failure]];
}

- (void)addAssetURL:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
         completion:(ALAssetsLibraryWriteImageCompletionBlock)completion
            failure:(ALAssetsLibraryAccessFailureBlock)failure
{
  __block BOOL albumWasFound = NO;
  
    ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock;
    enumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {
    if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
      albumWasFound = YES;
      
      ALAssetsLibraryAssetForURLResultBlock assetForURLResultBlock =
        [self _assetForURLResultBlockWithGroup:group
                                      assetURL:assetURL
                                    completion:completion
                                       failure:failure];
      [self assetForURL:assetURL
            resultBlock:assetForURLResultBlock
           failureBlock:failure];
      
      *stop = YES;
    }
    
    if (group == nil && albumWasFound == NO) {
      ALAssetsLibrary * __weak weakSelf = self;
      
      void(^addPhotoToLibraryBlock)(ALAssetsGroup *group) = ^void(ALAssetsGroup *group) {
        ALAssetsLibraryAssetForURLResultBlock assetForURLResultBlock =
        [weakSelf _assetForURLResultBlockWithGroup:group
                                          assetURL:assetURL
                                        completion:completion
                                           failure:failure];
        [weakSelf assetForURL:assetURL
                  resultBlock:assetForURLResultBlock
                 failureBlock:failure];
      };
      
      if (! [self respondsToSelector:@selector(addAssetsGroupAlbumWithName:resultBlock:failureBlock:)]) {
        NSLog(@"%s: WARNING: |-addAssetsGroupAlbumWithName:resultBlock:failureBlock:| \
              only available on iOS 5.0 or later. Asset cannot be saved to album.", __PRETTY_FUNCTION__);
      }
      else {
        Class PHPhotoLibrary_class = NSClassFromString(@"PHPhotoLibrary");
        
        if (PHPhotoLibrary_class) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
          id sharedPhotoLibrary = [PHPhotoLibrary_class performSelector:NSSelectorFromString(@"sharedPhotoLibrary")];
#pragma clang diagnostic pop
          
          BOOL shouldInvokeSuccessBlockInMainThread = ([NSThread currentThread] == [NSThread mainThread]);
          
          SEL performChanges;
          if (shouldInvokeSuccessBlockInMainThread) {
            performChanges = NSSelectorFromString(@"performChangesAndWait:error:");
          } else {
            performChanges = NSSelectorFromString(@"performChanges:completionHandler:");
          }
          
          NSMethodSignature * methodSignature = [sharedPhotoLibrary methodSignatureForSelector:performChanges];
          
          NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
          [invocation setTarget:sharedPhotoLibrary];
          [invocation setSelector:performChanges];
          
          void (^changeBlock)() = ^{
            Class PHAssetCollectionChangeRequest_class = NSClassFromString(@"PHAssetCollectionChangeRequest");
            SEL creationRequestForAssetCollectionWithTitle = NSSelectorFromString(@"creationRequestForAssetCollectionWithTitle:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [PHAssetCollectionChangeRequest_class performSelector:creationRequestForAssetCollectionWithTitle withObject:albumName];
#pragma clang diagnostic pop
          };
          [invocation setArgument:&changeBlock atIndex:2];
          
          void (^blockToEnumerateGroups)() = ^{
            [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                  if (group) {
                                    NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
                                    if ([albumName isEqualToString:name]) {
                                      addPhotoToLibraryBlock(group);
                                    }
                                  }
                                }
                              failureBlock:failure];
          };
          
          if (shouldInvokeSuccessBlockInMainThread) {
            NSError * error = nil;
            [invocation setArgument:&error atIndex:3];
            [invocation invoke];
            
              BOOL createAlbumSucceed;
            [invocation getReturnValue:&createAlbumSucceed];
            
            if (createAlbumSucceed) {
              blockToEnumerateGroups();
            } else {
              if (error) {
                NSLog(@"%s: Error creating album (%@) :  %@",
                      __PRETTY_FUNCTION__, albumName, [error localizedDescription]);
              }
            }
          }
          else {
            void (^completionHandler)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
              if (success) {
                blockToEnumerateGroups();
              } else {
                if (error) {
                  NSLog(@"%s: Error creating album (%@) : %@",
                        __PRETTY_FUNCTION__, albumName, [error localizedDescription]);
                }
              }
            };
            [invocation setArgument:&completionHandler atIndex:3];
            [invocation invoke];
          }
        }
        else {
          [self addAssetsGroupAlbumWithName:albumName
                                resultBlock:addPhotoToLibraryBlock
                               failureBlock:failure];
        }
      }
      *stop = YES;
    }
  };

  [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                      usingBlock:enumerationBlock
                    failureBlock:failure];
}

- (void)loadAssetsForProperty:(NSString *)property
                    fromAlbum:(NSString *)albumName
                   completion:(void (^)(NSMutableArray *, NSError *))completion
{
  ALAssetsLibraryGroupsEnumerationResultsBlock block = ^(ALAssetsGroup *group, BOOL *stop) {
    if (group == nil) {
      *stop = YES;
      return;
    }
    
    if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
      NSMutableArray * array = [[NSMutableArray alloc] init];
      [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (! result) return;
        
        [array addObject:(property ? ([result valueForProperty:property] ?: [NSNull null]) : result)];
      }];
      
      if (completion) completion(array, nil);
      *stop = YES;
    }
  };
  
  ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    if (completion) completion(nil, error);
  };
  
  [self enumerateGroupsWithTypes:ALAssetsGroupAll
                      usingBlock:block
                    failureBlock:failureBlock];
}

- (void)loadImagesFromAlbum:(NSString *)albumName
                 completion:(void (^)(NSMutableArray *, NSError *))completion
{
  ALAssetsLibraryGroupsEnumerationResultsBlock block = ^(ALAssetsGroup *group, BOOL *stop) {
    if (group == nil) {
      *stop = YES;
      return;
    }
    
    if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
      NSMutableArray * images = [[NSMutableArray alloc] init];
      [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (! result) return;
        UIImageOrientation orientation =
          (UIImageOrientation)[[result valueForProperty:@"ALAssetPropertyOrientation"] intValue];
        UIImage * image = [UIImage imageWithCGImage:[[result defaultRepresentation] fullScreenImage]
                                              scale:1.0
                                        orientation:orientation];
        [images addObject:image];
      }];
      
      if (completion) completion(images, nil);
      *stop = YES;
    }
  };
  
  ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    if (completion) completion(nil, error);
  };
  
  [self enumerateGroupsWithTypes:ALAssetsGroupAll
                      usingBlock:block
                    failureBlock:failureBlock];
}

@end
