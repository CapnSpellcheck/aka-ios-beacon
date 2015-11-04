//
//  AKAViewBinding.m
//  AKABeacon
//
//  Created by Michael Utech on 13.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import AKACommons.AKAErrors;

#import "AKAViewBinding.h"

@implementation AKAViewBinding

#pragma mark - Initialization

- (instancetype)                initWithTarget:(req_id)target
                                    expression:(req_AKABindingExpression)bindingExpression
                                       context:(req_AKABindingContext)bindingContext
                                      delegate:(opt_AKABindingDelegate)delegate
                                         error:(out_NSError)error
{
    NSParameterAssert([target isKindOfClass:[UIView class]]);

    return [self initWithView:target
                   expression:bindingExpression
                      context:bindingContext
                     delegate:delegate
                        error:error];
}

- (instancetype _Nullable)        initWithView:(req_UIView)target
                                    expression:(req_AKABindingExpression)bindingExpression
                                       context:(req_AKABindingContext)bindingContext
                                      delegate:(opt_AKABindingDelegate)delegate
                                         error:(out_NSError)error
{
    [self validateTargetView:target];

    if (self = [super initWithTarget:[self createBindingTargetPropertyForView:target]
                          expression:bindingExpression
                             context:bindingContext
                            delegate:delegate
                               error:error])
    {
        _view = target;
    }

    return self;
}

- (void)validateTargetView:(req_UIView)targetView
{
    (void)targetView;
    NSParameterAssert([targetView isKindOfClass:[UIView class]]);
}

- (req_AKAProperty)createBindingTargetPropertyForView:(req_UIView)target
{
    (void)target;
    AKAErrorAbstractMethodImplementationMissing();
}

@end