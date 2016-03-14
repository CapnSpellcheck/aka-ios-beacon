//
//  AKABindingBehaviourViewController.h
//  AKABeacon
//
//  Created by Michael Utech on 13.03.16.
//  Copyright © 2016 Michael Utech & AKA Sarl. All rights reserved.
//

@import UIKit;
#import "AKAControlDelegate.h"

@class AKAFormControl;
@class AKABindingBehaviourViewController;


@protocol AKABindingBehaviourDelegate <AKAControlDelegate>
@end


@interface AKABindingBehaviourViewController : UIViewController

+ (void)addToViewController:(UIViewController*)viewController;
- (void)addToViewController:(UIViewController*)viewController;
- (void)removeFromViewController:(UIViewController*)viewController;

@property(nonatomic, readonly) AKAFormControl* formControl;
@property(nonatomic, readonly, weak) id<AKABindingBehaviourDelegate> delegate;

// TODO: refactor into separate behavior:
@property(nonatomic, readonly, weak) UIScrollView* scrollView;

@end
