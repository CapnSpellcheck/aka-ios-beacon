//
//  AKAControlViewBinding.m
//  AKABeacon
//
//  Created by Michael Utech on 13.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import UIKit;
#import "AKALog.h"
#import "NSObject+AKAConcurrencyTools.h"

#import "AKAControlViewBinding.h"
#import "AKABinding_Protected.h"
#import "AKABindingErrors.h"

@interface AKAControlViewBinding() {
    BOOL _isUpdatingSourceValueForTargetValueChange;
}

@end

@implementation AKAControlViewBinding

@dynamic delegate;


- (instancetype)init
{
    if (self = [super init])
    {
        _isUpdatingSourceValueForTargetValueChange = NO;
    }
    return self;
}

#pragma mark - Properties

- (BOOL)isUpdatingSourceValueForTargetValueChange
{
    return _isUpdatingSourceValueForTargetValueChange;
}

#pragma mark - Conversion

- (BOOL)                                 convertTargetValue:(opt_id)targetValue
                                              toSourceValue:(out_id)sourceValueStore
                                                      error:(out_NSError)error
{
    (void)error; // passthrough, never fails

    BOOL result = YES;
    if (sourceValueStore)
    {
        *sourceValueStore = targetValue;
    }
    return result;
}

#pragma mark - Delegate Support

- (void)            sourceUpdateFailedToValidateSourceValue:(opt_id)sourceValue
                                   convertedFromTargetValue:(opt_id)targetValue
                                                  withError:(opt_NSError)error
{
    id<AKAControlViewBindingDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(binding:sourceUpdateFailedToValidateSourceValue:convertedFromTargetValue:withError:)])
    {
        [delegate                      binding:self
            sourceUpdateFailedToValidateSourceValue:sourceValue
                           convertedFromTargetValue:targetValue
                                          withError:error];
    }
}

- (void)             sourceUpdateFailedToConvertTargetValue:(opt_id)targetValue
                                     toSourceValueWithError:(opt_NSError)error
{
    id<AKAControlViewBindingDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(binding:sourceUpdateFailedToConvertTargetValue:toSourceValueWithError:)])
    {
        [delegate                      binding:self
             sourceUpdateFailedToConvertTargetValue:targetValue
                             toSourceValueWithError:error];
    }
}

- (BOOL)              shouldUpdateTargetValueForSourceValue:(opt_id)oldSourceValue
                                                   changeTo:(opt_id)newSourceValue
                                                validatedTo:(opt_id)sourceValue
{
    (void)oldSourceValue;
    (void)newSourceValue;
    (void)sourceValue;

    // Break update cycles
    return !self.isUpdatingSourceValueForTargetValueChange;
}

- (BOOL)              shouldUpdateSourceValueForTargetValue:(opt_id)oldTargetValue
                                                   changeTo:(opt_id)newTargetValue
                                                validatedTo:(opt_id)targetValue
{
    (void)oldTargetValue;
    (void)newTargetValue;
    (void)targetValue;

    // Break update cycles
    return !self.isUpdatingTargetValueForSourceValueChange;
}

- (void)                   targetValueDidChangeFromOldValue:(opt_id)oldTargetValue
                                             toInvalidValue:(opt_id)newTargetValue
                                                  withError:(opt_NSError)error
{
    id<AKAControlViewBindingDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(binding:targetValueDidChangeFromOldValue:toInvalidValue:withError:)])
    {
        [delegate                       binding:self
               targetValueDidChangeFromOldValue:oldTargetValue
                                 toInvalidValue:newTargetValue
                                      withError:error];
    }
}

- (BOOL)                            shouldUpdateSourceValue:(id)oldSourceValue
                                                         to:(id)newSourceValue
                                             forTargetValue:(id)oldTargetValue
                                                   changeTo:(id)newTargetValue
{
    id<AKAControlViewBindingDelegate> delegate = self.delegate;
    BOOL result = YES;
    if ([delegate respondsToSelector:@selector(shouldBinding:updateSourceValue:to:forTargetValue:changeTo:)])
    {
        result = [delegate shouldBinding:self
                       updateSourceValue:oldSourceValue
                                      to:newSourceValue
                          forTargetValue:oldTargetValue
                                changeTo:newTargetValue];
    }
    return result;
}

- (void)                              willUpdateSourceValue:(opt_id)oldSourceValue
                                                         to:(opt_id)newSourceValue
{
    _isUpdatingSourceValueForTargetValueChange = YES;
    id<AKAControlViewBindingDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(binding:willUpdateSourceValue:to:)])
    {
        [delegate binding:self willUpdateSourceValue:oldSourceValue to:newSourceValue];
    }
}

- (void)                               didUpdateSourceValue:(opt_id)oldSourceValue
                                                         to:(opt_id)newSourceValue
{
    id<AKAControlViewBindingDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(binding:didUpdateSourceValue:to:)])
    {
        [delegate binding:self didUpdateSourceValue:oldSourceValue to:newSourceValue];
    }
    _isUpdatingSourceValueForTargetValueChange = NO;
}

#pragma mark - Source Value Updates

- (void)                                  updateSourceValueSkipDelegateRequests:(BOOL)skipDelegateRequests

{
    id targetValue = self.targetValueProperty.value;
    [self updateSourceValueForTargetValue:targetValue
                                 changeTo:targetValue
                     skipDelegateRequests:skipDelegateRequests];
}

- (void)                    updateSourceValueForTargetValue:(opt_id)oldTargetValue
                                                   changeTo:(opt_id)newTargetValue
{
    [self updateSourceValueForTargetValue:oldTargetValue
                                 changeTo:newTargetValue
                     skipDelegateRequests:NO];
}

- (void)                    updateSourceValueForTargetValue:(opt_id)oldTargetValue
                                                   changeTo:(opt_id)newTargetValue
                                       skipDelegateRequests:(BOOL)skipDelegateRequests
{
    (void)oldTargetValue;
    
    [self aka_performBlockInMainThreadOrQueue:
     ^{
         NSError* error;

         id sourceValue = nil;
         if ([self convertTargetValue:newTargetValue
                        toSourceValue:&sourceValue
                                error:&error])
         {
             if ([self validateSourceValue:&sourceValue error:&error])
             {
                 NSAssert(!self.isUpdatingSourceValueForTargetValueChange, @"Nested source value update for target value change.");

                 id oldSourceValue = self.sourceValueProperty.value;

                 if (skipDelegateRequests || [self shouldUpdateSourceValue:oldSourceValue
                                                                        to:sourceValue
                                                            forTargetValue:oldTargetValue
                                                                  changeTo:newTargetValue])
                 {
                     [self willUpdateSourceValue:oldSourceValue to:sourceValue];

                     self.sourceValueProperty.value = sourceValue;

                     [self didUpdateSourceValue:oldSourceValue to:sourceValue];
                 }
             }
             else
             {
                 [self sourceUpdateFailedToValidateSourceValue:sourceValue
                                      convertedFromTargetValue:newTargetValue
                                                     withError:error];
             }
         }
         else
         {
             [self sourceUpdateFailedToConvertTargetValue:newTargetValue
                                   toSourceValueWithError:error];
         }

     }
                            waitForCompletion:NO];
}

#pragma mark - Change Tracking

- (void)                   targetValueDidChangeFromOldValue:(opt_id)oldTargetValue
                                                 toNewValue:(opt_id)newTargetValue
{
    NSError* error;
    id targetValue = newTargetValue;
    if ([self validateTargetValue:&targetValue error:&error])
    {
        if ([self shouldUpdateSourceValueForTargetValue:oldTargetValue
                                               changeTo:newTargetValue
                                            validatedTo:targetValue])
        {
            [self updateSourceValueForTargetValue:oldTargetValue changeTo:targetValue];
        }
        else
        {
            AKALogVerbose(@"%@: Skipped source value update for target value '%@' change to '%@'",
                        self, oldTargetValue, newTargetValue);
        }
    }
    else
    {
        [self targetValueDidChangeFromOldValue:oldTargetValue
                                toInvalidValue:newTargetValue
                                     withError:error];
    }
}

@end

