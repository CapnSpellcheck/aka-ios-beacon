//
//  AKABeaconNullability.h
//  AKABeacon
//
//  Created by Michael Utech on 06.02.16.
//  Copyright © 2016 Michael Utech & AKA Sarl. All rights reserved.
//

#import "AKANullability.h"

#ifndef AKABeaconNullability_h
#define AKABeaconNullability_h

/*
 Provides forward declarations and nullability macros for AKABeacon types. Please refer to AKACommons.Nullability for an explanation why we are using nullability macros.

 The reason for providing forward declaration is to reduce the amount of cross forward declarations in object/delegate pairs and to reduce include dependency graphs to dependencies which actually require the declaration of a type and not just it's presence.
 
 TODO: we are updating this file progressively as we proceed cleaning up the code base.
 */

#pragma mark - Bindings

@class AKABindingExpression;
#define req_AKABindingExpression AKABindingExpression*_Nonnull
#define opt_AKABindingExpression AKABindingExpression*_Nullable
#define out_AKABindingExpression AKABindingExpression* _Nullable __autoreleasing* _Nullable

@class AKABinding;
#define req_AKABinding AKABinding*_Nonnull
#define opt_AKABinding AKABinding*_Nullable

@protocol AKABindingOwnerProtocol;
#define req_AKABindingOwner id<AKABindingOwnerProtocol>_Nonnull
#define opt_AKABindingOwner id<AKABindingOwnerProtocol>_Nullable

@protocol AKABindingDelegate;
#define req_AKABindingDelegate id<AKABindingDelegate>_Nonnull
#define opt_AKABindingDelegate id<AKABindingDelegate>_Nullable


@class AKAControlViewBinding;
#define req_AKAControlViewBinding AKAControlViewBinding*_Nonnull
#define opt_AKAControlViewBinding AKAControlViewBinding*_Nullable

@protocol AKAControlViewBindingDelegate;
#define req_AKAControlViewBindingDelegate id<AKAControlViewBindingDelegate>_Nonnull
#define opt_AKAControlViewBindingDelegate id<AKAControlViewBindingDelegate>_Nullable


@class AKACollectionControlViewBinding;
#define req_AKACollectionControlViewBinding AKACollectionControlViewBinding*_Nonnull
#define opt_AKACollectionControlViewBinding AKACollectionControlViewBinding*_Nullable


@class AKAKeyboardControlViewBinding;
#define req_AKAKeyboardControlViewBinding AKAKeyboardControlViewBinding*_Nonnull
#define opt_AKAKeyboardControlViewBinding AKAKeyboardControlViewBinding*_Nullable

@protocol AKAKeyboardControlViewBindingDelegate;
#define req_AKAKeyboardControlViewBindingDelegate id<AKAKeyboardControlViewBindingDelegate>_Nonnull
#define opt_AKAKeyboardControlViewBindingDelegate id<AKAKeyboardControlViewBindingDelegate>_Nullable

#define opt_AKABindingExpressionAttributes NSDictionary<NSString*, AKABindingExpression*>* _Nullable
#define req_AKABindingExpressionAttributes NSDictionary<NSString*, AKABindingExpression*>* _Nonnull

@class AKABindingController;
#define req_AKABindingController AKABindingController* _Nonnull
#define opt_AKABindingController AKABindingController* _Nullable

@protocol AKABindingControllerDelegate;
#define req_AKABindingControllerDelegate id<AKABindingControllerDelegate> _Nonnull
#define opt_AKABindingControllerDelegate id<AKABindingControllerDelegate> _Nullable

#pragma mark - Controls

@class AKAControl;
#define req_AKAControl AKAControl*_Nonnull
#define opt_AKAControl AKAControl*_Nullable

@class AKACompositeControl;
#define req_AKACompositeControl AKACompositeControl*_Nonnull
#define opt_AKACompositeControl AKACompositeControl*_Nullable

#pragma mark - Cocoa Mappings

@class AKATransitionAnimationParameters;
#define req_AKATransitionAnimationParameters AKATransitionAnimationParameters*_Nonnull
#define opt_AKATransitionAnimationParameters AKATransitionAnimationParameters*_Nullable

#endif /* AKABeaconNullability_h */
