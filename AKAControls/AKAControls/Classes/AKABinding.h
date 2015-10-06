//
//  AKABinding.h
//  AKAControls
//
//  Created by Michael Utech on 17.09.15.
//  Copyright (c) 2015 AKA Sarl. All rights reserved.
//

@import UIKit;
@import AKACommons.AKANullability;
@import AKACommons.AKAProperty;

#import "AKABindingExpression.h"

@class AKABinding;
@protocol AKABindingDelegate;
typedef AKABinding* _Nullable                               opt_AKABinding;
typedef AKABinding* _Nonnull                                req_AKABinding;
typedef id<AKABindingDelegate>_Nullable                     opt_AKABindingDelegate;


@interface AKABinding : NSObject

#pragma mark - Initialization

- (instancetype _Nullable)         initWithTarget:(id _Nonnull)target
                                       expression:(req_AKABindingExpression)bindingExpression
                                          context:(req_AKABindingContext)bindingContext
                                         delegate:(opt_AKABindingDelegate)delegate;

#pragma mark - Configuration

@property(nonatomic, readonly, nonnull) AKAProperty*        bindingSource;
@property(nonatomic, readonly, nonnull) AKAProperty*        bindingTarget;
@property(nonatomic, readonly, nullable) SEL                bindingProperty;
@property(nonatomic, readonly, weak) id<AKABindingDelegate> delegate;

#pragma mark - Conversion


- (BOOL)convertSourceValue:(opt_id)sourceValue
             toTargetValue:(out_id)targetValueStore
                     error:(out_NSError)error;

- (BOOL)convertTargetValue:(opt_id)targetValue
             toSourceValue:(out_id)sourceValueStore
                     error:(out_NSError)error;

#pragma mark - Validation

- (BOOL)validateSourceValue:(inout_id)sourceValueStore
                      error:(out_NSError)error;

- (BOOL)validateTargetValue:(inout_id)targetValueStore
                      error:(out_NSError)error;

#pragma mark - Change Tracking

- (void)             sourceValueDidChangeFromOldValue:(opt_id)oldSourceValue
                                           toNewValue:(opt_id)newSourceValue;

- (void)             targetValueDidChangeFromOldValue:(opt_id)oldTargetValue
                                           toNewValue:(opt_id)newTargetValue;

- (BOOL)                        startObservingChanges;

- (BOOL)                         stopObservingChanges;

#pragma mark - Change Propagation

/**
 * Determines if the source (f.e. model-) value should be updated as a result of a changed
 * target (f.e. view-) value. The default implementation returns NO, if the target value is
 * currently being updated (and thus would trigger an update cycle).
 *
 * @warning: Sub classes redefining this method should always call the super implementation and never return YES if it returned NO.
 *
 * @param oldTargetValue the old target value
 * @param newTargetValue the new target value
 * @param targetValue the new target value or the result of the target value validation replacing an invalid value.
 *
 * @return YES if the source value should be updated, NO otherwise.
 */
- (BOOL)        shouldUpdateSourceValueForTargetValue:(opt_id)oldTargetValue
                                             changeTo:(opt_id)newTargetValue
                                          validatedTo:(opt_id)targetValue;

/**
 * Determines if the target (f.e. view-) value should be updated as a result of a changed
 * source (f.e. model-) value. The default implementation returns NO, if the source value
 * is currently being updated (and thus would trigger an update cycle).
 *
 * @warning: Sub class redefining this method should always call the super implementation and never return YES if it returned NO.
 *
 * @param oldSourceValue the old source value
 * @param newSourceValue the new source value
 * @param sourceValue the new source value or the result of the source value validation replacing an invalid value.
 *
 * @return YES if the target value should be updated, NO otherwise.
 */
- (BOOL)        shouldUpdateTargetValueForSourceValue:(opt_id)oldSourceValue
                                             changeTo:(opt_id)newSourceValue
                                          validatedTo:(opt_id)sourceValue;

@end

@interface AKABinding(Protected)

#pragma mark - UIResponder Events

- (void)                  responderWillActivate:(req_UIResponder)responder;

- (void)                   responderDidActivate:(req_UIResponder)responder;

- (void)                responderWillDeactivate:(req_UIResponder)responder;

- (void)                 responderDidDeactivate:(req_UIResponder)responder;

@end


@protocol AKABindingDelegate<NSObject>

@optional
/**
 * Informs the delegate, that an attempt to update the
 * target value for a source value change to the specified
 * value failed because the source value could not be converted
 * to a valid target value.
 *
 * @param binding the binding observing source value changes.
 * @param sourceValue the source value that could not be converted
 * @param error an error object providing additional information.
 */
- (void)                                binding:(req_AKABinding)binding
         targetUpdateFailedToConvertSourceValue:(opt_id)sourceValue
                         toTargetValueWithError:(opt_NSError)error;

@optional
/**
 * Informs the delegate, that an attempt to update the
 * target value for a source value change to the specified
 * value failed because the new target value is not valid.
 *
 * @param binding the binding observing the source value change
 * @param targetValue the target value obtained by converstion from the source value.
 * @param sourceValue the source value which itself passed validation.
 * @param error an error object providing additional information.
 */
- (void)                                binding:(req_AKABinding)binding
        targetUpdateFailedToValidateTargetValue:(opt_id)targetValue
                       convertedFromSourceValue:(opt_id)sourceValue
                                      withError:(opt_NSError)error;

@optional
/**
 * Informs the delegate, that an attempt to update the
 * source (model) value for a target (view) value change to the specified
 * value failed, because the target value could not be converted
 * to a valid source value.
 *
 * @param binding the binding observing target value changes.
 * @param targetValue the target value that could not be converted.
 * @param error an error object providing additional information.
 */
- (void)                                binding:(req_AKABinding)binding
         sourceUpdateFailedToConvertTargetValue:(opt_id)targetValue
                         toSourceValueWithError:(opt_NSError)error;

@optional
/**
 * Informs the delegate, that an attempt to update the
 * source value for a target value change to the specified
 * value failed because the target value is not valid.
 *
 * @param binding the binding observing the source value change
 * @param targetValue the invalid target value
 * @param error an error object providing additional information.
 */
- (void)                                binding:(req_AKABinding)binding
        sourceUpdateFailedToValidateSourceValue:(opt_id)sourceValue
                       convertedFromTargetValue:(opt_id)targetValue
                                      withError:(opt_NSError)error;

#pragma mark - AKAKeyboardActivationSequence Control

- (BOOL)                                binding:(req_AKABinding)binding
                 responderRequestedActivateNext:(req_UIResponder)responder;

#pragma mark - UIResponder Events

@optional
- (void)                                binding:(req_AKABinding)binding
                          responderWillActivate:(req_UIResponder)responder;

@optional
- (void)                                binding:(req_AKABinding)binding
                           responderDidActivate:(req_UIResponder)responder;

@optional
- (void)                                binding:(req_AKABinding)binding
                        responderWillDeactivate:(req_UIResponder)responder;

@optional
- (void)                                binding:(req_AKABinding)binding
                         responderDidDeactivate:(req_UIResponder)responder;



@end