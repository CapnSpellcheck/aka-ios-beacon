//
//  AKATextEditorControlView.m
//  AKABeacon
//
//  Created by Michael Utech on 20.03.15.
//  Copyright (c) 2015 Michael Utech & AKA Sarl. All rights reserved.
//

#import "AKATextEditorControlView.h"
#import "AKAEditorControlView_Protected.h"
#import "AKABeaconErrors.h"
#import "UITextField+AKAIBBindingProperties_textBinding.h"

@implementation AKATextEditorControlView

@synthesize autoActivate = _autoActivate;
@synthesize KBActivationSequence = _KBActivationSequence;
@synthesize liveModelUpdates = _liveModelUpdates;

#pragma mark - AKATextFieldControlViewBindingConfigurationProtocol

- (void)setupDefaultValues
{
    [super setupDefaultValues];
}

#pragma mark - AKAEditorControlView overrides

- (BOOL)autocreateEditor:(out UIView *__autoreleasing *)createdView
{
    UITextField* editor = [[UITextField alloc] initWithFrame:CGRectZero];
    BOOL result = editor != nil;

    if (result)
    {
        editor.textBinding_aka = self.editorValueBinding;

        editor.text = @"";

        *createdView = editor;
    }

    return result;
}

@end

#import "UILabel+AKAIBBindingProperties_textBinding.h"

@implementation AKATextLabelEditorControlView

#pragma mark - AKATextFieldControlViewBindingConfigurationProtocol

- (void)setupDefaultValues
{
    [super setupDefaultValues];
}

#pragma mark - AKAEditorControlView overrides

- (BOOL)autocreateEditor:(out UIView *__autoreleasing *)createdView
{
    UILabel* editor = [[UILabel alloc] initWithFrame:CGRectZero];
    BOOL result = editor != nil;

    if (result)
    {
        editor.textBinding_aka = self.editorValueBinding;

        *createdView = editor;
    }

    return result;
}

@end
