#import <sys/cdefs.h>//
//  AKACompositeControl.m
//  AKACommons
//
//  Created by Michael Utech on 12.03.15.
//  Copyright (c) 2015 Michael Utech & AKA Sarl. All rights reserved.
//

#import "AKALog.h"
#import "NSObject+AKAConcurrencyTools.h"
#import "UIView+AKAHierarchyVisitor.h"

#import "AKACompositeControl.h"
#import "AKATableViewCellCompositeControl.h"
#import "AKAControl_Internal.h"
#import "AKAControlViewProtocol.h"

@interface AKACompositeControl ()

@property(nonatomic, strong) NSMutableArray<AKAControl*>*  controlsStorage;
@property(nonatomic) NSUInteger activeControlIndex;

@end


@implementation AKACompositeControl

#pragma mark - Initialization

- (instancetype)                                     init
{
    self = [super init];

    if (self)
    {
        self.controlsStorage = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark - Adding and Removing Member Controls

- (AKAControl*)createControlForView:(UIView*)view
                  withConfiguration:(AKAControlConfiguration*)configuration
{
    AKAControl* control = nil;
    Class controlType = configuration[kAKAControlTypeKey];

    if ([controlType isSubclassOfClass:[AKAControl class]])
    {
        control = [[controlType alloc] initWithOwner:self
                                       configuration:configuration];
        [control setView:view];
    }

    return control;
}

- (BOOL)                                     insertControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
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

- (BOOL)                              removeControlAtIndex:(NSUInteger)index
{
    BOOL result = index <= self.controlsStorage.count;

    if (result)
    {
        AKAControl* control = self.controlsStorage[index];
        [control stopObservingChanges];
        result = [self removeControl:control atIndex:index];
    }

    return result;
}

- (BOOL)                                     removeControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
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

- (NSUInteger)                           removeAllControls __unused {
    NSUInteger result = 0;

    NSAssert(self.countOfControls <= NSIntegerMax, @"index overflow");
    for (NSInteger i = (NSInteger)self.countOfControls - 1; i >= 0; --i)
    {
        if ([self removeControlAtIndex:(NSUInteger)i])
        {
            ++result;
        }
    }

    return result;
}

- (void)                            moveControlFromIndex:(NSUInteger)fromIndex
                                                 toIndex:(NSUInteger)toIndex
{
    AKAControl* control = self.controlsStorage[fromIndex];

    [self.controlsStorage removeObjectAtIndex:fromIndex];
    [self.controlsStorage insertObject:control atIndex:toIndex > fromIndex ? toIndex - 1 : toIndex];
}

#pragma mark Delegat'ish Methods for Notifications and Customization

- (BOOL)                                  shouldAddControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
{
    AKACompositeControl* owner = control.owner;
    BOOL result = (index <= self.controlsStorage.count &&
                   (owner == nil || owner == self) &&
                   ![self.controlsStorage containsObject:control]);

    if (result)
    {
        result = [self shouldControl:self addControl:control atIndex:index];
    }

    return result;
}

- (void)                                    willAddControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
{
    [self control:self willAddControl:control atIndex:index];

    // If by some ugly means the control changed ownership after we
    // tested it in shouldAddControl, this should throw an exception:
    [control setOwner:self];
}

- (void)                                     didAddControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
{
    [self control:self didAddControl:control atIndex:index];

    if (self.isObservingChanges)
    {
        [control startObservingChanges];
    }
}

- (BOOL)                               shouldRemoveControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
{
    BOOL result = (index <= self.controlsStorage.count &&
                   control.owner == self &&
                   control == self.controlsStorage[index]);

    if (result)
    {
        result = [self shouldControl:self removeControl:control atIndex:index];
    }

    return result;
}

- (void)                                 willRemoveControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
{
    [self control:self willRemoveControl:control fromIndex:index];
    [control stopObservingChanges];
}

- (void)                                  didRemoveControl:(AKAControl*)control
                                                   atIndex:(NSUInteger)index
{
    (void)index; // not used
    [control setOwner:nil];
    [self control:self didRemoveControl:control fromIndex:index];
}

#pragma mark - Change Tracking

#pragma mark Controlling Observation

- (void)                             startObservingChanges
{
    NSAssert([[NSThread currentThread] isMainThread], @"Observation started outside main thread");

    [self aka_performBlockInMainThreadOrQueue:^{
         if (!self.isObservingChanges)
         {
             [super startObservingChanges];
             for (AKAControl* control in self.controlsStorage)
             {
                 [control startObservingChanges];
             }
         }
     }
                            waitForCompletion:YES];
}

- (void)                              stopObservingChanges
{
    NSAssert([[NSThread currentThread] isMainThread], @"Observation stopped outside main thread");

    [self aka_performBlockInMainThreadOrQueue:^{
         // We are not checking if we are observing changes to make double sure to
         // not to leave observations behind which will end in a crash.
         //if (self.isObservingChanges)
         //{
         for (AKAControl* control in self.controlsStorage)
         {
             [control stopObservingChanges];
         }
         [super stopObservingChanges];
         //}
     }
                            waitForCompletion:YES];
}

#pragma mark - Implementation

- (AKAControl*)                        directMemberControl:(AKAControl*)control
{
    AKAControl* result = nil;

    if (control != nil && control != self)
    {
        AKACompositeControl* owner = control.owner;

        if (owner == self)
        {
            result = control;
        }
        else
        {
            result = [self directMemberControl:owner];
        }
    }

    return result;
}

@end


@implementation AKACompositeControl (KeyboardActivationSequence)

- (AKAKeyboardActivationSequence*)keyboardActivationSequence
{
    return self.owner.keyboardActivationSequence;
}

@end

@implementation AKACompositeControl (MemberAccess)

#pragma mark - Accessing Members

- (NSUInteger)                             countOfControls
{
    return self.controlsStorage.count;
}

- (id)                             objectInControlsAtIndex:(NSUInteger)index
{
    return self.controlsStorage[index];
}

- (NSUInteger)                              indexOfControl:(AKAControl*)control
{
    return [self.controlsStorage indexOfObjectIdenticalTo:control];
}

- (void)                       enumerateControlsUsingBlock:(void (^)(req_AKAControl control,
                                                                     NSUInteger index,
                                                                     outreq_BOOL stop))block;
{
    [self enumerateControlsUsingBlock:block startIndex:0 continueInOwner:NO];
}

- (void)                       enumerateControlsUsingBlock:(void (^)(req_AKAControl control,
                                                                     NSUInteger index,
                                                                     outreq_BOOL stop))block
                                                startIndex:(NSUInteger)startIndex
                                           continueInOwner:(BOOL)continueInOwner
{
    __block BOOL localStop = NO;

    if (startIndex < self.controlsStorage.count)
    {
        NSRange range = NSMakeRange(startIndex, self.controlsStorage.count - startIndex);
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.controlsStorage
         enumerateObjectsAtIndexes:indexSet
                           options:(NSEnumerationOptions)0
                        usingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
             block(obj, idx, &localStop);
             *stop = localStop;
         }];
    }
    AKACompositeControl* owner = self.owner;

    if (!localStop && continueInOwner && owner)
    {
        NSUInteger index = [owner indexOfControl:self];
        [owner enumerateControlsUsingBlock:block startIndex:index + 1 continueInOwner:continueInOwner];
    }
}

- (void)            enumerateControlsRecursivelyUsingBlock:(void (^)(req_AKAControl control,
                                                                     opt_AKACompositeControl owner,
                                                                     NSUInteger index,
                                                                     outreq_BOOL stop))block
{
    [self enumerateControlsRecursivelyUsingBlock:block
                                      startIndex:0
                                 continueInOwner:NO];
}

- (void)            enumerateControlsRecursivelyUsingBlock:(void (^)(req_AKAControl control,
                                                                     req_AKACompositeControl owner,
                                                                     NSUInteger index,
                                                                     outreq_BOOL stop))block
                                                startIndex:(NSUInteger)startIndex
                                           continueInOwner:(BOOL)continueInOwner
{
    [self enumerateControlsUsingBlock:^(AKAControl* control, NSUInteger idx, BOOL* stop) {
         __block BOOL localStop = NO;
         block(control, self, idx, &localStop);

         if (!localStop && [control isKindOfClass:[AKACompositeControl class]])
         {
             AKACompositeControl* composite = (AKACompositeControl*)control;
             [composite enumerateControlsRecursivelyUsingBlock:^(AKAControl* innerControl, AKACompositeControl* owner, NSUInteger innerIdx, BOOL* innerStop) {
                  block(innerControl, owner, innerIdx, &localStop);
                  *innerStop = localStop;
              }];
         }
         *stop = localStop;
     }
                           startIndex:startIndex
                      continueInOwner:continueInOwner];
}

- (void)                  enumerateLeafControlsUsingBlock:(void (^)(req_AKAControl control,
                                                                    req_AKACompositeControl owner,
                                                                    NSUInteger index,
                                                                    outreq_BOOL stop))block __unused
{
    [self enumerateLeafControlsUsingBlock:block startIndex:0 continueInOwner:NO];
}

- (void)                   enumerateLeafControlsUsingBlock:(void (^)(req_AKAControl control,
                                                                     req_AKACompositeControl owner,
                                                                     NSUInteger index,
                                                                     outreq_BOOL stop))block
                                                startIndex:(NSUInteger)startIndex
                                           continueInOwner:(BOOL)continueInOwner
{
    [self enumerateControlsUsingBlock:^(AKAControl* control,
                                        NSUInteger idx,
                                        BOOL* stop)
     {
         __block BOOL localStop = NO;

         if ([control isKindOfClass:[AKACompositeControl class]])
         {
             AKACompositeControl* composite = (AKACompositeControl*)control;

             [composite enumerateLeafControlsUsingBlock:^(AKAControl* innerControl,
                                                          AKACompositeControl* innerOwner,
                                                          NSUInteger innerIdx,
                                                          BOOL* innerStop)
              {
                  block(innerControl, innerOwner, innerIdx, &localStop);
                  *innerStop = localStop;
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

@end


@implementation AKACompositeControl (MemberAdditionAndRemoval)

+ (NSArray *)viewsToExcludeFromScanningViewController:(UIViewController *)viewController
{
    NSMutableArray* result = nil;

    if (viewController.childViewControllers.count > 0)
    {
        result = [NSMutableArray new];
        [viewController.childViewControllers enumerateObjectsUsingBlock:
         ^(__kindof UIViewController * _Nonnull vc,
           NSUInteger __unused indx,
           BOOL * _Nonnull __unused stop)
         {
             opt_UIView view = vc.view;
             if (view)
             {
                 [result addObject:(req_UIView)view];
             }
         }];
    }

    return result;
}

#pragma mark Adding and Removing Member Controls

- (BOOL)                                        addControl:(AKAControl*)control __unused
{
    return [self insertControl:control atIndex:self.controlsStorage.count];
}

- (BOOL)                                     removeControl:(AKAControl*)control
{
    NSUInteger index = [self.controlsStorage indexOfObjectIdenticalTo:control];

    return [self removeControl:control atIndex:index];
}

- (NSUInteger)   addControlsForControlViewsInViewHierarchy:(UIView*)rootView
                                              excludeViews:(opt_NSArray)childControllerViews
{
    return [self insertControlsForControlViewsInViewHierarchy:rootView
                                                      atIndex:self.controlsStorage.count
                                                 excludeViews:childControllerViews];
}

- (void)beginInsertingControls
{
    [self controlWillInsertMemberControls:self];
}

- (void)endInsertingControls
{
    [self controlDidEndInsertingMemberControls:self];
}

- (NSUInteger)insertControlsForControlViewsInViewHierarchy:(UIView*)rootView
                                                   atIndex:(NSUInteger)index
                                              excludeViews:(opt_NSArray)childControllerViews
{
    NSUInteger __block count = 0;

    if (![childControllerViews containsObject:rootView])
    {
        [self beginInsertingControls];
        [rootView aka_enumerateSelfAndSubviewsUsingBlock:
         ^(UIView* view, BOOL* stop, BOOL* doNotDescend)
         {
             (void)stop; // not used

             BOOL excludeView = [childControllerViews containsObject:view];
             BOOL createControl = [view conformsToProtocol:@protocol(AKAControlViewProtocol)];

             if (excludeView)
             {
                 // Skip view hierarchy if the view is requested to be excluded (used to ensure
                 // that embedded view controller root views are managed by their proper view controller
                 // and not the enclosing one).
                 *doNotDescend = YES;
             }
             else if (createControl)
             {
                 UIView<AKAControlViewProtocol>* controlView = (id)view;
                 AKAControl* control = [self createControlForView:controlView
                                                withConfiguration:controlView.aka_controlConfiguration];

                 if (control)
                 {
                     [self insertControl:control
                                 atIndex:index + count];

                     // Add bindings and controls (recursively)
                     [control addBindingsForView:view];

                     if ([control isKindOfClass:[AKACompositeControl class]])
                     {
                         *doNotDescend = YES;
                         AKACompositeControl* composite = (AKACompositeControl*)control;
                         [composite autoAddControlsForControlViewSubviewsInViewHierarchy:view
                                                                            excludeViews:childControllerViews];
                     }

                     ++count;
                 }
                 else
                 {
                     NSAssert(NO, @"Failed to create member control in %@ for control view %@", self, controlView);
                     AKALogError(@"Failed to create member control in %@ for control view %@. Trying to recover by attaching defined binding to surrounding composite control. This should not happen, please investigate!", self, controlView);
                     [self addBindingsForView:view];
                 }
             }
             else
             {
                 [self addBindingsForView:view];
             }

             if ([view isKindOfClass:[UIToolbar class]])
             {
                 UIToolbar* toolbar = (id)view;
                 [toolbar.items enumerateObjectsUsingBlock:
                  ^(UIBarButtonItem * _Nonnull item,
                    __unused NSUInteger unusedIndex,
                    __unused BOOL * unusedStop)
                  {
                      // TODO: bar button item is not a view, refactor interface to support cases like this
                      [self addBindingsForView:(id)item];
                  }];
             }
         }];
        [self endInsertingControls];
    }

    return count;
}

- (NSUInteger)autoAddControlsForControlViewSubviewsInViewHierarchy:(UIView*)controlView
                                                      excludeViews:(opt_NSArray)childControllerViews
{
    return [self addControlsForControlViewSubviewsInViewHierarchy:controlView
                                                     excludeViews:childControllerViews];
}

- (NSUInteger)   addControlsForControlViewSubviewsInViewHierarchy:(UIView*)rootView
                                                     excludeViews:(opt_NSArray)childControllerViews
{
    return [self insertControlsForControlViewSubviewsInViewHierarchy:rootView
                                                             atIndex:self.controlsStorage.count
                                                        excludeViews:childControllerViews];
}

- (NSUInteger)insertControlsForControlViewSubviewsInViewHierarchy:(UIView*)rootView
                                                          atIndex:(NSUInteger)index
                                                     excludeViews:(opt_NSArray)childControllerViews
{
    NSUInteger __block count = 0;

    // TODO: refactor: override in AKATableViewCellCompositeControl instead:
    if ([rootView isKindOfClass:[UITableViewCell class]])
    {
        UITableViewCell* cell = (UITableViewCell*)rootView;
        count = [self insertControlsForControlViewsInViewHierarchy:cell.contentView
                                                           atIndex:index
                                                      excludeViews:childControllerViews];
    }
    else
    {
        [rootView aka_enumerateSubviewsUsingBlock:^(UIView* view, BOOL* stop, BOOL* doNotDescend) {
             (void)stop; // not used

             count += [self insertControlsForControlViewsInViewHierarchy:view
                                                                 atIndex:index + count
                                                            excludeViews:childControllerViews];
             *doNotDescend = YES;
         }];
    }

    return count;
}

- (void)      addControlsForControlViewsInOutletCollection:(NSArray*)outletCollection
                                              excludeViews:(opt_NSArray)childControllerViews
{
    [self insertControlsForControlViewsInOutletCollection:outletCollection
                                                  atIndex:0
                                             excludeViews:childControllerViews];
}

- (void)   insertControlsForControlViewsInOutletCollection:(NSArray*)outletCollection
                                                   atIndex:(NSUInteger)index
                                              excludeViews:(opt_NSArray)childControllerViews
{
    NSUInteger count = 0;

    [self beginInsertingControls];
    for (UIView* view in outletCollection)
    {
        count += [self insertControlsForControlViewsInViewHierarchy:view
                                                            atIndex:index + count
                                                       excludeViews:childControllerViews];
    }
    [self endInsertingControls];
}

- (void)     addControlsForControlViewsInOutletCollections:(NSArray<NSArray*>*)arrayOfOutletCollections
                                              excludeViews:(opt_NSArray)childControllerViews
{
    [self insertControlsForControlViewsInOutletCollections:arrayOfOutletCollections
                                                   atIndex:0
                                              excludeViews:childControllerViews];
}

- (void)  insertControlsForControlViewsInOutletCollections:(NSArray<NSArray*>*)arrayOfOutletCollections
                                                   atIndex:(NSUInteger)index
                                              excludeViews:(opt_NSArray)childControllerViews
{
    NSUInteger count = 0;

    [self beginInsertingControls];
    for (NSArray* outletCollection in arrayOfOutletCollections)
    {
        AKACompositeControl* collectionControl = [[AKACompositeControl alloc] initWithOwner:self configuration:nil];

        if ([self insertControl:collectionControl atIndex:index + count])
        {
            ++count;
            [collectionControl addControlsForControlViewsInOutletCollection:outletCollection
                                                               excludeViews:childControllerViews];
        }
    }
    [self endInsertingControls];
}

- (void)       addControlsForControlViewsInStaticTableView:(UITableView*)tableView
                                                dataSource:(id<UITableViewDataSource>)dataSource
                                              excludeViews:(opt_NSArray)childControllerViews
{
    [self insertControlsForControlViewsInStaticTableView:tableView
                                              dataSource:dataSource
                                                 atIndex:self.controlsStorage.count
                                            excludeViews:childControllerViews];
}

- (void)    insertControlsForControlViewsInStaticTableView:(UITableView*)tableView
                                                dataSource:(id<UITableViewDataSource>)dataSource
                                                   atIndex:(NSUInteger)index
                                              excludeViews:(opt_NSArray)childControllerViews
{
    NSUInteger count = 0;
    NSUInteger numberOfSections = (NSUInteger)[dataSource numberOfSectionsInTableView:tableView];

    [self beginInsertingControls];
    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; ++sectionIndex)
    {
        NSUInteger numberOfRows = (NSUInteger)[dataSource tableView:tableView numberOfRowsInSection:sectionIndex];
        for (NSInteger rowIndex = 0; rowIndex < numberOfRows; ++rowIndex)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

            if (cell == nil)
            {
                // Offscreen cells will not be delivered by the table view. Since this method
                // is restricted to static table views, we can reasonably expect that
                // the cells returned by the data source will be the same instances that
                // we would get from the table view.
                cell = [dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
            }

            if ([cell conformsToProtocol:@protocol(AKAControlViewProtocol)])
            {
                UIView<AKAControlViewProtocol>* controlView = (id)cell;
                AKAControl* control = [self createControlForView:controlView
                                               withConfiguration:controlView.aka_controlConfiguration];

                // Add bindings, this is done before inserting the control because the collection
                // binding is needed by AKAFormTableViewController (TODO: much too complex, refactor this)
                [control addBindingsForView:controlView];

                if (control)
                {
                    if ([control isKindOfClass:[AKATableViewCellCompositeControl class]])
                    {
                        // Record the indexPath (and while we are at it, also tableView and dataSource)
                        // because it's otherwise very hard to find the right indexPath for a given
                        // cell. We want this to provide the means to AKAFormTableViewController to
                        // hide and show (or perform other operations on) rows which correspond to controls.
                        // TODO: this is quite a bit hacky, review the architecture
                        AKATableViewCellCompositeControl* tvccp = (AKATableViewCellCompositeControl*)control;
                        tvccp.indexPath = indexPath;
                        tvccp.tableView = tableView;
                        tvccp.dataSource = dataSource;
                    }

                    [self insertControl:control atIndex:index + count];
                    ++count;

                    // Add controls (recursively), this is done after inserting the control to ensure
                    // that nested bindings using $root key paths will see the real root
                    if ([control isKindOfClass:[AKACompositeControl class]])
                    {
                        AKACompositeControl* composite = (AKACompositeControl*)control;
                        [composite autoAddControlsForControlViewSubviewsInViewHierarchy:controlView
                                                                           excludeViews:childControllerViews];
                    }
                }
            }
            else if (cell != nil)
            {
                // If the cell is not a control view, handle is like any other view (scanning its
                // view hierarchy for control views starting at its contentView).
                UIView* rootView = cell.contentView;
                count += [self insertControlsForControlViewsInViewHierarchy:rootView
                                                                    atIndex:index + count
                                                               excludeViews:childControllerViews];
            }
        }
    }
    [self endInsertingControls];
}

@end


@implementation AKACompositeControl (DelegatePropagation)

- (void)                  controlWillInsertMemberControls:(AKACompositeControl*)compositeControl
{
    [self.owner controlWillInsertMemberControls:compositeControl];
}

- (void)             controlDidEndInsertingMemberControls:(AKACompositeControl*)compositeControl
{
    [self.owner controlDidEndInsertingMemberControls:compositeControl];
}

- (BOOL)  shouldControl:(AKACompositeControl*)compositeControl
             addControl:(AKAControl*)memberControl
                atIndex:(NSUInteger)index
{
    BOOL result = YES;
    AKACompositeControl* owner = self.owner;

    if (owner != nil)
    {
        result = [owner shouldControl:compositeControl addControl:memberControl atIndex:index];
    }

    return result;
}

- (void)        control:(AKACompositeControl*)compositeControl
         willAddControl:(AKAControl*)memberControl
                atIndex:(NSUInteger)index
{
    [self.owner control:compositeControl willAddControl:memberControl atIndex:index];
}

- (void)        control:(AKACompositeControl*)compositeControl
          didAddControl:(AKAControl*)memberControl
                atIndex:(NSUInteger)index
{
    [self.owner control:compositeControl didAddControl:memberControl atIndex:index];
}

- (BOOL)  shouldControl:(AKACompositeControl*)compositeControl
          removeControl:(AKAControl*)memberControl
                atIndex:(NSUInteger)index
{
    BOOL result = YES;
    AKACompositeControl* owner = self.owner;

    if (owner != nil)
    {
        result = [owner shouldControl:compositeControl removeControl:memberControl atIndex:index];
    }

    return result;
}

- (void)        control:(AKACompositeControl*)compositeControl
      willRemoveControl:(AKAControl*)memberControl
              fromIndex:(NSUInteger)index
{
    [self.owner control:compositeControl willRemoveControl:memberControl fromIndex:index];
}

- (void)        control:(AKACompositeControl*)compositeControl
       didRemoveControl:(AKAControl*)memberControl
              fromIndex:(NSUInteger)index
{
    [self.owner control:compositeControl didRemoveControl:memberControl fromIndex:index];
}

@end
