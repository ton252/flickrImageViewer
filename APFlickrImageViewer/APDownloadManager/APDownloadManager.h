//
//  APDownloadManager.h
//  coredata
//
//  Created by ton252 on 02.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
@class APImage;
@protocol APDownloadManagerDelegate;

@interface APDownloadManager : NSObject

@property(weak,nonatomic)id<APDownloadManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)downloadImagesWithTags:(NSString *)tags
                      location:(CLLocationCoordinate2D)coordinates
                        radius:(CLLocationDistance)radius
                maxImagesCount:(NSInteger)imagesCount
                       success:(void (^)(APImage *image, NSDictionary *info))success
                       failure:(void (^)(NSError *error, NSDictionary *info))failure
             completionHandler:(void (^)(NSArray *images))completionHandler;

- (void)cancelTasks;

@end

@protocol APDownloadManagerDelegate <NSObject>

@optional

-(void)finishLoading;

@end