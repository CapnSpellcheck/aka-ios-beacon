//
//  AKABinding+SubclassInitialization.m
//  AKABeacon
//
//  Created by Michael Utech on 28.05.16.
//  Copyright © 2016 Michael Utech & AKA Sarl. All rights reserved.
//

#import "AKABinding_Protected.h"
#import "AKABinding+SubclassInitialization.h"
#import "AKABinding+DelegateSupport.h"
#import "AKABinding+SubBindings.h"
#import "AKABinding_SubBindingsProperties.h"

#import "AKALog.h"
#import "AKABindingErrors.h"
#import "AKABindingExpressionEvaluator.h"

@implementation AKABinding (SubclassInitialization)

#pragma mark - Initialization

- (instancetype)                                initWithTarget:(req_id)target
                                                    expression:(req_AKABindingExpression)bindingExpression
                                                       context:(req_AKABindingContext)bindingContext
                                                      delegate:(opt_AKABindingDelegate)delegate
                                                         error:(out_NSError)error
{
    [self validateTarget:target];

    self = [self initWithTargetProperty:[self createBindingTargetPropertyForTarget:target]
                             expression:bindingExpression
                                context:bindingContext
                               delegate:delegate
                                  error:error];

    return self;
}

#pragma mark - Binding Type Validation


- (BOOL)                     validateBindingTypeWithExpression:(opt_AKABindingExpression)bindingExpression
                                                         error:(out_NSError)error
{
    BOOL result = YES;

    if (bindingExpression)
    {
        Class specifiedBindingType = bindingExpression.specification.bindingType;

        result = (specifiedBindingType == nil || [[self class] isSubclassOfClass:specifiedBindingType]);

        if (!result)
        {
            *error = [AKABindingErrors invalidBindingExpression:(req_AKABindingExpression)bindingExpression
                                                    bindingType:self.class
                               doesNotMatchSpecifiedBindingType:specifiedBindingType];
        }
    }

    return result;
}

#pragma mark - Binding Target Initialization

- (void)                                        validateTarget:(req_id __unused)target
{
    AKAErrorAbstractMethodImplementationMissing();
}

- (req_AKAProperty)       createBindingTargetPropertyForTarget:(req_id __unused)target
{
    AKAErrorAbstractMethodImplementationMissing();
}

#pragma mark - Binding Source Initialization

- (opt_AKAProperty)                 bindingSourceForExpression:(req_AKABindingExpression)bindingExpression
                                                       context:(req_AKABindingContext)bindingContext
                                                changeObserver:(opt_AKAPropertyChangeObserver)changeObserver
                                                         error:(out_NSError)error
{
    opt_AKAProperty bindingSource = nil;

    if (bindingExpression.class == [AKABindingExpression class] ||
        bindingExpression.expressionType == AKABindingExpressionTypeNone)
    {
        // The binding expression does not have a primary value. Consequently, the concrete binding
        // type may provide a default binding source:
        bindingSource = [self defaultBindingSourceForExpression:bindingExpression
                                                        context:bindingContext
                                                 changeObserver:changeObserver
                                                          error:error];
    }
    else if (bindingExpression.expressionType == AKABindingExpressionTypeArray)
    {
        bindingSource = [self bindingSourceForArrayExpression:bindingExpression
                                                      context:bindingContext
                                               changeObserver:changeObserver
                                                        error:error];
    }
    else
    {
        bindingSource = [bindingExpression bindingSourcePropertyInContext:bindingContext
                                                            changeObserer:changeObserver];
        if (!bindingSource && error)
        {
            *error = [AKABindingErrors bindingErrorUndefinedBindingSourceForExpression:bindingExpression
                                                                               context:bindingContext];
        }
    }

    return bindingSource;
}

- (AKAProperty*)             defaultBindingSourceForExpression:(req_AKABindingExpression)bindingExpression
                                                       context:(req_AKABindingContext)bindingContext
                                                changeObserver:(opt_AKAPropertyChangeObserver)changeObserver
                                                         error:(out_NSError)error
{
    (void)bindingExpression;
    (void)bindingContext;
    (void)changeObserver;
    (void)error;

    // Note: Bindings that do not need a primary expression should return a property with an undefined target and keypath. This is not done by default to ensure that undefined source properties trigger an error unless this is intentional.
    AKAErrorAbstractMethodImplementationMissing();
}


- (AKAProperty*)               bindingSourceForArrayExpression:(req_AKABindingExpression)bindingExpression
                                                       context:(req_AKABindingContext)bindingContext
                                                changeObserver:(opt_AKAPropertyChangeObserver)changeObserver
                                                         error:(out_NSError)error
{
    // Binding source will not be updated (for target changes), so the change observer will not
    // be used; however, changes in array items will trigger source array item events:
    (void)changeObserver;

    BOOL result = YES;
    AKAProperty* bindingSource = nil;

    id sourceValue = [bindingExpression bindingSourceValueInContext:bindingContext];

    if ([sourceValue isKindOfClass:[NSArray class]])
    {
        BOOL isConstant = YES;
        NSArray* sourceArray = sourceValue;
        NSMutableArray* targetArray = [NSMutableArray new];

        for (id sourceItem in sourceArray)
        {
            // If an array item does not have a binding, null is stored to preserve index integrity.
            id arrayItemBinding = [NSNull null];

            if ([sourceItem isKindOfClass:[AKABindingExpression class]])
            {
                AKABindingExpression* sourceExpression = sourceItem;
                if (sourceExpression.isConstant)
                {
                    // Constant expressions will be evaluated immediately and no binding is created.
                    id targetValue = [sourceExpression bindingSourceValueInContext:bindingContext];
                    if (targetValue == nil)
                    {
                        [targetArray addObject:[NSNull null]];
                    }
                    else
                    {
                        [targetArray addObject:targetValue];
                    }
                }
                else
                {
                    // All other binding expressions require the creation of a binding for the array
                    // item, the target array is thus not constant.
                    isConstant = NO;

                    // The target value will be initialized as undefined value, as soon as the binding
                    // will start observing changes, the value will be updated by the binding.
                    [targetArray addObject:[NSNull null]];
                    NSUInteger index = targetArray.count - 1;

                    __weak typeof(self) weakSelf = self;
                    AKAProperty* arrayItemTargetProperty =
                    [AKAIndexedProperty propertyOfWeakIndexedTarget:targetArray
                                                              index:(NSInteger)index
                                                     changeObserver:
                     ^(id  _Nullable oldValue, id  _Nullable newValue)
                     {
                         [weakSelf targetArrayItemAtIndex:index
                                                    value:oldValue == [NSNull null] ? nil : oldValue
                                              didChangeTo:newValue == [NSNull null] ? nil : newValue];
                     }];
                    Class bindingType = sourceExpression.specification.bindingType;
                    if (bindingType == nil)
                    {
                        bindingType = [AKAPropertyBinding class];
                    }

                    AKABinding* binding = [bindingType bindingToTargetProperty:arrayItemTargetProperty
                                                                withExpression:sourceExpression
                                                                       context:bindingContext
                                                                      delegate:weakSelf.delegateForSubBindings
                                                                         error:error];
                    if (binding)
                    {
                        arrayItemBinding = binding;
                    }
                    else
                    {
                        result = NO;
                    }
                }
            }
            if (result)
            {
                [self addArrayItemBinding:arrayItemBinding];
            }
        }

        if (result)
        {
            if (isConstant)
            {
                // Create a non-mutable copy
                self.syntheticTargetValue = [NSArray arrayWithArray:targetArray];
            }
            else
            {
                // Preserve the mutable array, because bindings may update array items
                self.syntheticTargetValue = targetArray;
            }

            bindingSource = [AKAProperty propertyOfWeakTarget:self
                                                       getter:
                             ^id _Nullable(req_id target)
                             {
                                 AKABinding* binding = target;
                                 return binding.syntheticTargetValue;
                             }
                                                       setter:
                             ^(req_id target, opt_id value)
                             {
                                 (void)target;
                                 (void)value;
                                 NSAssert(NO, @"Updating binding source is not supported by array property bindings (yet)");
                             }
                                           observationStarter:
                             ^BOOL(req_id target)
                             {
                                 BOOL sresult = YES;
                                 AKABinding* binding = target;

                                 for (AKABinding* itemBinding in binding.arrayItemBindings)
                                 {
                                     sresult = [itemBinding startObservingChanges] && sresult;
                                 }

                                 return sresult;
                             }
                                           observationStopper:
                             ^BOOL(req_id target)
                             {
                                 BOOL sresult = YES;
                                 AKABinding* binding = target;

                                 for (AKABinding* itemBinding in binding.arrayItemBindings)
                                 {
                                     sresult = [itemBinding stopObservingChanges] && sresult;
                                 }

                                 return sresult;
                             }];
        }
    }
    else
    {
        NSError* e = [AKABindingErrors invalidBinding:self
                                          sourceValue:sourceValue
                                   expectedSubclassOf:[NSArray class]];
        if (error)
        {
            *error = e;
        }
        else
        {
            // TODO: refactor this to AKABindingErrors (unhandled error)
            @throw [NSException exceptionWithName:@"InvalidOperation"
                                           reason:e.localizedDescription
                                         userInfo:@{ @"error": e }];
        }
        result = NO;
    }
    
    return bindingSource;
}

#pragma mark - Attribute Initialization

- (BOOL)                    initializeAttributesWithExpression:(req_AKABindingExpression)bindingExpression
                                                         error:(out_NSError)error
{
    __block BOOL result = YES;

    (void)error;

    __block NSError* localError = nil;

    AKABindingSpecification* specification = [self.class specification];

    [((opt_AKABindingExpressionAttributes)(bindingExpression.attributes)) enumerateKeysAndObjectsUsingBlock:
     ^(req_NSString attributeName,
       req_AKABindingExpression attribute,
       outreq_BOOL stop)
     {
         (void)stop;

         AKABindingAttributeSpecification* attributeSpec =
         specification.bindingSourceSpecification.attributes[attributeName];

         if (attributeSpec)
         {
             NSString* bindingPropertyName = attributeSpec.bindingPropertyName;

             if (bindingPropertyName == nil)
             {
                 bindingPropertyName = attributeName;
             }

             switch (attributeSpec.attributeUse)
             {
                 case AKABindingAttributeUseManually:
                 {
                     result = [self initializeManualAttributeWithName:attributeName
                                                        specification:attributeSpec
                                                  attributeExpression:attribute
                                                                error:&localError];
                     break;
                 }

                 case AKABindingAttributeUseAssignValueToBindingProperty:
                 {
                     result = [self initializeBindingPropertyValueAssignmentAttribute:bindingPropertyName withSpecification:attributeSpec attributeExpression:attribute error:&localError];
                     break;
                 }

                 case AKABindingAttributeUseAssignExpressionToBindingProperty:
                 {
                     result = [self initializeBindingPropertyExpressionAssignmentAttribute:bindingPropertyName
                                                                         withSpecification:attributeSpec
                                                                       attributeExpression:attribute
                                                                                     error:&localError];
                     break;
                 }


                 case AKABindingAttributeUseAssignEvaluatorToBindingProperty:
                 {
                     result = [self initializeBindingPropertyEvaluatorAssignmentAttribute:bindingPropertyName
                                                                        withSpecification:attributeSpec
                                                                      attributeExpression:attribute
                                                                                    error:&localError];
                     break;
                 }

                 case AKABindingAttributeUseAssignValueToTargetProperty:
                 {
                     result = [self initializeTargetPropertyValueAssignmentAttribute:bindingPropertyName
                                                                   withSpecification:attributeSpec
                                                                 attributeExpression:attribute
                                                                               error:&localError];
                     break;
                 }

                 case AKABindingAttributeUseBindToBindingProperty:
                 {
                     result = [self initializeBindingPropertyBindingAttribute:bindingPropertyName
                                                            withSpecification:attributeSpec
                                                          attributeExpression:attribute
                                                                        error:&localError];

                     break;
                 }

                 case AKABindingAttributeUseBindToTargetProperty:
                 {
                     result = [self initializeTargetPropertyBindingAttribute:bindingPropertyName
                                                           withSpecification:attributeSpec
                                                         attributeExpression:attribute
                                                                       error:&localError];
                     break;
                 }

                 default:
                     break;
             }
         }
         else
         {
             result = [self initializeUnspecifiedAttribute:attributeName
                                       attributeExpression:attribute
                                                     error:&localError];
         }
         *stop = !result;
     }];

    if (!result && error)
    {
        *error = localError;
    }

    return result;
}

- (BOOL)                     initializeManualAttributeWithName:(NSString * __unused)attributeName
                                                 specification:(req_AKABindingAttributeSpecification __unused)specification
                                           attributeExpression:(req_AKABindingExpression __unused)attributeExpression
                                                         error:(out_NSError __unused)error
{
    return YES;
}

- (BOOL)     initializeBindingPropertyValueAssignmentAttribute:(NSString *)bindingProperty
                                             withSpecification:(AKABindingAttributeSpecification * __unused)specification
                                           attributeExpression:(req_AKABindingExpression)attributeExpression
                                                         error:(out_NSError __unused)error
{
    id value = [attributeExpression bindingSourceValueInContext:self.bindingContext];
    [self setValue:value forKey:bindingProperty];
    return YES;
}

- (BOOL)initializeBindingPropertyExpressionAssignmentAttribute:(NSString *)bindingProperty
                                             withSpecification:(AKABindingAttributeSpecification *)specification
                                           attributeExpression:(req_AKABindingExpression)attributeExpression
                                                         error:(out_NSError __unused)error
{
    [self setValue:attributeExpression forKey:bindingProperty];
    return YES;
}

- (BOOL) initializeBindingPropertyEvaluatorAssignmentAttribute:(NSString *)bindingProperty
                                             withSpecification:(AKABindingAttributeSpecification *)specification
                                           attributeExpression:(req_AKABindingExpression)attributeExpression
                                                         error:(out_NSError)error
{
    NSError* localError = nil;
    AKABindingExpressionEvaluator* evaluator =
    [[AKABindingExpressionEvaluator alloc] initWithFactoryBindingExpression:attributeExpression
                                                             bindingContext:self.bindingContext
                                                            bindingDelegate:self.delegateForSubBindings
                                                                      error:&localError];
    BOOL result = (evaluator != nil || localError == nil);

    if (result)
    {
        [self setValue:evaluator forKeyPath:bindingProperty];
    }
    else
    {
        AKARegisterErrorInErrorStore(localError, error);
    }

    return result;
}

- (BOOL)      initializeTargetPropertyValueAssignmentAttribute:(req_NSString)bindingProperty
                                             withSpecification:(req_AKABindingAttributeSpecification __unused)specification
                                           attributeExpression:(req_AKABindingExpression)attributeExpression
                                                         error:(out_NSError __unused)error;
{
    BOOL result = YES;

    id target = self.bindingTarget.value;
    if (target == nil)
    {
        // If the target does not yet have a defined value, a binding will be created to ensure that the value is not lost.
        AKALogWarn(@"Cannot assign binding %@ attribute value %@ to target property %@ because the target is undefined. To support defered target assignment, a property binding will be created instead", self, attributeExpression, bindingProperty);

        result = [self initializeTargetPropertyBindingAttribute:bindingProperty withSpecification:specification attributeExpression:attributeExpression error:error];
    }
    else
    {
        id value = [attributeExpression bindingSourceValueInContext:self.bindingContext];
        [target setValue:value forKey:bindingProperty];
    }
    
    return result;
}

- (BOOL)             initializeBindingPropertyBindingAttribute:(NSString *)bindingProperty
                                             withSpecification:(AKABindingAttributeSpecification *)specification
                                           attributeExpression:(req_AKABindingExpression)attributeExpression
                                                         error:(out_NSError)error
{
    BOOL result = YES;
    Class bindingType = specification.bindingType;

    if (bindingType == nil)
    {
        bindingType = [AKAPropertyBinding class];
    }

    if (bindingType != nil)
    {
        __weak typeof(self) weakSelf = self;
        AKAProperty* targetProperty =
        [AKAProperty propertyOfWeakKeyValueTarget:self
                                          keyPath:bindingProperty
                                   changeObserver:^(opt_id oldValue, opt_id newValue) {
                                       [weakSelf bindingProperty:bindingProperty
                                                           value:oldValue
                                             didChangeToNewValue:newValue];
                                   }];
        AKABinding* propertyBinding = [bindingType bindingToTargetProperty:targetProperty
                                                            withExpression:attributeExpression
                                                                   context:self.bindingContext
                                                                  delegate:weakSelf.delegateForSubBindings
                                                                     error:error];
        result = propertyBinding != nil;
        if (result)
        {
            [self addBindingPropertyBinding:propertyBinding];
        }
    }
    return result;
}

- (BOOL)              initializeTargetPropertyBindingAttribute:(NSString *)bindingProperty
                                             withSpecification:(AKABindingAttributeSpecification *)specification
                                           attributeExpression:(req_AKABindingExpression)attributeExpression
                                                         error:(out_NSError)error
{
    BOOL result = YES;
    Class bindingType = specification.bindingType;

    if (bindingType == nil)
    {
        bindingType = [AKAPropertyBinding class];
    }

    if (bindingType != nil)
    {
        __weak typeof(self) weakSelf = self;
        AKAProperty* targetProperty =
        [self.bindingTarget propertyAtKeyPath:bindingProperty
                           withChangeObserver:
         ^(opt_id oldValue, opt_id newValue)
         {
             [weakSelf  targetProperty:bindingProperty
                                 value:oldValue
                   didChangeToNewValue:newValue];
         }];
        AKABinding* propertyBinding = [bindingType bindingToTargetProperty:targetProperty
                                                            withExpression:attributeExpression
                                                                   context:self.bindingContext
                                                                  delegate:weakSelf.delegateForSubBindings
                                                                     error:error];
        result = propertyBinding != nil;
        if (result)
        {
            [self addTargetPropertyBinding:propertyBinding];
        }
    }
    return result;
}

- (BOOL)                        initializeUnspecifiedAttribute:(NSString * __unused)attributeName
                                           attributeExpression:(req_AKABindingExpression __unused)attributeExpression
                                                         error:(out_NSError __unused)error
{
    return YES;
}

@end
