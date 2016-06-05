//
//  MapViewController.m
//  APFlickrImageViewer
//
//  Created by ton252 on 05.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController()<CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *radiusLabel;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property(strong, nonatomic) CLLocationManager *locationManager;

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
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];
    [self.mapView addGestureRecognizer:tapGesture];
    
    [self cancelButton:self.searchBar enable:YES];
    self.radius = [self convertSliderValueToRadius];
}



#pragma mark Search bar methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self cancelButton:self.searchBar enable:YES];
}


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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = [self stripDoubleSpaceFrom:searchBar.text];

    if ([self validateAlphabets:searchBar.text] && ![searchBar.text isEqualToString:@" "]){

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
        title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
        NSString *message = @"To use background location you must turn on 'Always' in the Location Services Settings";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Settings", nil];
        [alertView show];
        [self.locationManager startUpdatingLocation];
        [self.locationManager requestAlwaysAuthorization];
        NSLog(@"Location access denied");
    }
}


@end
