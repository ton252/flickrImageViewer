//
//  APImageViewController.m
//  APFlickrImageViewer
//
//  Created by ton252 on 05.06.16.
//  Copyright © 2016 ton252. All rights reserved.
//

#import "APImageViewController.h"
#import "APImage+CoreDataProperties.h"
#import "APModelManager.h"

@interface APImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation APImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadImage];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void)loadImage {
    APImage *imageModel = [[APModelManager defaultManager] getAPImageWithID:self.imageIdentifier];
    
    if (imageModel){
        UIImage *image = [UIImage imageWithData:imageModel.data];
        [self.imageView setImage:image];
        [self setTitle:imageModel.title];
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillDisappear:animated];
}

#pragma mark ScrollView delegate method

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}


@end
