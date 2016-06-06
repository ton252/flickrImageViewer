//
//  APModelManager.m
//  APFlickrImageViewer
//
//  Created by ton252 on 05.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "APModelManager.h"
#import "APImage+CoreDataProperties.h"

@interface APModelManager ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;

@end

@implementation APModelManager

#pragma mark APImage methods

- (APImage *)createAPImageFrom:(NSDictionary *) dictionary
                      withData:(NSData *) data {
    
    NSString *title = [dictionary objectForKey:@"title"];
    NSNumber *longitude = [NSNumber numberWithFloat:[[dictionary objectForKey:@"longitude"] floatValue]];
    NSNumber *latitude = [NSNumber numberWithFloat:[[dictionary objectForKey:@"latitude"] floatValue]];
    NSNumber *imageID = [NSNumber numberWithInteger:[[dictionary objectForKey:@"id"] integerValue]];
    NSNumber *farm = [dictionary objectForKey:@"farm"];
    NSString *owner = [dictionary objectForKey:@"owner"];
    NSString *secret = [dictionary objectForKey:@"secret"];
    NSString *server = [dictionary objectForKey:@"server"];
    
    if (title && longitude && latitude && imageID && data && farm && secret && server && title && owner) {
        
        APImage *image = [self getAPImageWithID:imageID.integerValue];
        
        if (!image) {
            image = [NSEntityDescription insertNewObjectForEntityForName:@"APImage"
                                                  inManagedObjectContext:self.rootSavingContext];
        }
        
        image.title = title;
        image.image_id = imageID;
        image.latitude = latitude;
        image.longitude = longitude;
        image.farm = farm;
        image.owner = owner;
        image.secret = secret;
        image.server = server;
        image.data = data;
        
        [[APModelManager defaultManager] saveRootContext];
        
        return image;
    }
    
    return nil;
}

- (APImage *)getAPImageWithID:(NSInteger) imageID {
    NSString *idSTR = [NSString stringWithFormat: @"%ld", (long)imageID];

    return [self getAPImageWithAtribute:@"image_id" value:idSTR];
}

- (APImage *)getAPImageInContextWithID:(NSInteger) imageID {
    NSString *idSTR = [NSString stringWithFormat: @"%ld", (long)imageID];

    return [self getAPImageWithAtributeInContext:@"image_id" value:idSTR];
}

- (APImage *)getAPImageWithAtribute:(NSString *) atribute value:(NSString *) value {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", atribute,value];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"APImage" inManagedObjectContext:self.managedObjectContext]];
    [request setPredicate:predicate];
    
    NSArray *results = [self.rootSavingContext executeFetchRequest:request error:nil];
    
    return [results firstObject];
}

- (APImage *)getAPImageWithAtributeInContext:(NSString *) atribute value:(NSString *) value{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", atribute,value];
    NSSet *objects = [self.rootSavingContext insertedObjects];
    APImage *image = [[[objects filteredSetUsingPredicate:predicate] allObjects] firstObject];
    return image;
}

- (void)getAllImages:(void (^)(NSArray *images)) complitionBlock{
    __weak typeof(self) weakSelf = self;
    [self.rootSavingContext performBlock:^{
            NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"APImage"];
            NSArray *images  = [weakSelf.rootSavingContext executeFetchRequest:request error:nil];
            complitionBlock(images);
    }];

    //return [self.rootSavingContext executeFetchRequest:request error:nil];
}


- (void)removeAllImages {
    
    [self getAllImages:^(NSArray *images) {
        for (APImage *image in images){
            [self.rootSavingContext deleteObject:image];
        }
    }];
    
//    NSArray *images = [self getAllImages];
//    for (APImage *image in images){
//        [self.rootSavingContext performBlock:^{
//            [self.rootSavingContext deleteObject:image];
//        }];
//    }
    
}

#pragma mark Initialization methods

+ (instancetype)defaultManager {
    static APModelManager* manager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[APModelManager alloc] init];
        [manager createContext];
    });
    
    return manager;
}


- (void)createContext {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"APFlickrImageViewer" withExtension:@"momd"];
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSPersistentStoreCoordinator *psc =  [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        
        NSURL *doсURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [doсURL URLByAppendingPathComponent:@"APFlickrImageViewer.sqlite"];
        NSError *error = nil;
        [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                    URL:storeURL
                                options:nil
                                  error:&error];
        
        _rootSavingContext = [[NSManagedObjectContext alloc]  initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_rootSavingContext setPersistentStoreCoordinator:psc];        
    });
}

- (void)saveRootContext {
    if (_rootSavingContext.hasChanges) {
        [_rootSavingContext performBlock:^{
            NSError *error = nil;
            [_rootSavingContext save:&error];
        }];
    }
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ton252.APFlickrImageViewer" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"APFlickrImageViewer" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"APFlickrImageViewer.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end


