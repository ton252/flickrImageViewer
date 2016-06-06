//
//  MapViewController.m
//  APFlickrImageViewer
//
//  Created by ton252 on 05.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "APDownloadManager.h"
#import "APImage+CoreDataProperties.h"
#import "APPointAnnotation.h"
#import "APModelManager.h"
#import "APImageViewController.h"

@interface MapViewController()<CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate, APDownloadManagerDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *radiusLabel;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property(strong, nonatomic) CLLocationManager *locationManager;


@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (assign, nonatomic, getter = isLocationUpdated) BOOL locationUpdated;
@property (assign, nonatomic) float radius;


@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self defaultSettings];
    [self setupLocationManager];
    [self restoreUserData];
}

- (void)defaultSettings{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.mapView.delegate = self;
    self.searchBar.delegate = self;
    [[APDownloadManager sharedManager] setDelegate:self];
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];
    [self.mapView addGestureRecognizer:tapGesture];
    
    self.activityIndicator.hidesWhenStopped = YES;
    
    [self cancelButton:self.searchBar enable:YES];


}

#pragma mark Networking

- (void)startLoading {
    [self.loadingView  setHidden:NO];
    [self.activityIndicator startAnimating];
}

- (void)stopLoading {
    [self.loadingView  setHidden:YES];
    [self.activityIndicator stopAnimating];
    self.radius = self.radius;
}

- (void)requestImages {
    [self startLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[APDownloadManager sharedManager] downloadImagesWithTags:self.searchBar.text
                                                     location:self.mapView.userLocation.location.coordinate
                                                       radius:self.radius
                                               maxImagesCount:100
                                                      success:^(APImage *image, NSDictionary *info) {
                                                          [self locatePoint:image];
                                                      }failure:nil
                                            completionHandler:^(NSArray *images){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                    if (images.count == 0){
                                                        UIAlertView *alert =
                                                        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Nothing found", nil)
                                                                                   message:NSLocalizedString(@"Please, try to change tag or radius",nil)
                                                                                  delegate:self
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil];
                                                        [alert show];
                                                    }
                                                });
                                            }];
}

- (void)finishLoading{
    [self saveUserLocation];
    [self performSelectorOnMainThread:@selector(stopLoading) withObject:nil waitUntilDone:YES];
}

#pragma mark Managed data methods

- (void)locatePoint:(APImage *) image {
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        APPointAnnotation *annotation = [[APPointAnnotation alloc] init];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(image.latitude.floatValue,image.longitude.floatValue);
        [annotation setCoordinate:location];
        
        [annotation setTitle:image.title];
        [annotation setTag:image.image_id.integerValue];
        [self.mapView addAnnotation:annotation];
        
    });
    
}

- (void)restoreUserData{
    self.locationUpdated = NO;
    __weak typeof(self) weakSelf = self;
    [[APModelManager defaultManager] getAllImages:^(NSArray *images) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (images.count == 0){
                //Default Settings
                _radius = weakSelf.radiusSlider.maximumValue;
            }else{
                [weakSelf restoreUsertLocation];
                for (APImage *image in images){
                    [weakSelf locatePoint:image];
                }
                weakSelf.locationUpdated = YES;
            }
        });
    }];
    
}


#pragma mark Search bar methods


- (NSString *)stripDoubleSpaceFrom:(NSString *)str {
    while ([str rangeOfString:@"  "].location != NSNotFound) {
        str = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    }
    
    return str;
}

- (void)hideKeyBoard{
    [self.searchBar resignFirstResponder];
    [self cancelButton:self.searchBar enable:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self stopLoading];
    [self removeUserInformation];
    [searchBar setText:@""];
    [[APDownloadManager sharedManager] cancelTasks];
    [[APModelManager defaultManager] removeAllImages];
    [self.mapView removeAnnotations:self.mapView.annotations];
    [searchBar resignFirstResponder];
    [self cancelButton:self.searchBar enable:YES];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.length > text.length)
        return YES;
    return [self validateAlphabets:text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = [self stripDoubleSpaceFrom:searchBar.text];

    if ([self validateAlphabets:searchBar.text] && ![searchBar.text isEqualToString:@" "]){
        [self requestImages];
    }else{
        return;
    }
    
    [searchBar resignFirstResponder];
    [self cancelButton:self.searchBar enable:YES];
}

- (void)cancelButton:(UISearchBar *) searchBar enable:(BOOL) enable{
    for (UIView *view1 in searchBar.subviews){
        for (UIView *view2 in view1.subviews) {
            if ([view2 isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)view2;
                button.enabled = enable;
                button.userInteractionEnabled = enable;
            }
        }
    }
}

- (BOOL)validateAlphabets: (NSString *)alpha {
    NSString *abnRegex = @"[A-Za-z1234567890 \n]+";
    NSPredicate *abnTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", abnRegex];
    BOOL isValid = [abnTest evaluateWithObject:alpha];
    
    return isValid;
}

#pragma mark Slider methods

- (IBAction)setSliderValueAction:(UISlider *)sender {
    _radius = [self convertSliderValueToRadius];
    self.radiusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Search radius", nil),self.radius/1000.f];
    self.locationUpdated = NO;
    [self zoomToUserCoordinates:self.mapView.userLocation.coordinate radius:self.radius];
}

- (float)convertSliderValueToRadius {
    float value = self.radiusSlider.value;
    float adjustedValue = self.radiusSlider.maximumValue - value + self.radiusSlider.minimumValue;
    
    return adjustedValue;
}

- (float)convertRadiusToSliderValue {
    float value = self.radius;
    float adjustedValue = self.radiusSlider.maximumValue - value + self.radiusSlider.minimumValue;
    
    return adjustedValue;
}

- (void)setRadius:(float)radius {
    _radius = radius;
    self.radiusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Search radius", nil),radius/1000.f];
    self.radiusSlider.value = radius;
}


#pragma mark Location methods

- (void)setupLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    [self.locationManager requestAlwaysAuthorization];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }
    else {
        [self enableActivateLocationMessage:status];
    }
}

- (void)enableActivateLocationMessage:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusDenied) {
        NSString *title;
        title = (status == kCLAuthorizationStatusDenied) ? NSLocalizedString(@"Location services are off", nil)  : NSLocalizedString(@"Background location is not enabled",nil);
        NSString *message = NSLocalizedString(@"To use background location you must turn on 'Always' in the Location Services Settings",nil);
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Settings", nil];
        [alertView show];
        [self.locationManager startUpdatingLocation];
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // Send the user to the Settings for this app
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }else if (buttonIndex == 0){
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        [self enableActivateLocationMessage:status];
    }
}

#pragma mark Map view methods

- (void)saveUserLocation {
    CLLocationCoordinate2D coordinate = self.mapView.userLocation.location.coordinate;
    NSDictionary *locationDict = @{@"latitude": @(coordinate.latitude),
                                   @"longitude": @(coordinate.longitude),
                                   @"radius":@(self.radius)};
    [[NSUserDefaults standardUserDefaults] setObject:locationDict forKey:@"lastUserLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreUsertLocation {
    NSDictionary *locationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"lastUserLocation"];
    
    if (locationDict){
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = [[locationDict objectForKey:@"latitude"] doubleValue];
        coordinate.longitude = [[locationDict objectForKey:@"longitude"] doubleValue];
        self.radius = [[locationDict objectForKey:@"radius"] floatValue];
        [self zoomToUserCoordinates:coordinate radius:self.radius];
    }
}

- (void)removeUserInformation {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastUserLocation"];
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)location {
    [self zoomToUserCoordinates:location.coordinate radius:self.radius];
}

- (void)zoomToUserCoordinates:(CLLocationCoordinate2D )coordinates radius:(float) radius {
    if (self.isLocationUpdated)
        return;
    
    MKCoordinateRegion region;
    region = MKCoordinateRegionMakeWithDistance(coordinates, radius, radius);
    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:YES];
    
    self.locationUpdated = YES;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    MKAnnotationView *userAnnotationView = nil;
    if ([annotation isKindOfClass:MKPointAnnotation.class])
    {
        userAnnotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"UserLocation"];
        if (userAnnotationView == nil)  {
            userAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"UserLocation"];
        }
        else
            userAnnotationView.annotation = annotation;
        
        userAnnotationView.enabled = YES;
        userAnnotationView.canShowCallout = YES;
        
        APPointAnnotation *userAnnotation = (APPointAnnotation *)userAnnotationView.annotation;
        
        UIButton *showPhotoButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [showPhotoButton setTag:userAnnotation.tag];
        [showPhotoButton addTarget:self action:@selector(showImage:) forControlEvents:UIControlEventTouchUpInside];
        userAnnotationView.rightCalloutAccessoryView = showPhotoButton;
        
    }
    
    return userAnnotationView;
}

- (void)showImage:(UIButton *) sender{
    
    APImageViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"APImageViewController"];
    viewController.imageIdentifier = sender.tag;
    [self.navigationController pushViewController: viewController animated:YES];
    
}


@end
