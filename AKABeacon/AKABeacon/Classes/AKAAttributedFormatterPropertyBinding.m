//
//  AKAAttributedFormatterPropertyBinding.m
//  AKABeacon
//
//  Created by Michael Utech on 19.12.15.
//  Copyright © 2015 Michael Utech & AKA Sarl. All rights reserved.
//

#import "AKAAttributedFormatterPropertyBinding.h"
#import "AKANSEnumerations.h"
#import "AKAAttributedFormatter.h"

@implementation AKAAttributedFormatterPropertyBinding

+ (AKABindingSpecification*)                 specification
{
    static AKABindingSpecification* result = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSDictionary* spec = @{
            @"bindingType":         [AKAAttributedFormatterPropertyBinding class],
            @"targetType":          [AKAProperty class],
            @"expressionType":      @(AKABindingExpressionTypeAnyKeyPath | AKABindingExpressionTypeNone),
            @"attributes": @{
                @"pattern": @{
                    @"required":        @YES,
                    @"use":             @(AKABindingAttributeUseBindToTargetProperty),
                    @"expressionType":  @(AKABindingExpressionTypeString)
                },

                @"patternOptions": @{
                    @"required":        @NO,
                    @"use":             @(AKABindingAttributeUseBindToTargetProperty),
                    @"expressionType":  @(AKABindingExpressionTypeOptionsConstant|AKABindingExpressionTypeAnyKeyPath),
                    @"optionsType":     @"NSStringCompareOptions"
                },

                @"backgroundColor": @{
                    @"required":        @NO,
                    @"use": @(AKABindingAttributeUseBindToTargetProperty),
                    @"bindingProperty": [NSString stringWithFormat:@"attributes.%@", NSBackgroundColorAttributeName],
                    @"expressionType":  @(AKABindingExpressionTypeUIColor)
                },

                @"textColor": @{
                    @"required":        @NO,
                    @"use": @(AKABindingAttributeUseBindToTargetProperty),
                    @"bindingProperty": [NSString stringWithFormat:@"attributes.%@", NSForegroundColorAttributeName],
                    @"expressionType":  @(AKABindingExpressionTypeUIColor)
                },

                @"font": @{
                    @"required":        @NO,
                    @"use": @(AKABindingAttributeUseBindToTargetProperty),
                    @"bindingProperty": [NSString stringWithFormat:@"attributes.%@", NSFontAttributeName],
                    @"expressionType":  @(AKABindingExpressionTypeUIFontConstant)
                },
            },
            @"allowUnspecifiedAttributes":   @YES
        };

        result = [[AKABindingSpecification alloc] initWithDictionary:spec basedOn:[super specification]];
    });

    return result;
}

+ (void)registerEnumerationAndOptionTypes
{
    [super registerEnumerationAndOptionTypes];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AKABindingExpressionSpecification registerOptionsType:@"NSStringCompareOptions"
                                              withValuesByName:[AKANSEnumerations stringCompareOptions]];
    });
}

- (NSFormatter*)defaultFormatter
{
    return [AKAAttributedFormatter new];
}

- (NSFormatter*)createMutableFormatter
{
    return [AKAAttributedFormatter new];
}

@end
