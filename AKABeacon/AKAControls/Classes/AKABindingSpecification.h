//
//  AKABindingSpecification.h
//  AKABeacon
//
//  Created by Michael Utech on 26.09.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import Foundation;
@import AKACommons.AKANullability;

@class AKABindingProvider;
typedef AKABindingProvider* _Nullable opt_AKABindingProvider;

@class AKATypePattern;
@class AKABindingTargetSpecification;
@class AKABindingExpressionSpecification;
@class AKABindingAttributeSpecification;

typedef NS_ENUM(NSInteger, AKABindingAttributeUse)
{
    AKABindingAttributeUseAssignValueToBindingProperty,
    AKABindingAttributeUseAssignExpressionToBindingProperty,
    AKABindingAttributeUseBindToBindingProperty
};

typedef NS_OPTIONS(NSInteger, AKABindingExpressionType)
{
    AKABindingExpressionTypeNone =                          0,

    AKABindingExpressionTypeUnqualifiedKeyPath =            (1 <<  0),
    AKABindingExpressionTypeDataContextKeyPath =            (1 <<  1),
    AKABindingExpressionTypeRootDataContextKeyPath =        (1 <<  2),
    AKABindingExpressionTypeControlKeyPath =                (1 <<  3),

    AKABindingExpressionTypeArray =                         (1 <<  5),

    AKABindingExpressionTypeClassConstant =                 (1 << 10),

    AKABindingExpressionTypeStringConstant =                (1 << 11),

    AKABindingExpressionTypeNumberConstant =                (1 << 12),
    AKABindingExpressionTypeBooleanConstant =               (1 << 13),
    AKABindingExpressionTypeIntegerConstant =               (1 << 14),
    AKABindingExpressionTypeDoubleConstant =                (1 << 15),

    AKABindingExpressionTypeUIColorConstant =               (1 << 16),
    AKABindingExpressionTypeCGColorConstant =               (1 << 17),
    AKABindingExpressionTypeCGPointConstant =               (1 << 18),
    AKABindingExpressionTypeCGSizeConstant =                (1 << 19),
    AKABindingExpressionTypeCGRectConstant =                (1 << 20),
    AKABindingExpressionTypeUIFontConstant =                (1 << 21),

    AKABindingExpressionTypeAnyKeyPath        = (AKABindingExpressionTypeDataContextKeyPath     |
                                                 AKABindingExpressionTypeRootDataContextKeyPath |
                                                 AKABindingExpressionTypeControlKeyPath),

    AKABindingExpressionTypeClass             = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeClassConstant),
    AKABindingExpressionTypeString            = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeStringConstant),
    AKABindingExpressionTypeBoolean           = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeBooleanConstant),
    AKABindingExpressionTypeInteger           = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeIntegerConstant),
    AKABindingExpressionTypeDouble            = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeDoubleConstant),
    AKABindingExpressionTypeNumber            = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeNumberConstant),

    AKABindingExpressionTypeAnyColorConstant =  (AKABindingExpressionTypeUIColorConstant        |
                                                 AKABindingExpressionTypeCGColorConstant),

    AKABindingExpressionTypeAnyNumberConstant = (AKABindingExpressionTypeNumberConstant         |
                                                 AKABindingExpressionTypeBooleanConstant        |
                                                 AKABindingExpressionTypeIntegerConstant        |
                                                 AKABindingExpressionTypeDoubleConstant),

    AKABindingExpressionTypeAnyConstant       = (AKABindingExpressionTypeClassConstant          |
                                                 AKABindingExpressionTypeStringConstant         |
                                                 AKABindingExpressionTypeAnyNumberConstant      |
                                                 AKABindingExpressionTypeAnyColorConstant       |
                                                 AKABindingExpressionTypeCGPointConstant        |
                                                 AKABindingExpressionTypeCGSizeConstant         |
                                                 AKABindingExpressionTypeCGRectConstant         |
                                                 AKABindingExpressionTypeUIFontConstant),


    AKABindingExpressionTypeAny               = (AKABindingExpressionTypeAnyKeyPath             |
                                                 AKABindingExpressionTypeAnyConstant            |
                                                 AKABindingExpressionTypeArray)

};


#pragma mark - AKABindingSpecification
#pragma mark -

@interface AKABindingSpecification : NSObject

#pragma mark - Initialization

- (instancetype _Nullable)initWithDictionary:(req_NSDictionary)dictionary;

#pragma mark - Conversion

- (void)addToDictionary:(req_NSMutableDictionary)specDictionary;

#pragma mark - Properties

@property(nonatomic, readonly, nullable)Class                               bindingType;

@property(nonatomic, readonly, nonnull) AKABindingProvider*                 bindingProvider;

@property(nonatomic, readonly, nullable) AKABindingTargetSpecification*      bindingTargetSpecification;
@property(nonatomic, readonly, nullable) AKABindingExpressionSpecification*  bindingSourceSpecification;

- (opt_AKABindingProvider)bindingProviderForAttributeWithName:(req_NSString)attributeName;
- (opt_AKABindingProvider)bindingProviderForArrayItem;

@end

@interface AKABindingTargetSpecification: NSObject

- (instancetype _Nullable)initWithDictionary:(req_NSDictionary)dictionary;
- (void)addToDictionary:(req_NSMutableDictionary)specDictionary;

@property(nonatomic, readonly, nullable) AKATypePattern*        typePattern;

@end

@interface AKABindingExpressionSpecification: NSObject

- (instancetype _Nullable)initWithDictionary:(req_NSDictionary)dictionary;
- (void)addToDictionary:(req_NSMutableDictionary)specDictionary;

/**
 * Specifies the set of valid types of the binding expressions primary expression.
 *
 * Please note that key path expressions will have a type of AKAProperty,
 * numeric and boolean constants NSNumber, string constants NSString, 
 */
@property(nonatomic, readonly)          AKABindingExpressionType            expressionType;

/**
 * Specifies which attributes can be defined in a matching binding expression.
 */
@property(nonatomic, readonly, nonnull) NSDictionary<NSString*, AKABindingAttributeSpecification*>*
                                                                            attributes;
/**
 * Specifies the binding provider to be used for items in primary expressions of array type.
 */
@property(nonatomic, readonly, nullable) AKABindingProvider*                arrayItemBindingProvider;

@end

@interface AKABindingAttributeSpecification : AKABindingSpecification

- (instancetype _Nullable)initWithDictionary:(req_NSDictionary)dictionary;
- (void)addToDictionary:(req_NSMutableDictionary)specDictionary;

/**
 * Specifies if the attribute has to be provided in matching binding expressions.
 */
@property(nonatomic, readonly)           BOOL               required;

@property(nonatomic, readonly)           AKABindingAttributeUse attributeUse;
@property(nonatomic, readonly, nullable) NSString*          bindingPropertyName;

@end

@interface AKATypePattern: NSObject

- (instancetype _Nullable)initWithArrayOfClasses:(req_NSArray)array;
- (instancetype _Nullable)initWithClass:(Class _Nonnull)type;
- (instancetype _Nullable)initWithDictionary:(req_NSDictionary)dictionary;
- (void)addToDictionary:(req_NSMutableDictionary)specDictionary;

@property(nonatomic, readonly, nullable) NSSet<Class>*      acceptedTypes;
@property(nonatomic, readonly, nullable) NSSet<Class>*      rejectedTypes;
@property(nonatomic, readonly, nullable) NSSet<NSString*>*  acceptedValueTypes;
@property(nonatomic, readonly, nullable) NSSet<NSString*>*  rejectedValueTypes;

- (BOOL)matchesObject:(id _Nullable)object;

@end
