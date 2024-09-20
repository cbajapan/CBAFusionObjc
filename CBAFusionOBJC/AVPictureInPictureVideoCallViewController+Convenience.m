//
//  AVPictureInPictureVideoCallViewController+Convenience.m
//  CBAFusionOBJC
//
//  Created by Cole M on 9/20/24.
//  Copyright © 2024 AliceCallsBob. All rights reserved.
//
#import "AVPictureInPictureVideoCallViewController+Convenience.h"

@implementation AVPictureInPictureVideoCallViewController (Convenience)

- (instancetype)initWithPipView:(UIView *)pipView preferredContentSize:(CGSize)preferredContentSize {
    self = [self init];
    if (self) {
        // Set the preferredContentSize.
        self.preferredContentSize = preferredContentSize;

        // Configure the pipView.
        pipView.translatesAutoresizingMaskIntoConstraints = NO;
        pipView.frame = self.view.bounds; // Use bounds instead of frame for proper sizing
        [self.view addSubview:pipView];

        // Set up Auto Layout constraints
        [NSLayoutConstraint activateConstraints:@[
            [pipView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [pipView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [pipView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [pipView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
        ]];
    }
    return self;
}

@end
