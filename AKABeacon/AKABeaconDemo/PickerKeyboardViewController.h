//
//  PickerKeyboardViewController.h
//  AKABeaconDemo
//
//  Created by Michael Utech on 03.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

#import <UIKit/UIKit.h>

@import AKABeacon.AKAPickerKeyboardTriggerView;
@import AKABeacon.AKAFormViewController;

@interface PickerKeyboardViewController : AKAFormViewController

@property (weak, nonatomic) IBOutlet AKAPickerKeyboardTriggerView *stringPickerTriggerView;
@property (weak, nonatomic) IBOutlet AKAPickerKeyboardTriggerView *objectPickerTriggerView;

@end
