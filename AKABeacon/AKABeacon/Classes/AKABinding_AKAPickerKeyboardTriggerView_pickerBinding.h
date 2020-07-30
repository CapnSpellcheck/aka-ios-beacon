//
//  AKABinding_AKAPickerKeyboardTriggerView_pickerBinding.h
//  AKABeacon
//
//  Created by Michael Utech on 04.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

#import "AKAKeyboardBinding_AKACustomKeyboardResponderView.h"


#pragma mark - AKABinding_AKAPickerKeyboardTriggerView_pickerBinding - Interface
#pragma mark -

@interface AKABinding_AKAPickerKeyboardTriggerView_pickerBinding: AKAKeyboardBinding_AKACustomKeyboardResponderView

@property(nonatomic, readonly) opt_AKABindingExpression             choicesBindingExpression;
@property(nonatomic, readonly) opt_AKABindingExpression             titleBindingExpression;
@property(nonatomic, readonly) opt_NSString                         titleForUndefinedValue;
@property(nonatomic, readonly) opt_NSString                         titleForOtherValue;

@property(nonatomic, readonly) BOOL                                 needsReloadChoices;
@property(nonatomic, readonly, nullable) id                         otherValue;

@property(nonatomic, readonly) UIPickerView*                        pickerView;

- (void)                                animateTriggerForValue:(id)oldValue
                                                      changeTo:(id)newValue
                                                    animations:(void (^)())block;
@end


