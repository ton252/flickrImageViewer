//
//  APModelManager.h
//  APFlickrImageViewer
//
//  Created by ton252 on 05.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class APImage;

@interface APModelManager : NSObject

+ (instancetype)defaultManager;

@property(strong,nonatomic)NSManagedObjectContext *rootSavingContext;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveRootContext;

- (APImage *)createAPImageFrom:(NSDictionary *) dictionary
                      withData:(NSData *) data;
- (APImage *)getAPImageWithAtribute:(NSString *) atribute value:(NSString *) value;
- (APImage *)getAPImageInContextWithID:(NSInteger) imageID;
- (APImage *)getAPImageWithID:(NSInteger) imageID;

- (void)getAPImageWithID:(NSInteger) imageID completition:(void (^)(APImage *)) completitionBlock;
- (void)getAllImages:(void (^)(NSArray * images)) completitionBlock;
- (void)removeAllImages;


@end
