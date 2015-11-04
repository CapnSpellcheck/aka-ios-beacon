//
//  UITextField+AKAIBBindingProperties.m
//  AKABeacon
//
//  Created by Michael Utech on 20.09.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import AKACommons.AKANullability;
@import AKACommons.AKALog;
@import AKACommons.NSObject_AKAAssociatedValues;

#import "UITextField+AKAIBBindingProperties.h"
#import "AKABindingProvider_UITextField_textBinding.h"
#import "AKAKeyboardControl.h"

@implementation UITextField(AKAIBBindingProperties)

- (NSString *)              textBinding_aka
{
    AKABindingProvider_UITextField_textBinding* provider =
        [AKABindingProvider_UITextField_textBinding sharedInstance];

    return [provider bindingExpressionTextForSelector:@selector(textBinding_aka)
                                               inView:self];
}

- (void)                 setTextBinding_aka:(opt_NSString)textBinding_aka
{
    AKABindingProvider_UITextField_textBinding* provider =
        [AKABindingProvider_UITextField_textBinding sharedInstance];

    [provider setBindingExpressionText:textBinding_aka
                           forSelector:@selector(textBinding_aka)
                                inView:self];
}

- (AKAMutableControlConfiguration*)aka_controlConfiguration
{

    NSString* key = NSStringFromSelector(@selector(aka_controlConfiguration));
    AKAMutableControlConfiguration* result = [self aka_associatedValueForKey:key];
    if (result == nil)
    {
        result = [AKAMutableControlConfiguration new];
        result[kAKAControlTypeKey] = [AKAKeyboardControl class];
        result[kAKAControlViewBinding] = NSStringFromSelector(@selector(textBinding_aka));
        [self aka_setAssociatedValue:result forKey:key];
    }
    return result;
}

- (void)aka_setControlConfigurationValue:(id)value forKey:(NSString *)key
{
    AKAMutableControlConfiguration* mutableConfiguration = (AKAMutableControlConfiguration*)self.aka_controlConfiguration;
    if (value == nil)
    {
        [mutableConfiguration removeObjectForKey:key];
    }
    else
    {
        mutableConfiguration[key] = value;
    }
}

@end

