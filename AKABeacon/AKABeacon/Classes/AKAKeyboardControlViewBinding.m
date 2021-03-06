//
//  AKAKeyboardControlViewBinding.m
//  AKABeacon
//
//  Created by Michael Utech on 13.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

#import "AKAErrors.h"

#import "AKAKeyboardControlViewBinding.h"
#import "AKAKeyboardControlViewBinding+DelegateSupport.h"

#import "AKAKeyboardActivationSequenceItemProtocol_Internal.h"
#import "AKAKeyboardActivationSequence.h"

#import "AKACompositeControl+BindingDelegatePropagation.h"

NSString *const kDefaultKeyboardActivationSequenceIdentifier = @"DEFAULT";

@interface AKAKeyboardControlViewBinding ()
{
    __weak AKAKeyboardActivationSequence* _keyboardActivationSequence;
    UIView*                               _savedInputAccessoryView;
}
@end

@implementation AKAKeyboardControlViewBinding

@dynamic delegate;

+ (AKABindingSpecification *)specification
{
    static AKABindingSpecification* result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary* spec =
        @{ @"bindingType":          [AKAKeyboardControlViewBinding class],
           @"targetType":           [UIResponder class],
           @"expressionType":       @(AKABindingExpressionTypeAny),
           @"attributes":
               @{ @"liveModelUpdates":
                      @{ @"expressionType":  @(AKABindingExpressionTypeBoolean),
                         @"use":             @(AKABindingAttributeUseAssignValueToBindingProperty)
                         },
                  @"autoActivate":
                      @{ @"expressionType":  @(AKABindingExpressionTypeBoolean),
                         @"use":             @(AKABindingAttributeUseAssignValueToBindingProperty)
                         },
                  @"KBActivationSequence":
                      @{ @"expressionType":  @(AKABindingExpressionTypeBoolean),
                         @"use":             @(AKABindingAttributeUseAssignValueToBindingProperty),
                         @"bindingProperty": @"shouldParticipateInKeyboardActivationSequence"
                         },
                  @"KBActivationSequenceID":
                      @{ @"expressionType":  @(AKABindingExpressionTypeStringConstant),
                         @"use":             @(AKABindingAttributeUseAssignValueToBindingProperty),
                         @"bindingProperty": @"keyboardActivationSequenceID"
                         },
                  }
           };
        result = [[AKABindingSpecification alloc] initWithDictionary:spec basedOn:[AKAControlViewBinding specification]];
    });
    return result;
}

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init])
    {
        self.shouldParticipateInKeyboardActivationSequence = YES;
        self.autoActivate = NO;
        self.liveModelUpdates = YES;
        _keyboardActivationSequenceID = kDefaultKeyboardActivationSequenceIdentifier;
    }
    return self;
}

#pragma mark - Properties

- (opt_UIView)                    responderInputAccessoryView
{
    return self.responderForKeyboardActivationSequence.inputAccessoryView;
}

- (void)                       setResponderInputAccessoryView:(opt_UIView)inputAccessoryView
{
    UIResponder* responder = self.responderForKeyboardActivationSequence;

    if ([responder respondsToSelector:@selector(setInputAccessoryView:)])
    {
        [responder performSelector:@selector(setInputAccessoryView:) withObject:inputAccessoryView];
    }
    else
    {
        AKAErrorAbstractMethodImplementationMissing();
    }
}

@end


@interface AKAKeyboardControlViewBinding (KeyboardActivationSequence_Internal) <
    AKAKeyboardActivationSequenceItemProtocol_Internal
    >
- (void)                        setKeyboardActivationSequence:(AKAKeyboardActivationSequence*)keyboardActivationSequence;
@end

@implementation AKAKeyboardControlViewBinding (KeyboardActivationSequence_Internal)

- (void)                        setKeyboardActivationSequence:(AKAKeyboardActivationSequence*)keyboardActivationSequence
{
    AKAKeyboardActivationSequence* current = _keyboardActivationSequence;
    if (keyboardActivationSequence != current)
    {
        NSAssert(keyboardActivationSequence == nil || current == nil,
                 @"Invalid attempt to join keyboard activation sequence %@, %@ is already member of sequence %@", keyboardActivationSequence, self, current);

        _keyboardActivationSequence = keyboardActivationSequence;
    }
}

@end

@implementation AKAKeyboardControlViewBinding (KeyboardActivationSequence)


- (BOOL)             participatesInKeyboardActivationSequence
{
    return self.keyboardActivationSequence != nil;
}

- (AKAKeyboardActivationSequence*)keyboardActivationSequence
{
    return _keyboardActivationSequence;
}

- (opt_UIResponder)    responderForKeyboardActivationSequence
{
    return self.target;
}

#pragma mark - Activation (First Responder)

- (BOOL)                                    isResponderActive
{
    return self.responderForKeyboardActivationSequence.isFirstResponder;
}

- (BOOL)                                    activateResponder
{
    UIResponder* responder = self.responderForKeyboardActivationSequence;
    BOOL result = [self shouldResponderActivate:responder];

    if (result)
    {
        [self responderWillActivate:responder];
        result = [responder becomeFirstResponder];

        if (result)
        {
            [self responderDidActivate:responder];
        }
    }

    return result;
}

- (BOOL)                                  deactivateResponder
{
    UIResponder* responder = self.responderForKeyboardActivationSequence;
    BOOL result = [self shouldResponderDeactivate:responder];

    if (responder != nil)
    {
        [self responderWillDeactivate:responder];
        result = [responder resignFirstResponder];

        if (result)
        {
            [self responderDidDeactivate:responder];
        }
    }

    return result;
}

- (BOOL)                            installInputAccessoryView:(req_UIView)inputAccessoryView
{
    if ((UIView*)inputAccessoryView != self.responderInputAccessoryView)
    {
        NSAssert(_savedInputAccessoryView == nil,
                 @"previously installed input accessory view was not restored");
        _savedInputAccessoryView = self.responderInputAccessoryView;
        self.responderInputAccessoryView = inputAccessoryView;
    }

    return self.responderInputAccessoryView == inputAccessoryView;
}

- (BOOL)                            restoreInputAccessoryView
{
    self.responderInputAccessoryView = _savedInputAccessoryView;
    BOOL result = self.responderInputAccessoryView == _savedInputAccessoryView;
    _savedInputAccessoryView = nil;

    return result;
}

@end
