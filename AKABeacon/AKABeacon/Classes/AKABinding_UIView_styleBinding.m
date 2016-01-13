//
//  AKABinding_UIView_styleBinding.m
//  AKABeacon
//
//  Created by Michael Utech on 15.12.15.
//  Copyright © 2015 Michael Utech & AKA Sarl. All rights reserved.
//

#import "AKABinding_UIView_styleBinding.h"
#import "AKAPropertyBinding.h"

@implementation AKABinding_UIView_styleBinding

+ (AKABindingSpecification *)specification
{
    static AKABindingSpecification* result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary* spec =
        @{ @"bindingType":          [AKABinding_UIView_styleBinding class],
           @"targetType":           [UIView class],
           @"expressionType":       @(AKABindingExpressionTypeNone),
           @"attributes":
               @{ @"backgroundColor":
                      @{ @"bindingType":    [AKAPropertyBinding class],
                         @"expressionType": @(AKABindingExpressionTypeUIColor),
                         @"use":             @(AKABindingAttributeUseBindToTargetProperty),
                         @"bindingProperty": @"backgroundColor"
                         },
                  },
           };
        result = [[AKABindingSpecification alloc] initWithDictionary:spec basedOn:[super specification]];
    });
    return result;
}

#pragma mark - Initialization

- (void)validateTargetView:(req_UIView)targetView
{
    NSParameterAssert([targetView isKindOfClass:[UIView class]]);
}


- (AKAProperty*)createBindingTargetPropertyForView:(req_UIView)view
{
    (void)view;
    // We might want to use some base style/theming mechanism here. For the time
    // being, the primary value is simply ignored and the binding target value too.
    return [AKAProperty propertyOfWeakTarget:view
                                      getter:
            ^id _Nullable(req_id target)
            {
                return target;
            }
                                      setter:
            ^(req_id target, opt_id value)
            {
                (void)target;
                (void)value;
            }
                          observationStarter:
            ^BOOL(req_id target)
            {
                (void)target;
                return YES;
            }
                          observationStopper:
            ^BOOL(req_id target)
            {
                (void)target;
                return YES;
            }];
}

- (AKAProperty *)defaultBindingSourceForExpression:(req_AKABindingExpression)bindingExpression
                                           context:(req_AKABindingContext)bindingContext
                                    changeObserver:(AKAPropertyChangeObserver)changeObserver
                                             error:(NSError *__autoreleasing  _Nullable *)error
{
    (void)bindingExpression;
    (void)bindingContext;
    (void)error;
    
    return [AKAProperty propertyOfWeakKeyValueTarget:nil keyPath:nil changeObserver:changeObserver];
}

@end
