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

@interface MapViewController()<CLLocationManagerDelegate,MKMapViewDelegate,UISearchBarDelegate>

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
    [self setupLoactionManager];
    
}

- (void)defaultSettings{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.mapView.delegate = self;
    self.searchBar.delegate = self;
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];
    [self.mapView addGestureRecognizer:tapGesture];
    
    self.activityIndicator.hidesWhenStopped = YES;
    
    [self cancelButton:self.searchBar enable:YES];
     self.radius = self.radiusSlider.maximumValue;

}

#pragma mark Networking

- (void)startLoading {
    [self.loadingView  setHidden:NO];
    [self.activityIndicator startAnimating];
    self.radiusLabel.text = NSLocalizedString(@"Loading pictures: ", nil);
}

- (void)stopLoading {
    [self.loadingView  setHidden:YES];
    [self.activityIndicator stopAnimating];
    self.radius = self.radius;
}

-(void)requestImages {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[APDownloadManager sharedManager] downloadImagesWithTags:self.searchBar.text
                                                     location:self.mapView.userLocation.location.coordinate
                                                       radius:self.radius
                                               maxImagesCount:100
                                                      success:^(APImage *image, NSDictionary *info) {
                                                      }failure:nil
                                            completionHandler:^(NSArray *images){
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                    if (images.count == 0){
                                                        UIAlertView *alert =
                                                        [[UIAlertView alloc] initWithTitle:@"Nothing found"
                                                                                   message:@"Please, try to change tag or location"
                                                                                  delegate:self
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil];
                                                        [alert show];
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
    [searchBar resignFirstResponder];
    [self cancelButton:self.searchBar enable:YES];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = [self stripDoubleSpaceFrom:searchBar.text];

    if ([self validateAlphabets:searchBar.text] && ![searchBar.text isEqualToString:@" "]){
        [self requestImages];
    }else{
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"Input error"
                                   message:@"Please, use just english letters."
                                  delegate:self
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
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
    NSString *abnRegex = @"[A-Za-z123456789 ]+";
    NSPredicate *abnTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", abnRegex];
    BOOL isValid = [abnTest evaluateWithObject:alpha];
    
    return isValid;
}

#pragma mark Slider methods

- (IBAction)setSliderValueAction:(UISlider *)sender {
    _radius = [self convertSliderValueToRadius];
    self.radiusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Search radius", nil),self.radius/1000.f];
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

- (void)setupLoactionManager {
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
    else if (status == kCLAuthorizationStatusDenied) {
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
    }
}

#pragma mark Map view methods

- (void)saveUserLocation {
    NSDictionary *locationDict = @{@"userLocation": self.mapView.userLocation, @"radius": @(self.radius)};
    [[NSUserDefaults standardUserDefaults] setObject:locationDict forKey:@"lastUserLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreUsertLocation {
    NSDictionary *locationDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"lastUserLocation"];
    
    if (locationDict){
        MKUserLocation *userLocation = [locationDict objectForKey:@"userLocation"];
        self.radius = [[locationDict objectForKey:@"radius"] floatValue];
        [self zoomToUserCoordinates:userLocation.coordinate radius:self.radius];
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


@end
