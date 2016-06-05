//
//  APDownloadManager.m
//  coredata
//
//  Created by ton252 on 02.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//
#import "APDownloadManager.h"
//#import "APModelManager.h"

#define MIN_RADIUS 0.f
#define MAX_RADIUS 32000.f
#define VALUE_BORDER(number, lower, upper) ( ((number) < (lower))? (lower) : ( ((number) > (upper) ) ? (upper) : (number) ) ) // Set interval for value  [min < value < max]

#warning message Enter FlickrAPIKey

NSString *const FlickrAPIKey = @"";
NSString *const FlickrImageURL = @"https://farm%@.staticflickr.com/%@/%@_%@.jpg"; //https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
NSString *const FlickrREST = @"https://api.flickr.com/services/rest/";

NSString *const FlickrMETHOD_IMAGESEARCH = @"flickr.photos.search";
NSString *const FlickrMETHOD_GETLOCATION =@"flickr.photos.geo.getLocation";

NSString *const FlickrMETHOD_KEY = @"method";
NSString *const FilckrKEY_API_KEY = @"api_key";
NSString *const FilckrKEY_TAGS = @"tags";
NSString *const FilckrKEY_LAT = @"lat";
NSString *const FilckrKEY_LON =@"lon";
NSString *const FilckrKEY_RADIUS = @"radius";
NSString *const FilckrKEY_FORMAT = @"format";
NSString *const FilckrKEY_PERPAGE = @"per_page";
NSString *const FilckrKEY_JSONCALLBAK = @"nojsoncallback";
NSString *const FilckrKEY_PRIVACYFILTER = @"privacy_filter";
NSString *const FilckrKEY_PHOTOID = @"photo_id";

NSString *const FilckrKEY_LOCATION = @"location";
NSString *const FilckrKEY_LATITUDE = @"latitude";
NSString *const FilckrKEY_LONGITUDE = @"longitude";

NSString *const FilckrKEY_PHOTO = @"photo";
NSString *const FilckrKEY_PHOTOS = @"photos";
NSString *const FilckrKEY_FARMID = @"farm";
NSString *const FilckrKEY_SERVERID = @"server";
NSString *const FilckrKEY_ID = @"id";
NSString *const FilckrKEY_SECRETID = @"secret";

NSString *const APDownloadManagerErrorDomain = @"APDownloadManagerErrorDomain";

@interface APDownloadManager() <NSURLSessionDelegate>

@property(strong,nonatomic) NSURLSession *session;
@property(strong, nonatomic) NSMutableArray<NSURLSessionDownloadTask*> *downloadTasks;

@end

@implementation APDownloadManager

+ (instancetype)sharedManager{
    
    static APDownloadManager* manager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[APDownloadManager alloc] init];
    });
    
    return manager;
    
}

- (instancetype)init{
    
    self = [super init];
    
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 4;
        self.session = [NSURLSession sessionWithConfiguration:config];
        self.downloadTasks = [[NSMutableArray alloc] init];
    }
    
    return self;
    
}


- (NSURLSessionDataTask *)getImagesWihTags:(NSString *) tags
                                  location:(CLLocationCoordinate2D) coordinates
                                    radius:(CLLocationDistance) radius
                            maxImagesCount:(NSInteger) imagesCount
                         completionHandler:(void (^)(NSArray *imagesDict, NSError *error))completionHandler {

    NSString *radiusStr = @(VALUE_BORDER(radius/1000.f,MIN_RADIUS,MAX_RADIUS)).stringValue;
    NSString * tagsStr = [tags stringByReplacingOccurrencesOfString:@" " withString:@","];
    imagesCount = MAX(1,imagesCount);
    
    NSDictionary *parameters = @{FlickrMETHOD_KEY: FlickrMETHOD_IMAGESEARCH,
                                FilckrKEY_API_KEY: FlickrAPIKey,
                                   FilckrKEY_TAGS: tagsStr,
                                    FilckrKEY_LAT: @(coordinates.latitude).stringValue,
                                    FilckrKEY_LON: @(coordinates.longitude).stringValue,
                                 FilckrKEY_RADIUS: radiusStr,
                                FilckrKEY_PERPAGE: @(imagesCount),
                          FilckrKEY_PRIVACYFILTER: @"1",
                                 FilckrKEY_FORMAT: @"json",
                            FilckrKEY_JSONCALLBAK: @"1"};

    NSURL *requestURL = [NSURL URLWithString:[self createURL:FlickrREST withParameters:parameters]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *dataTask =
    [self jsonDataTaskWithRequest:request completionHandler:^(NSDictionary *responseObject, NSError *error) {
        NSError *resultError = error;
        NSArray *resultArray = nil;
        if (!error){
            NSDictionary *photosDict = [responseObject objectForKey:FilckrKEY_PHOTOS];
            if (photosDict) {
                resultArray = [photosDict objectForKey:FilckrKEY_PHOTO];
            }else{
                resultError = [APDownloadManager errorForCode:0];
            }
        }
        if (completionHandler) completionHandler(resultArray,resultError);
    }];
    [dataTask resume];
    
    return dataTask;
    
}

- (NSURLSessionDataTask *)jsonDataTaskWithRequest:(NSURLRequest *)request
                                completionHandler:(void (^)(NSDictionary *responseObject, NSError *error))completionHandler{
    
    NSURLSessionDataTask *dataTask =
    [self.session dataTaskWithRequest:request
                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        NSError *resultError = error;
                        NSDictionary *responseObject = nil;
                        if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                            if ([httpResponse.MIMEType isEqualToString:@"application/json"]){
                                NSError *serializationError = nil;
                                responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                                if (serializationError) resultError = serializationError;
                            } else {
                                error = [APDownloadManager errorForCode:-3];
                            }
                        }else{
                            error = [APDownloadManager errorForCode:-2];
                        }
                        if (completionHandler) completionHandler(responseObject,resultError);
                    }];

    return dataTask;
    
}

- (void)downloadImagesWithTags:(NSString *)tags
                      location:(CLLocationCoordinate2D)coordinates
                        radius:(CLLocationDistance)radius
                maxImagesCount:(NSInteger)imagesCount
                       success:(void (^)(APImage *image, NSDictionary *info))success
                       failure:(void (^)(NSError *error, NSDictionary *info))failure
             completionHandler:(void (^)(NSArray *images))completionHandler{
    
    [self getImagesWihTags:tags location:coordinates radius:radius
            maxImagesCount:imagesCount completionHandler:^(NSArray *imagesDict, NSError *error) {
                if (!error){
                    
                    __block NSMutableArray *resultImages = [[NSMutableArray alloc] init];
                    dispatch_group_t downloadGroup = dispatch_group_create();
                    
                    for (NSDictionary *dict in imagesDict){
                        dispatch_group_enter(downloadGroup);
                        [self getImageLocation:dict
                             completionHandler:^(NSDictionary *imageInfo, NSError *error) {
                                 if (!error){
                                     [self downloadImage:imageInfo completionHandler:^(UIImage *image, NSDictionary *info, NSError *error) {
                                         if (!error){
                                             
#warning message Processing and Preservation of the received data
                                         }else{
                                             if (failure) failure(error,info);
                                         }
                                        dispatch_group_leave(downloadGroup);
                                     }];
                                 }else{
                                     if (failure) failure(error,nil);
                                     dispatch_group_leave(downloadGroup);
                                 }
                         }];
                    }
                    
                    dispatch_group_notify(downloadGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        if (completionHandler) completionHandler([NSArray arrayWithArray:resultImages]);
                    });
                    
                }else{
                    if (failure) failure(error,nil);
                    if (completionHandler) completionHandler(nil);
                }
    }];
    
    
    
}

- (NSURLSessionDataTask *)getImageLocation:(NSDictionary *) imageInfo
                         completionHandler:(void (^)(NSDictionary *imageInfo, NSError *error))completionHandler{
    
    NSString *ID = [imageInfo objectForKey:FilckrKEY_ID];
    if (ID){
        NSDictionary *parameters = @{FlickrMETHOD_KEY: FlickrMETHOD_GETLOCATION,
                                    FilckrKEY_API_KEY: FlickrAPIKey,
                                    FilckrKEY_PHOTOID: ID,
                                     FilckrKEY_FORMAT: @"json" ,
                                FilckrKEY_JSONCALLBAK: @"1"};

        NSURL *requestURL = [NSURL URLWithString:[self createURL:FlickrREST withParameters:parameters]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
        [request setHTTPMethod:@"GET"];
        
        NSURLSessionDataTask *dataTask =
        [self jsonDataTaskWithRequest:request completionHandler:^(NSDictionary *responseObject, NSError *error) {
            NSError *resultError = error;
            NSDictionary *resultImageDict = nil;
            if (!error){
                NSDictionary *imageDict = [[responseObject objectForKey:FilckrKEY_PHOTO] objectForKey:FilckrKEY_LOCATION];
                NSString *latittude = [imageDict objectForKey:FilckrKEY_LATITUDE];
                NSString *longitude = [imageDict objectForKey:FilckrKEY_LONGITUDE];
                    if (latittude && longitude){
                        NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] initWithDictionary:imageInfo];
                        [tmpDict setValue:latittude forKey:FilckrKEY_LATITUDE];
                        [tmpDict setValue:longitude forKey:FilckrKEY_LONGITUDE];
                        resultImageDict = [NSDictionary dictionaryWithDictionary:tmpDict];
                    }else{
                        resultError = [APDownloadManager errorForCode:0];
                    }
            }
            completionHandler(resultImageDict,resultError);
        }];
        [dataTask resume];
        return dataTask;
        
    }else{
        NSError *error = [APDownloadManager errorForCode:0];
        if (completionHandler)completionHandler(nil, error);
    }
    
    return nil;
}


- (NSURLSessionDownloadTask *)downloadImage:(NSDictionary *) imageInfo
                              completionHandler:(void (^)(UIImage *image, NSDictionary *info, NSError *error))completionHandler{
    
    
    NSString *farmID = [imageInfo objectForKey:FilckrKEY_FARMID];
    NSString *serverID = [imageInfo objectForKey:FilckrKEY_SERVERID];
    NSString *ID = [imageInfo objectForKey:FilckrKEY_ID];
    NSString *secretID = [imageInfo objectForKey:FilckrKEY_SECRETID];
    
    if (farmID && serverID && ID && secretID){
        NSString *imgUrl = [NSString stringWithFormat:FlickrImageURL,farmID,serverID,ID,secretID];
        __weak typeof(self)weakSelf = self;
        __block NSURLSessionDownloadTask *dataTask =
        [self.session downloadTaskWithURL:[NSURL URLWithString:imgUrl]
                        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                         UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
                                         if (completionHandler) completionHandler(downloadedImage,imageInfo,error);
                                         @synchronized (weakSelf) {
                                             [weakSelf.downloadTasks removeObject:dataTask];
                                             if (weakSelf.downloadTasks.count == 0){
                                                 if ([weakSelf.delegate respondsToSelector:@selector(finishLoading)]){
                                                    [weakSelf.delegate finishLoading];
                                                 }
                                             }
                                         }
         }];
        @synchronized (self) {
            [self.downloadTasks addObject:dataTask];
        }

        [dataTask resume];
        return dataTask;
    } else{
        NSError *error = [APDownloadManager errorForCode:0];
        if (completionHandler) completionHandler(nil,imageInfo,error);
    }
    
    return nil;
}


- (NSArray *)createImagesURLwithDictionary:(NSDictionary *) parameters{
    
    NSDictionary *photosDict = [parameters objectForKey:FilckrKEY_PHOTOS];
    
    if (photosDict) {
    
        NSArray *array = [photosDict objectForKey:FilckrKEY_PHOTO];
        
        if (array) {
            
            NSMutableArray *imagesURL = [[NSMutableArray alloc] init];
            
            for (NSDictionary *imgDict in array) {
                NSString *farmID = [imgDict objectForKey:FilckrKEY_FARMID];
                NSString *serverID = [imgDict objectForKey:FilckrKEY_SERVERID];
                NSString *ID = [imgDict objectForKey:FilckrKEY_ID];
                NSString *secretID = [imgDict objectForKey:FilckrKEY_SECRETID];
                
                if (farmID && serverID && ID && secretID){
                    NSString *imgUrl = [NSString stringWithFormat:FlickrImageURL,farmID,serverID,ID,secretID];
                    [imagesURL addObject:imgUrl];
                }
            }
            
            return [NSArray arrayWithArray:imagesURL];
        }
    }
    
    return nil;
}


- (NSString *)createURL:(NSString *) url withParameters:(NSDictionary *) parameters{
    
    for (int i =0; i < parameters.allKeys.count; i++){
        NSString *key = parameters.allKeys[i];
        if (i == 0){
            url = [NSString stringWithFormat:@"%@?%@=%@",url,key,[parameters objectForKey:key]];
        }else{
            url = [NSString stringWithFormat:@"%@&%@=%@",url,key,[parameters objectForKey:key]];
        }
    }
    
    return url;
}

- (void)cancelTasks {
    
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionTask *task in dataTasks) {
            [task cancel];
        }
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            [task cancel];
        }
    }];
}

+ (NSError *)errorForCode:(NSInteger) code{
    
    NSError *error = nil;
    
    switch (code){
        case -2:{
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Request failed: unacceptable response-type", nil),
                                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Request failed: unacceptable response-type", nil),
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)};
            
            error = [NSError errorWithDomain:APDownloadManagerErrorDomain code:code userInfo:userInfo];
            break;
        }case -3:{
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Request failed: unacceptable content-type", nil),
                                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Request failed: unacceptable content-type", nil),
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)};
            error = [NSError errorWithDomain:APDownloadManagerErrorDomain code:code userInfo:userInfo];
            break;
        }default:{
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Request failed: Unknown error", nil),
                                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Request failed: Unknown error", nil),
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Something was wrong", nil)};
            error = [NSError errorWithDomain:APDownloadManagerErrorDomain code:-1 userInfo:userInfo];
            
            break;
        }
    }
    
    return error;
}



@end
