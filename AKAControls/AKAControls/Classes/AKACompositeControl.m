//
//  AKACompositeControl.m
//  AKACommons
//
//  Created by Michael Utech on 12.03.15.
//  Copyright (c) 2015 AKA Sarl. All rights reserved.
//

#import "AKACompositeControl.h"
#import "AKAControl_Internal.h"
#import "AKAControlViewProtocol.h"
#import "AKAViewBinding.h"
#import "AKAKeyboardActivationSequence.h"
#import "AKAControlsErrors_Internal.h"

#import "UIView+AKAHierarchyVisitor.h"

@interface AKACompositeControl()

@property(nonatomic, strong) NSMutableArray* controlsStorage;
@property(nonatomic) NSUInteger activeControlIndex;

@end

@implementation AKACompositeControl

@synthesize activeControl = _activeControl;

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.controlsStorage = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Member Controls

#pragma mark Access to Member Controls

- (NSArray*)controls
{
    return [NSArray arrayWithArray:self.controlsStorage];
}

- (NSUInteger)indexOfControl:(AKAControl*)control
{
    return [self.controlsStorage indexOfObjectIdenticalTo:control];
}

- (void)enumerateControlsUsingBlock:(void(^)(AKAControl* control, NSUInteger index, BOOL* stop))block
{
    [self enumerateControlsUsingBlock:block startIndex:0 continueInOwner:NO];
}

- (void)enumerateControlsUsingBlock:(void(^)(AKAControl* control, NSUInteger index, BOOL* stop))block
                         startIndex:(NSUInteger)startIndex
                    continueInOwner:(BOOL)continueInOwner
{
    __block BOOL localStop = NO;
    if (startIndex < self.controlsStorage.count)
    {
        NSRange range = NSMakeRange(startIndex, self.controlsStorage.count - startIndex);
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.controlsStorage enumerateObjectsAtIndexes:indexSet
                                                options:(NSEnumerationOptions)0
                                             usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                 block(obj, idx, &localStop);
                                                 *stop = localStop;
                                             }];
    }
    AKACompositeControl* owner = self.owner;
    if (!localStop && continueInOwner && owner)
    {
        NSUInteger index = [owner indexOfControl:self];
        [owner enumerateControlsUsingBlock:block startIndex:index+1 continueInOwner:continueInOwner];
    }
}

- (void)enumerateLeafControlsUsingBlock:(void(^)(AKAControl* control, AKACompositeControl* owner, NSUInteger index, BOOL* stop))block
{
    [self enumerateLeafControlsUsingBlock:block startIndex:0 continueInOwner:NO];
}

- (void)enumerateLeafControlsUsingBlock:(void(^)(AKAControl* control, AKACompositeControl* owner, NSUInteger index, BOOL* stop))block
                             startIndex:(NSUInteger)startIndex
                        continueInOwner:(BOOL)continueInOwner
{
    [self enumerateControlsUsingBlock:^(AKAControl* control, NSUInteger idx, BOOL *stop) {
        __block BOOL localStop = NO;
        if ([control isKindOfClass:[AKACompositeControl class]])
        {
            AKACompositeControl* composite = (AKACompositeControl*)control;
            [composite enumerateLeafControlsUsingBlock:^(AKAControl* control, AKACompositeControl* owner, NSUInteger idx, BOOL* stop) {
                block(control, owner, idx, &localStop);
                *stop = localStop;
            }
                                            startIndex:0
                                       continueInOwner:NO]; // NO: this instance handles siblings
        }
        else
        {
            block(control, self, idx, &localStop);
        }
        *stop = localStop;
    }
                                          startIndex:startIndex
                                     continueInOwner:continueInOwner];
}

#pragma mark Adding and Removing Member Controls

- (NSUInteger)addControlsForControlViewsInViewHierarchy:(UIView*)rootView
{
    return [self insertControlsForControlViewsInViewHierarchy:rootView
                                                      atIndex:self.controlsStorage.count];
}

- (NSUInteger)insertControlsForControlViewsInViewHierarchy:(UIView*)rootView
                                                   atIndex:(NSUInteger)index
{
    NSUInteger __block count = 0;
    [rootView aka_enumerateSubviewsUsingBlock:^(UIView *view, BOOL *stop, BOOL *doNotDescend) {
        (void)stop; // not used
        if ([view conformsToProtocol:@protocol(AKAControlViewProtocol)])
        {
            AKAControl* control = nil;
            count += [self insertControl:&control
                          forControlView:(id)view
                                 atIndex:index + count];
            if ([control isKindOfClass:[AKACompositeControl class]])
            {
                *doNotDescend = YES;
            }
        }
    }];
    return count;
}

- (NSUInteger)insertControl:(out AKAControl**)controlStorage
             forControlView:(UIView<AKAControlViewProtocol>*)view
                    atIndex:(NSUInteger)index
{
    AKAViewBindingConfiguration* configuration = view.bindingConfiguration;
    return [self insertControl:controlStorage
                       forView:view
             withConfiguration:configuration
                       atIndex:index];
}

- (NSUInteger)insertControl:(out AKAControl**)controlStorage
                    forView:(UIView*)view
          withConfiguration:(AKAViewBindingConfiguration*)configuration
                    atIndex:(NSUInteger)index
{
    NSUInteger count = 0;

    Class controlType = configuration.preferredControlType;
    AKAControl* control;
    NSString* keyPath = configuration.valueKeyPath;
    if (keyPath.length > 0)
    {
        control = [[controlType alloc] initWithOwner:self
                                             keyPath:configuration.valueKeyPath];
    }
    else
    {
        control = [[controlType alloc] initWithOwner:self];
    }

    Class bindingType = configuration.preferredBindingType;
    AKAViewBinding* binding = [[bindingType alloc] initWithView:view
                                                  configuration:configuration
                                                       delegate:control];
    control.viewBinding = binding;
    if ([self insertControl:control atIndex:index + count])
    {
        ++count;
        if ([control isKindOfClass:[AKACompositeControl class]] && binding.view != nil)
        {
            AKACompositeControl* composite = (AKACompositeControl*)control;
            [composite addControlsForControlViewsInViewHierarchy:binding.view];
        }
    }

    if (controlStorage != nil)
    {
        *controlStorage = control;
    }
    return count;
}

- (NSUInteger)addControlsForControlViewsInOutletCollection:(NSArray*)outletCollection
{
    return [self insertControlsForControlViewsInOutletCollection:outletCollection
                                                   atIndex:0];
}

- (NSUInteger)insertControlsForControlViewsInOutletCollection:(NSArray*)outletCollection
                                                       atIndex:(NSUInteger)index
{
    NSUInteger count = 0;
    for (UIView* view in outletCollection)
    {
        if ([view conformsToProtocol:@protocol(AKAControlViewProtocol)])
        {
            count += [self insertControl:nil
                          forControlView:(id)view
                                 atIndex:index + count];
        }
        else
        {
            count += [self insertControlsForControlViewsInViewHierarchy:view
                                                                atIndex:index + count];
        }
    }
    return count;
}

- (NSUInteger)addControlsForControlViewsInOutletCollections:(NSArray*)arrayOfOutletCollections
{
    return [self insertControlsForControlViewsInOutletCollections:arrayOfOutletCollections
                                                   atIndex:0];
}

- (NSUInteger)insertControlsForControlViewsInOutletCollections:(NSArray*)arrayOfOutletCollections
                                                       atIndex:(NSUInteger)index
{
    NSUInteger count = 0;
    for (NSArray* outletCollection in arrayOfOutletCollections)
    {
        AKACompositeControl* collectionControl = [[AKACompositeControl alloc] initWithOwner:self keyPath:nil];
        if ([self insertControl:collectionControl atIndex:index + count])
        {
            ++count;
            [collectionControl addControlsForControlViewsInOutletCollection:outletCollection];
        }
    }
    return count;
}

- (NSUInteger)addControlsForControlViewsInStaticTableView:(UITableView*)tableView
{
    return [self insertControlsForControlViewsInStaticTableView:tableView
                                                      atIndex:self.controlsStorage.count];
}

- (NSUInteger)insertControlsForControlViewsInStaticTableView:(UITableView*)tableView
                                                     atIndex:(NSUInteger)index
{
    NSUInteger __block count = 0;
    for (NSInteger sectionIndex = 0; sectionIndex < tableView.numberOfSections; ++sectionIndex)
    {
        for (NSInteger rowIndex = 0; rowIndex < [tableView numberOfRowsInSection:sectionIndex]; ++rowIndex)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
            UIView* rootView = cell.contentView;
            [rootView aka_enumerateSubviewsUsingBlock:^(UIView *view, BOOL *stop, BOOL *doNotDescend) {
                (void)stop; // not used
                if ([view conformsToProtocol:@protocol(AKAControlViewProtocol)])
                {
                    UIView<AKAControlViewProtocol>* controlView = (id)view;
                    AKAControl* control = nil;
                    if ([self insertControl:&control forControlView:controlView atIndex:index + count])
                    {
                        ++count;
                        *doNotDescend = YES;
                        if ([control isKindOfClass:[AKACompositeControl class]] && control.view != nil)
                        {
                            AKACompositeControl* composite = (AKACompositeControl*)control;
                            [composite addControlsForControlViewsInViewHierarchy:control.view];
                        }
                    }
                }
            }];
        }
    }

    return count;
}

- (BOOL)addControl:(AKAControl*)control
{
    return [self insertControl:control atIndex:self.controlsStorage.count];
}

- (BOOL)insertControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    NSParameterAssert(control != nil);
    NSParameterAssert(index <= self.controlsStorage.count);

    BOOL result = [self shouldAddControl:control atIndex:index];
    if (result)
    {
        [self willAddControl:control atIndex:index];
        [self.controlsStorage insertObject:control atIndex:index];
        [self didAddControl:control atIndex:index];
    }
    return result;
}

- (BOOL)removeControl:(AKAControl*)control
{
    NSUInteger index = [self.controlsStorage indexOfObjectIdenticalTo:control];
    return [self removeControl:control atIndex:index];
}

- (BOOL)removeControlAtIndex:(NSUInteger)index
{
    BOOL result = index <= self.controlsStorage.count;
    if (result)
    {
        AKAControl* control = [self.controlsStorage objectAtIndex:index];
        result = [self removeControl:control atIndex:index];
    }
    return result;
}

- (BOOL)removeControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    BOOL result = [self shouldRemoveControl:control atIndex:index];
    if (result)
    {
        [self willRemoveControl:control atIndex:index];
        [self.controlsStorage removeObjectAtIndex:index];
        [self didRemoveControl:control atIndex:index];
    }
    return result;
}

#pragma mark Delegat'ish Methods for Notifications and Customization

- (BOOL)shouldAddControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    AKACompositeControl* owner = control.owner;
    return (index <= self.controlsStorage.count &&
            (owner == nil || owner == self) &&
            ![self.controlsStorage containsObject:control]);
}

- (void)willAddControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    (void)index; // not used

    // If by some ugly means the control changed ownership after we
    // tested it in shouldAddControl, this should throw an exception:
    [control setOwner:self];
}

- (void)didAddControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    (void)control; // not used
    (void)index; // not used
}

- (BOOL)shouldRemoveControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    return (index <= self.controlsStorage.count &&
            control.owner == self &&
            control == [self.controlsStorage objectAtIndex:index]);
}

- (void)willRemoveControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    (void)control; // not used
    (void)index; // not used
}

- (void)didRemoveControl:(AKAControl*)control atIndex:(NSUInteger)index
{
    (void)index; // not used

    [control setOwner:nil];
}

#pragma mark - Change Tracking

#pragma mark Controlling Observation

- (void)startObservingOtherChanges
{
    [super startObservingOtherChanges];
    for (AKAControl* control in self.controlsStorage)
    {
        [control startObservingOtherChanges];
    }
}

- (void)stopObservingOtherChanges
{
    for (AKAControl* control in self.controlsStorage)
    {
        [control stopObservingOtherChanges];
    }
    [super stopObservingOtherChanges];
}

- (BOOL)isObservingViewValueChanges
{
    // return YES if any control is observing
    BOOL result = NO;

    result |= [super isObservingViewValueChanges];
    for (AKAControl* control in self.controlsStorage)
    {
        result |= control.isObservingViewValueChanges;
        if (result)
        {
            break;
        }
    }

    return result;
}

- (BOOL)startObservingViewValueChanges
{
    // return YES if any control started, start self then members
    BOOL result = NO;

    result |= [super startObservingViewValueChanges];
    for (AKAControl* control in self.controlsStorage)
    {
        result |= [control startObservingViewValueChanges];
    }

    return result;
}

- (BOOL)stopObservingViewValueChanges
{
    // return YES if all controls stopped, stop members then self
    BOOL result = YES;

    for (AKAControl* control in self.controlsStorage)
    {
        result &= [control stopObservingViewValueChanges];
    }
    result &= [super stopObservingViewValueChanges];

    return result;
}

- (BOOL)isObservingModelValueChanges
{
    // return YES if any control is observing
    BOOL result = NO;

    result |= [super isObservingModelValueChanges];
    for (AKAControl* control in self.controlsStorage)
    {
        result |= control.isObservingModelValueChanges;
        if (result)
        {
            break;
        }
    }
    return result;
}

- (BOOL)startObservingModelValueChanges
{
    // return YES if any control started, start self then members
    BOOL result = NO;

    result |= [super startObservingModelValueChanges];
    for (AKAControl* control in self.controlsStorage)
    {
        result |= [control startObservingModelValueChanges];
    }

    return result;
}

- (BOOL)stopObservingModelValueChanges
{
    // return YES if all controls stopped, stop members then self
    BOOL result = YES;

    for (AKAControl* control in self.controlsStorage)
    {
        result &= [control stopObservingModelValueChanges];
    }
    result &= [super stopObservingModelValueChanges];

    return result;
}

#pragma mark - Activation

- (BOOL)activate
{
    BOOL result = self.isActive;
    if (!result)
    {
        result = [super activate];
    }
    if (!result)
    {
        __block AKAControl* autoActivatable;
        __block AKAControl* activatable;
        [self enumerateControlsUsingBlock:^(AKAControl *control, NSUInteger index, BOOL *stop) {
            (void)index; // not needed

            if ([control canActivate])
            {
                if (!activatable)
                {
                    activatable = control;
                }
                if ([control shouldAutoActivate])
                {
                    autoActivatable = control;
                }
                *stop = autoActivatable != nil;
            }
        }];
        if (autoActivatable)
        {
            result = [autoActivatable activate];
        }
        else if (activatable)
        {
            result = [activatable activate];
        }
    }
    return result;
}

- (BOOL)deactivate
{
    BOOL result = !self.isActive;
    if (!result)
    {
        if (self.activeControl)
        {
            result = [self.activeControl deactivate];
        }
        if (!result)
        {
            // Do not deactivate if active member failed to deactivate
            result = [super deactivate];
        }
    }
    return result;
}

/**
 * Determines whether this control can be activated. This is true if either the associated
 * view binding indicates that the bound view supports activation or if any of the member
 * controls can activate.
 *
 * @return YES if the composite control directly or any of its members can be activated.
 */
- (BOOL)canActivate
{
    __block BOOL result = [super canActivate];
    if (!result)
    {
        [self enumerateControlsUsingBlock:^(AKAControl *control, NSUInteger index, BOOL *stop) {
            result = *stop = control.canActivate;
        }];
    }
    return result;
}

/**
 * Determines whether this control should be activated automatically. This is true if either the
 * associated view binding indicates that the bound view or any of the member controls should
 * be automatically activated.
 *
 * @return YES if the composite control directly or any of its members should be activated automatically.
 */
- (BOOL)shouldAutoActivate
{
    __block BOOL result = [super shouldAutoActivate];
    if (!result)
    {
        [self enumerateControlsUsingBlock:^(AKAControl *control, NSUInteger index, BOOL *stop) {
            result = *stop = [control shouldAutoActivate];
        }];
    }
    return result;
}

- (BOOL)shouldActivate
{
    return [super shouldActivate];
}

- (BOOL)shouldDeactivate
{
    return [super shouldActivate];
}

- (void)setActiveControl:(AKAControl *)activeControl
{
    AKAControl* oldActive = self.activeControl;
    if (activeControl == nil)
    {
        _activeControl = nil;
        _activeControlIndex = NSNotFound;
    }
    else
    {
        NSUInteger index = [self.controlsStorage indexOfObjectIdenticalTo:activeControl];
        if (index == NSNotFound)
        {
            [AKAControlsErrors invalidAttemptToActivateNonMemberControl:activeControl
                                                             inComposite:self];
        }
        if (activeControl != nil && oldActive != nil)
        {
            [AKAControlsErrors invalidAttemptToActivate:activeControl
                                            inComposite:self
                        whileAnotherMemberIsStillActive:oldActive
                                               recovery:^BOOL
            {
                [self setActiveControl:nil];
                return YES;
            }];

        }
        [self controlDidActivate:oldActive];
        _activeControl = activeControl;
        _activeControlIndex = index;
    }
}

#pragma mark Keyboard Activation Sequence

- (AKAKeyboardActivationSequence*)keyboardActivationSequence
{
    return self.owner.keyboardActivationSequence;
}

- (BOOL)participatesInKeyboardActivationSequence
{
    BOOL __block result = NO;
    [self enumerateControlsUsingBlock:^(AKAControl *control, NSUInteger index, BOOL *stop) {
        result |= control.participatesInKeyboardActivationSequence;
        *stop = result;
    }];
    return result;
}

#pragma mark Member Activation

/**
 * Determines if the specified control should be activated by first consulting
 * the delegate and then owner controls (transitively). If no delegate or owner
 * (including their delegates) vetoed and then all controls that would have to
 * be deactivate should do so, the result is YES.
 *
 * @param memberControl the member control
 *
 * @return YES if the specified member control should be updated.
 */
- (BOOL)shouldControlActivate:(AKAControl*)memberControl
{
    BOOL result = !memberControl.isActive;

    if (result)
    {
        // Let this instances delegate decide first
        id<AKAControlDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(shouldControlActivate:)])
        {
            result = [delegate shouldControlActivate:memberControl];
        }
    }

    if (result)
    {
        AKACompositeControl* owner = self.owner;
        if (owner != nil)
        {
            // Ascend the control tree to ensure all delegates
            // have been consulted first.
            result = [owner shouldControlActivate:memberControl];
        }

        // At this point, all ancestor delegates approved activation

        if (result && memberControl.owner == self)
        {
            if (self.isActive)
            {
                if (self.activeControl != nil)
                {
                    // This is the junction point between the current
                    // and future active control path and it is responsible to
                    // check if a currently active control and its transitive
                    // owners should be deactivated.
                    result = [self shouldDeactivateActiveSubtree];
                }
            }
            else if (owner != nil)
            {
                result = [self.owner shouldControlActivate:self];
            }
        }
    }

    return result;
}

- (void)controlWillActivate:(AKAControl *)memberControl
{
    id<AKAControlDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(controlWillActivate:)])
    {
        [delegate controlWillActivate:memberControl];
    }
    [self.owner controlWillActivate:memberControl];
}

- (void)controlDidActivate:(AKAControl*)memberControl
{
    if (memberControl.owner == self)
    {
        if (self.activeControl != nil && self.activeControl != memberControl)
        {
            // This should not be necessary, because they should have deactivated
            // before another control activated, just to be sure:
            [self.activeControl didDeactivate];
            if (self.activeControl != nil)
            {
                [self controlDidDeactivate:self.activeControl];
            }
        }

        [self setActiveControl:memberControl];
        if (!self.isActive)
        {
            [self didActivate];
        }
    }

    id<AKAControlDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(controlDidActivate:)])
    {
        [delegate controlDidActivate:memberControl];
    }
    [self.owner controlDidActivate:memberControl];
}

- (BOOL)shouldControlDeactivate:(AKAControl*)memberControl
{
    BOOL result = memberControl.isActive;

    // Let this instances delegate decide first
    id<AKAControlDelegate> delegate = self.delegate;
    if (result && [delegate respondsToSelector:@selector(shouldControlDeactivate:)])
    {
        result = [delegate shouldControlDeactivate:memberControl];
    }

    AKACompositeControl* owner = self.owner;
    if (result && owner)
    {
        result = [owner shouldControlDeactivate:memberControl];
    }

    return result;
}

- (void)controlWillDeactivate:(AKAControl *)memberControl
{
    id<AKAControlDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(controlWillDeactivate:)])
    {
        [delegate controlWillDeactivate:memberControl];
    }
    [self.owner controlWillDeactivate:memberControl];
}

- (void)controlDidDeactivate:(AKAControl*)memberControl
{
    if (memberControl.owner == self)
    {
        [self setActiveControl:nil];
    }
    id<AKAControlDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(controlDidDeactivate:)])
    {
        [delegate controlDidDeactivate:memberControl];
    }
    [self.owner controlDidDeactivate:memberControl];
}

#pragma mark - Implementation

- (BOOL)shouldDeactivateActiveSubtree
{
    // TODO: implement
    return YES;
}


- (AKAControl*)activeMemberLeafControl
{
    AKAControl* result = nil;
    if (self.isActive)
    {
        result = self.activeControl;
        if ([result isKindOfClass:[AKACompositeControl class]])
        {
            AKACompositeControl* control = (AKACompositeControl*)result;
            if (control.activeControl)
            {
                result = [control activeMemberLeafControl];
            }
        }
    }
    return result;
}

- (AKAControl*)activeLeafControl
{
    AKAControl* result = nil;
    if (self.isActive)
    {
        result = [self activeMemberLeafControl];
        if (result == nil)
        {
            result = self;
        }
    }
    else
    {
        result = [self.owner activeLeafControl];
    }
    return result;
}

- (AKAControl*)directMemberControl:(AKAControl*)control
{
    AKAControl* result = nil;

    if (control != nil && control != self)
    {
        if (control.owner == self)
        {
            result = control;
        }
        else
        {
            result = [self directMemberControl:control.owner];
        }
    }
    return result;
}

@end