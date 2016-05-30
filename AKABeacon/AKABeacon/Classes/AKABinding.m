//
//  AKABinding.m
//  AKABeacon
//
//  Created by Michael Utech on 17.09.15.
//  Copyright (c) 2015 Michael Utech & AKA Sarl. All rights reserved.
//

#import <objc/runtime.h>

// Internal Data Properties
#import "AKABinding_SubBindingsProperties.h"
#import "AKABinding_TargetValueUpdateProperties.h"

// Subclassing Interface
#import "AKABinding_Protected.h"
#import "AKABinding+SubclassInitialization.h"
#import "AKABinding+SubclassObservationEvents.h"
#import "AKABinding+DelegateSupport.h"

// Well Known Binding Types
#import "AKAConditionalBinding.h"
#import "AKAPropertyBinding.h"

#import "AKABindingErrors.h"
#import "AKABindingDelegateDispatcher.h"
#import "AKABindingExpressionEvaluator.h"
#import "NSObject+AKAConcurrencyTools.h"
#import "AKALog.h"

#pragma mark - AKABinding Private Interface
#pragma mark -

@interface AKABinding () {
    id                              _syntheticTargetValue;
    AKABindingDelegateDispatcher*   _delegateDispatcher;
}

@end

#pragma mark - AKABinding - Implementation
#pragma mark -

@implementation AKABinding

#pragma mark - Initialization

+ (opt_AKABinding)bindingToTarget:(req_id)target
                   withExpression:(req_AKABindingExpression)bindingExpression
                          context:(req_AKABindingContext)bindingContext
                         delegate:(opt_AKABindingDelegate)delegate
                            error:(out_NSError)error
{
    if (bindingExpression.expressionType == AKABindingExpressionTypeConditional)
    {
        AKAConditionalBinding* result = [AKAConditionalBinding alloc];
        result = [result initWithTarget:target
                      resultBindingType:self
                             expression:bindingExpression
                                context:bindingContext
                               delegate:delegate
                                  error:error];
        return result;
    }
    else
    {
        return [[self alloc] initWithTarget:target
                                 expression:bindingExpression
                                    context:bindingContext
                                   delegate:delegate
                                      error:error];
    }
}

+ (opt_AKABinding)bindingToTargetProperty:(req_AKAProperty)target
                           withExpression:(req_AKABindingExpression)bindingExpression
                                  context:(req_AKABindingContext)bindingContext
                                 delegate:(opt_AKABindingDelegate)delegate
                                    error:(out_NSError)error
{
    if (bindingExpression.expressionType == AKABindingExpressionTypeConditional)
    {
        AKAConditionalBinding* result = [AKAConditionalBinding alloc];
        result = [result initWithTargetProperty:target
                              resultBindingType:self
                                     expression:bindingExpression
                                        context:bindingContext
                                       delegate:delegate
                                          error:error];
        return result;
    }
    else
    {
        return [[self alloc] initWithTargetProperty:target
                                         expression:bindingExpression
                                            context:bindingContext
                                           delegate:delegate
                                              error:error];
    }
}

#pragma mark - Private Initializers

- (instancetype)                                       init
{
    if (self = [super init])
    {
        _isUpdatingTargetValueForSourceValueChange = NO;
    }

    return self;
}


- (opt_instancetype)initWithTargetProperty:(req_AKAProperty)target
                                expression:(req_AKABindingExpression)bindingExpression
                                   context:(req_AKABindingContext)bindingContext
                                  delegate:(opt_AKABindingDelegate)delegate
                                     error:(out_NSError)error
{
    NSError* localError = nil;

    AKABindingSpecification *specification = [self.class specification];

    Class specifiedBindingType = bindingExpression.specification.bindingType;

    if (![self validateBindingTypeWithExpression:bindingExpression
                                           error:&localError])
    {
        self = nil;
    }

    if (self)
    {
        // TODO: check if relaxing attribute checks is still needed anyway
        // Perform binding expression validation; relax attribute checks if binding type is a sub class of
        // the binding type defined in the specification:
        BOOL relaxAttributeChecks = self.class != specifiedBindingType;
        if (specification.bindingSourceSpecification)
        {
            if (![bindingExpression validateWithSpecification:bindingExpression.specification.bindingSourceSpecification
                               overrideAllowUnknownAttributes:relaxAttributeChecks
                                                        error:&localError])
            {
                self = nil;
            }
        }
    }


    if (self = [self init])
    {
        NSAssert(target == nil || [target isKindOfClass:[AKAProperty class]],
                @"Invalid target %@, expected instance of AKAProperty", target);
        _bindingTarget = target;

        _bindingContext = bindingContext;
        _delegateDispatcher = [[AKABindingDelegateDispatcher alloc] initWithDelegate:delegate
                delegateOverwrites:self];

        __weak AKABinding *weakSelf = self;
        req_AKAPropertyChangeObserver changeObserver = ^(opt_id oldValue, opt_id newValue) {
            [weakSelf processSourceValueChangeFromOldValue:oldValue
                                                 toNewValue:newValue];
        };
        AKAProperty *bindingSource = [self bindingSourceForExpression:bindingExpression
                context:bindingContext
                changeObserver:changeObserver
                error:&localError];
        if (bindingSource)
        {
            _bindingSource = (req_AKAProperty)bindingSource;
        }
        else
        {
            self = nil;
        }

        if (![self initializeAttributesWithExpression:bindingExpression
                                                error:&localError])
        {
            self = nil;
        }
    }

    if (self == nil)
    {
        if (error)
        {
            *error = localError;
        }
        else
        {
            // If the caller does not provide an error storage, we assume that it's not taking
            // care of error handling and consider the missing binding error a fatal condition.
            @throw [NSException exceptionWithName:@"Failed to create binding"
                                           reason:localError.localizedDescription
                                         userInfo:nil];
        }
    }

    return self;
}

#pragma mark - Properties

- (AKABindingController*)                        controller
{
    id result = self.bindingContext;

    if (![result isKindOfClass:[AKABindingController class]])
    {
        result = nil;
    }

    return result;
}

- (BOOL)          isUpdatingTargetValueForSourceValueChange
{
    return _isUpdatingTargetValueForSourceValueChange;
}

- (id<AKABindingDelegate>)                         delegate
{
    return _delegateDispatcher.delegate;
}

- (id<AKABindingDelegate>)           delegateForSubBindings
{
    id<AKABindingDelegate> result = _delegateDispatcher;
    if (!result)
    {
        result = self;
    }
    return result;
}

#pragma mark - Conversion

- (BOOL)                                 convertSourceValue:(opt_id)sourceValue
                                              toTargetValue:(out_id)targetValueStore
                                                      error:(out_NSError)error
{
    (void)error; // passthrough, never fails

    BOOL result = YES;

    if (targetValueStore)
    {
        *targetValueStore = sourceValue;
    }

    return result;
}

#pragma mark - Validation

- (BOOL)                                validateSourceValue:(inout_id)sourceValueStore
                                                      error:(out_NSError)error
{
    NSParameterAssert(sourceValueStore != nil);

    BOOL result = YES;

    id validatedValue = sourceValueStore == nil ? nil : *sourceValueStore;

    if (self.bindingSource != nil)
    {
        result = [self.bindingSource validateValue:&validatedValue error:error];

        if (sourceValueStore && validatedValue != *sourceValueStore)
        {
            *sourceValueStore = validatedValue;
        }
    }

    return result;
}

- (BOOL)                                validateTargetValue:(inout_id)targetValueStore
                                                      error:(out_NSError)error
{
    NSParameterAssert(targetValueStore != nil);

    BOOL result = YES;

    id validatedValue = targetValueStore == nil ? nil : *targetValueStore;

    if (self.bindingTarget != nil)
    {
        result = [self.bindingTarget validateValue:&validatedValue error:error];

        if (targetValueStore && validatedValue != *targetValueStore)
        {
            *targetValueStore = validatedValue;
        }
    }

    return result;
}

#pragma mark - Target Value Updates

- (void)                                  updateTargetValue
{
    id sourceValue = self.bindingSource.value;

    [self updateTargetValueForSourceValue:sourceValue changeTo:sourceValue];
}

- (void)                    updateTargetValueForSourceValue:(opt_id)oldSourceValue
                                                   changeTo:(opt_id)newSourceValue
{
    [self aka_performBlockInMainThreadOrQueue:
     ^{
         id targetValue = nil;
         NSError* error;

         id oldTargetValue = self.bindingTarget.value;
         
         if ([self convertSourceValue:newSourceValue
                        toTargetValue:&targetValue
                                error:&error])
         {
             if ([self validateTargetValue:&targetValue
                                     error:&error])
             {
                 if ([self shouldUpdateTargetValue:oldTargetValue
                                                to:targetValue
                                    forSourceValue:oldSourceValue
                                          changeTo:newSourceValue])
                 {
                     [self willUpdateTargetValue:oldTargetValue
                                              to:targetValue];

                     // Some bindings wrap the source value in an object that may not change when the
                     // source value changes or perform other transformations that would not either.
                     if (oldTargetValue != targetValue || oldSourceValue != newSourceValue)
                     {
                         self.bindingTarget.value = targetValue;
                     }

                     if (oldTargetValue != targetValue || oldSourceValue != newSourceValue)
                     {
                         for (AKABinding* tpBinding in self.targetPropertyBindings)
                         {
                             [tpBinding updateTargetValue];
                         }
                     }


                     [self didUpdateTargetValue:oldTargetValue
                                             to:targetValue];
                 }
             }
             else
             {
                 [self targetUpdateFailedToValidateTargetValue:targetValue
                                      convertedFromSourceValue:newSourceValue
                                                     withError:error];
             }
         }
         else
         {
             [self targetUpdateFailedToConvertSourceValue:newSourceValue
                                   toTargetValueWithError:error];
         }
     }
                            waitForCompletion:NO];
}

#pragma mark - Change Tracking

- (BOOL)                              startObservingChanges
{
    BOOL result = YES;

    [self willStartObservingChanges];

    result = [self startObservingBindingPropertyBindings] && result;
    result = [self startObservingBindingTarget] && result;
    result = [self startObservingBindingSource] && result;

    [self initializeTargetValueForObservationStart];

    result = [self startObservingBindingTargetPropertyBindings] && result;

    [self didStartObservingChanges];

    return result;
}

- (BOOL)              startObservingBindingPropertyBindings
{
    BOOL result = YES;
    [self willStartObservingBindingPropertyBindings];
    for (AKABinding* bpBinding in self.bindingPropertyBindings)
    {
        result = [bpBinding startObservingChanges] && result;
    }
    [self didStartObservingBindingPropertyBindings];
    return result;
}

- (BOOL)                        startObservingBindingTarget
{
    [self willStartObservingBindingTarget];
    BOOL result = [self.bindingTarget startObservingChanges];
    [self didStartObservingBindingTarget];
    return result;
}

- (BOOL)                        startObservingBindingSource
{
    [self willStartObservingBindingSource];
    BOOL result = [self.bindingSource startObservingChanges];
    [self didStartObservingBindingSource];
    return result;
}

- (void)           initializeTargetValueForObservationStart
{
    [self willInitializeTargetValueForObservationStart];
    [self updateTargetValue];
    [self didInitializeTargetValueForObservationStart];
}

- (BOOL)        startObservingBindingTargetPropertyBindings
{
    BOOL result = YES;
    [self willStartObservingBindingTargetPropertyBindings];
    for (AKABinding* tpBinding in self.targetPropertyBindings)
    {
        result = [tpBinding startObservingChanges] && result;
    }
    [self didStartObservingBindingTargetPropertyBindings];
    return result;
}

- (BOOL)                               stopObservingChanges
{
    __block BOOL result = YES;

    result = [self stopObservingBindingTargetPropertyBindings] && result;

    result = [self stopObservingBindingTarget] && result;
    result = [self stopObservingBindingSource] && result;

    result = [self stopObservingBindingPropertyBindings] && result;

    return result;
}

- (BOOL)               stopObservingBindingPropertyBindings
{
    BOOL result = YES;
    [self willStopObservingBindingPropertyBindings];
    for (AKABinding* bpBinding in self.bindingPropertyBindings)
    {
        result = [bpBinding stopObservingChanges] && result;
    }
    [self didStopObservingBindingPropertyBindings];
    return result;
}

- (BOOL)                         stopObservingBindingTarget
{
    [self willStopObservingBindingTarget];
    BOOL result = [self.bindingTarget stopObservingChanges];
    [self didStopObservingBindingTarget];
    return result;
}

- (BOOL)                         stopObservingBindingSource
{
    [self willStopObservingBindingSource];
    BOOL result = [self.bindingSource stopObservingChanges];
    [self didStopObservingBindingSource];
    return result;
}

- (BOOL)         stopObservingBindingTargetPropertyBindings
{
    BOOL result = YES;
    [self willStopObservingBindingTargetPropertyBindings];
    for (AKABinding* tpBinding in self.targetPropertyBindings)
    {
        result = [tpBinding stopObservingChanges] && result;
    }
    [self didStopObservingBindingTargetPropertyBindings];
    return result;
}

- (void)               processSourceValueChangeFromOldValue:(opt_id)oldSourceValue
                                                 toNewValue:(opt_id)newSourceValue
{
    NSError* error;
    id sourceValue = newSourceValue;

    if ([self validateSourceValue:&sourceValue error:&error])
    {
        [self sourceValueDidChangeFromOldValue:oldSourceValue to:newSourceValue];

        if ([self shouldUpdateTargetValueForSourceValue:oldSourceValue
                                               changeTo:newSourceValue
                                            validatedTo:sourceValue])
        {
            [self updateTargetValueForSourceValue:oldSourceValue
                                         changeTo:sourceValue];
        }
    }
    else
    {
        [self sourceValueDidChangeFromOldValue:oldSourceValue
                                toInvalidValue:newSourceValue
                                     withError:error];
    }
}

#pragma mark - Obscure

/**
 Called when a sub binding created from an attribute configured for use AKABindingAttributeUseBindToBindingProperty changed the value of the configured property of this binding.

 @param bindingPropertyName the properties name (KVC key).
 @param oldValue            the properties value before the change
 @param newValue            the properties new value
 */
- (void)                                    bindingProperty:(req_NSString)bindingPropertyName
                                                      value:(opt_id)oldValue
                                        didChangeToNewValue:(opt_id)newValue
{
}

/**
 Called when a sub binding created from an attribute configured for use AKABindingAttributeUseBindToTargetProperty changed the value of the configured property of this binding's target value.

 @param bindingPropertyName the properties name (KVC key).
 @param oldValue            the properties value before the change
 @param newValue            the properties new value
 */
- (void)                                     targetProperty:(req_NSString)bindingPropertyName
                                                      value:(opt_id)oldValue
                                        didChangeToNewValue:(opt_id)newValue
{
}

#pragma mark - AKABindingDelegate implementation (for sub bindings)

- (void)                                            binding:(AKABinding*)binding
                           sourceValueDidChangeFromOldValue:(opt_id)oldSourceValue
                                                         to:(opt_id)newSourceValue
{
    if (self.arrayItemBindings.count > 0)
    {
        NSUInteger arrayItemIndex = [self.arrayItemBindings indexOfObject:binding];
        if (arrayItemIndex != NSNotFound)
        {
            [self sourceArrayItemAtIndex:arrayItemIndex
                                   value:oldSourceValue
                             didChangeTo:newSourceValue];
        }
    }
}

#pragma mark - Diagnostics

- (NSString*)                                   description
{
    return [NSString stringWithFormat:@"<%@: %p; source=%@, target=%@>",
            self.class, (__bridge void*)self,
            self.bindingSource, self.bindingTarget];
}

@end


#pragma mark - AKABinding - Protected Implementation (subclass interface)
#pragma mark -

@implementation AKABinding(Protected)

#pragma mark - Properties

- (id)                                 syntheticTargetValue
{
    return _syntheticTargetValue;
}

- (void)                            setSyntheticTargetValue:(id)syntheticTargetValue
{
    _syntheticTargetValue = syntheticTargetValue;
}

#pragma mark - Change Tracking

@end


@implementation AKABinding (BindingSpecification)

+ (req_AKABindingSpecification)specification
{
    return nil;
}

+ (Class)bindingTypeForBindingExpressionInPrimaryExpressionArray
{
    AKABindingSpecification* specification = [self specification];
    return specification.bindingSourceSpecification.arrayItemBindingType;
}

+ (Class)bindingTypeForAttributeNamed:(NSString *)attributeName
{
    return [self specificationForAttributeNamed:attributeName].bindingType;
}

+ (opt_AKABindingAttributeSpecification)specificationForAttributeNamed:(NSString*)attributeName
{
    AKABindingSpecification* specification = [self specification];

    return specification.bindingSourceSpecification.attributes[attributeName];
}

@end

