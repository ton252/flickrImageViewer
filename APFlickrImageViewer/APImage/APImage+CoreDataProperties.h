//
//  APImage+CoreDataProperties.h
//  APFlickrImageViewer
//
//  Created by ton252 on 05.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "APImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface APImage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, retain) NSNumber *farm;
@property (nullable, nonatomic, retain) NSNumber *image_id;
@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSString *server;
@property (nullable, nonatomic, retain) NSString *secret;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *owner;

@end

NS_ASSUME_NONNULL_END
