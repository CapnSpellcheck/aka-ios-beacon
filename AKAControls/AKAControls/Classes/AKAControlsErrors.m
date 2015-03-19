//
//  AKAControlsErrors.m
//  AKACommons
//
//  Created by Michael Utech on 12.03.15.
//  Copyright (c) 2015 AKA Sarl. All rights reserved.
//

#import "AKAControlsErrors.h"
#import "AKALog.h"

@implementation AKAControlsErrors

static NSString* const akaControlsErrorDomain = @"com.aka-labs.errors.AKAControls";
static BOOL _attemptRecoveryActions = YES;

+ (NSString *)akaControlsErrorDomain
{
    return akaControlsErrorDomain;
}

+ (BOOL)attemptRecoveryActions
{
    return _attemptRecoveryActions;
}

+ (void)setAttemptRecoveryActions:(BOOL)attemptRecoveryActions
{
    _attemptRecoveryActions = attemptRecoveryActions;
}

+ (void)handleErrorWithMessage:(NSString*)message
                      recovery:(BOOL (^)())recover
{
    BOOL recovered = NO;
    if (recover != nil && [self attemptRecoveryActions])
    {
        AKALogWarn(@"%@", message);
        AKALogInfo(@"Attempting to recover from previous error...");
        recovered = recover();
        if (!recovered)
        {
            AKALogError(@"Recovery action for error \"%@\" failed", message);
        }
    }

    if (!recovered)
    {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:message
                                     userInfo:nil];

    }
}

#pragma mark - Composite Control Member Activation

+ (void)invalidAttemptToActivateNonMemberControl:(AKAControl *)control
                                      inComposite:(AKACompositeControl *)composite
{
    NSString* message = [NSString stringWithFormat:@"Attempt to activate control %@ which is not a direct member of %@", control, composite];
    [self handleErrorWithMessage:message recovery:nil];
}

+ (void)    invalidAttemptToActivate:(AKAControl *)control
                         inComposite:(AKACompositeControl *)composite
     whileAnotherMemberIsStillActive:(AKAControl *)oldActive
                            recovery:(BOOL (^)())recover
{
    NSString* message = [NSString stringWithFormat:@"Attempt to activate control %@ while another member control %@ is active in composite control %@", control, oldActive, composite];
    [self handleErrorWithMessage:message recovery:recover];
}

@end
