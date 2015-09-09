//
//  AKABindingConfiguration.m
//  AKAControls
//
//  Created by Michael Utech on 06.04.15.
//  Copyright (c) 2015 AKA Sarl. All rights reserved.
//

#import "AKAViewBindingConfiguration.h"
#import "AKAViewBinding.h"
#import "AKAControl.h"

@implementation AKAViewBindingConfiguration

- (Class)preferredBindingType
{
    return [AKAViewBinding class];
}

- (Class)preferredControlType
{
    return [AKAControl class];
}

- (Class)preferredViewType
{
    return [UIView class];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        self.controlName = [decoder decodeObjectForKey:@"controlName"];
        self.controlTags = [decoder decodeObjectForKey:@"controlTags"];
        self.role = [decoder decodeObjectForKey:@"role"];
        self.valueKeyPath = [decoder decodeObjectForKey:@"valueKeyPath"];
        self.converterKeyPath = [decoder decodeObjectForKey:@"converterKeyPath"];
        self.validatorKeyPath = [decoder decodeObjectForKey:@"validatorKeyPath"];
        self.readOnly = ((NSNumber*)[decoder decodeObjectForKey:@"readOnly"]).boolValue;
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.controlName forKey:@"controlName"];
    [coder encodeObject:self.controlTags forKey:@"controlTags"];
    [coder encodeObject:self.role forKey:@"role"];
    [coder encodeObject:self.valueKeyPath forKey:@"valueKeyPath"];
    [coder encodeObject:self.converterKeyPath forKey:@"converterKeyPath"];
    [coder encodeObject:self.validatorKeyPath forKey:@"validatorKeyPath"];
    [coder encodeObject:@(self.readOnly) forKey:@"readOnly"];
}

@end