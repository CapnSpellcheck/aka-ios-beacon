//
//  AKACompositeControl+BindingDelegatePropagation.h
//  AKAControls
//
//  Created by Michael Utech on 13.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import AKACommons.AKANullability;

#import "AKACompositeControl.h"
#import "AKABinding.h"
#import "AKAControlViewBinding.h"


@interface AKACompositeControl (BindingDelegatePropagation)

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKABinding)binding
               targetUpdateFailedToConvertSourceValue:(opt_id)sourceValue
                               toTargetValueWithError:(opt_NSError)error;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKABinding)binding
              targetUpdateFailedToValidateTargetValue:(opt_id)targetValue
                             convertedFromSourceValue:(opt_id)sourceValue
                                            withError:(opt_NSError)error;

- (BOOL)                                      control:(req_AKAControl)control
                                        shouldBinding:(req_AKABinding)binding
                                    updateTargetValue:(opt_id)oldTargetValue
                                                   to:(opt_id)newTargetValue
                                       forSourceValue:(opt_id)oldSourceValue
                                             changeTo:(opt_id)newSourceValue;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKABinding)binding
                                willUpdateTargetValue:(opt_id)oldTargetValue
                                                   to:(opt_id)newTargetValue;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKABinding)binding
                                 didUpdateTargetValue:(opt_id)oldTargetValue
                                                   to:(opt_id)newTargetValue;

@end


@interface AKACompositeControl (ControlViewBindingDelegatePropagation)

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAControlViewBinding)binding
               sourceUpdateFailedToConvertTargetValue:(opt_id)targetValue
                               toSourceValueWithError:(opt_NSError)error;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAControlViewBinding)binding
              sourceUpdateFailedToValidateSourceValue:(opt_id)sourceValue
                             convertedFromTargetValue:(opt_id)targetValue
                                            withError:(opt_NSError)error;

- (BOOL)                                      control:(req_AKAControl)control
                                        shouldBinding:(req_AKAControlViewBinding)binding
                                    updateSourceValue:(opt_id)oldSourceValue
                                                   to:(opt_id)newSourceValue
                                       forTargetValue:(opt_id)oldTargetValue
                                             changeTo:(opt_id)newTargetValue;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAControlViewBinding)binding
                                willUpdateSourceValue:(opt_id)oldSourceValue
                                                   to:(opt_id)newSourceValue;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAControlViewBinding)binding
                                 didUpdateSourceValue:(opt_id)oldSourceValue
                                                   to:(opt_id)newSourceValue;

@end


@interface AKACompositeControl(KeyboardControlViewBindingDelegatePropagation)

- (BOOL)                                      control:(req_AKAControl)control
                                        shouldBinding:(req_AKAKeyboardControlViewBinding)binding
                                    responderActivate:(req_UIResponder)responder;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAKeyboardControlViewBinding)binding
                                responderWillActivate:(req_UIResponder)responder;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAKeyboardControlViewBinding)binding
                                 responderDidActivate:(req_UIResponder)responder;

- (BOOL)                                      control:(req_AKAControl)control
                                        shouldBinding:(req_AKAKeyboardControlViewBinding)binding
                                  responderDeactivate:(req_UIResponder)responder;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAKeyboardControlViewBinding)binding
                              responderWillDeactivate:(req_UIResponder)responder;

- (void)                                      control:(req_AKAControl)control
                                              binding:(req_AKAKeyboardControlViewBinding)binding
                               responderDidDeactivate:(req_UIResponder)responder;

- (BOOL)                                      control:(req_AKAControl)control
                                              binding:(req_AKAKeyboardControlViewBinding)binding
                       responderRequestedActivateNext:(req_UIResponder)responder;

- (BOOL)                                      control:(req_AKAControl)control
                                              binding:(req_AKAKeyboardControlViewBinding)binding
                           responderRequestedGoOrDone:(req_UIResponder)responder;

@end