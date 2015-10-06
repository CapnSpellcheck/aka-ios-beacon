//
//  NSScanner+AKABindingExpressionParser.m
//  AKAControls
//
//  Created by Michael Utech on 19.09.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import AKACommons.AKAMutableOrderedDictionary;

#import "NSScanner+AKABindingExpressionParser.h"

#import "AKABindingExpression_Internal.h"
#import "AKABindingProvider.h"

@implementation NSScanner(BindingExpressionParser)

#pragma mark - Configuration

static NSString* const keywordTrue = @"true";
static NSString* const keywordFalse = @"false";
static NSString* const keywordData = @"data";
static NSString* const keywordRoot = @"root";
static NSString* const keywordControl = @"control";

+ (NSString*) keywordTrue { return keywordTrue; }
+ (NSString*) keywordFalse { return keywordFalse; }
+ (NSString*) keywordData { return keywordData; }
+ (NSString*) keywordRoot { return keywordRoot; }
+ (NSString*) keywordControl { return keywordControl; }

+ (NSDictionary<NSString*, NSDictionary<NSString*, Class>*>*)namedScopesAndConstants
{
    static NSDictionary* namedScopes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        namedScopes = @{ keywordTrue:    @{ @"value": @(YES),
                                            @"type":  [AKABooleanConstantBindingExpression class]
                                           },
                         keywordFalse:   @{ @"value": @(NO),
                                            @"type":  [AKABooleanConstantBindingExpression class]
                                           },
                         keywordData:    @{ @"value": [NSNull null],
                                            @"type":  [AKADataContextKeyPathBindingExpression class]
                                           },
                         keywordRoot:    @{ @"value": [NSNull null],
                                            @"type":  [AKARootDataContextKeyPathBindingExpression class]
                                           },
                         keywordControl: @{ @"value": [NSNull null],
                                            @"type":  [AKAControlKeyPathBindingExpression class]
                                           }
                         };
    });
    return namedScopes;
}

- (NSDictionary<NSString*, NSNumber*>*)keyPathOperators
{
    static NSDictionary* operators;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Used to recognize invalid operators and to decide if an operator requires
        // a subsequent key as in: "...@avg.salary" vs. "...@count"
        operators = @{ @"count": @NO,
                       @"avg": @YES,
                       @"min": @YES,
                       @"max": @YES,
                       @"sum": @YES,
                       @"distinctUnionOfObjects": @YES,
                       @"unionOfObjects": @YES,
                       @"distinctUnionOfArrays": @YES,
                       @"unionOfArrays": @YES,
                       @"distinctUnionOfSets": @YES,
                       @"unionOfSets": @YES
                       };
    });
    return operators;
}

#pragma mark - Binding Expression Parser

- (BOOL)    parseBindingExpression:(out_AKABindingExpression)store
                      withProvider:(opt_AKABindingProvider)provider
                             error:(out_NSError)error
{
    [self skipWhitespaceAndNewlineCharacters];
    BOOL result = !self.isAtEnd;

    id primaryExpression = nil;
    NSDictionary* attributes = nil;
    Class bindingExpressionType = nil;

    result = [self parseConstantOrScope:&primaryExpression
                           withProvider:provider
                                   type:&bindingExpressionType
                                  error:error];

    if (result)
    {
        // Order is relevant:
        BOOL requireKeyPath = [self skipCharacter:'.'];
        BOOL possiblyKeyPath = [self isAtValidFirstIdentifierCharacter] || [self isAtCharacter:'@'];

        if (requireKeyPath && !possiblyKeyPath)
        {
            result = NO;
            [self registerParseError:error
                            withCode:AKAParseErrorUnterminatedKeyPathAfterDot
                          atPosition:self.scanLocation
                              reason:@"Expected a key (path component) following trailing dot."];
        }
        else if (possiblyKeyPath)
        {
            result = [self parseKeyPath:&primaryExpression error:error];
            if (result && bindingExpressionType == nil)
            {
                bindingExpressionType = [AKAKeyPathBindingExpression class];
            }
        }
    }

    if (result)
    {
        [self skipWhitespaceAndNewlineCharacters];
        if ([self isAtCharacter:'{'])
        {
            result = [self parseAttributes:&attributes withProvider:provider error:error];
        }
        if (result && attributes.count > 0 && bindingExpressionType == nil)
        {
            bindingExpressionType = [AKABindingExpression class];
        }
    }

    if (result && store != nil)
    {
        AKABindingExpression* bindingExpression = [bindingExpressionType alloc];
        bindingExpression = [bindingExpression initWithPrimaryExpression:primaryExpression
                                                              attributes:attributes
                                                                provider:provider];
        *store = bindingExpression;
    }

    return result;
}

- (BOOL)      parseConstantOrScope:(out_id)constantStore
                      withProvider:(opt_AKABindingProvider)provider
                              type:(out_Class)typeStore
                             error:(out_NSError)error
{
    BOOL result = YES;
    Class type = nil;
    id constant = nil;

    BOOL explicitScope = [self skipCharacter:'$'];

    if ([self isAtCharacter:'"'])
    {
        type = [AKAStringConstantBindingExpression class];
        result = [self parseStringConstant:&constant error:error];
    }
    else if ([self skipCharacter:'('])
    {
        result = [self parseNumberConstant:&constant
                                      type:&type
                                          error:error];
        if (result)
        {
            result = [self skipCharacter:')'];
            if (!result)
            {
                [self registerParseError:error
                                withCode:AKAParseErrorUnterminatedParenthizedExpression
                              atPosition:self.scanLocation
                                  reason:@"Unterminated parenthisized expression"];
                // error, missing )
            }
        }
    }
    else if ([self skipCharacter:'<'])
    {
        type = [AKAClassConstantBindingExpression class];
        NSString* className;
        result = [self parseIdentifier:&className error:error];
        if (result)
        {
            constant = NSClassFromString(className);
            if (constant == nil)
            {
                result = NO;
                [self registerParseError:error
                                withCode:AKAParseErrorUnknownClass
                              atPosition:self.scanLocation
                                  reason:[NSString stringWithFormat:@"There is no class loaded with the name %@", className]];
            }
            if (result)
            {
                result = [self skipCharacter:'>'];
                if (!result)
                {
                    [self registerParseError:error
                                    withCode:AKAParseErrorUnterminatedClassReference
                                  atPosition:self.scanLocation
                                      reason:@"Unterminated class reference, expected '>'"];
                }
            }
        }
    }
    else if ([self skipCharacter:'['])
    {
        type = [AKAArrayBindingExpression class];
        NSMutableArray* array = [NSMutableArray new];

        [self skipWhitespaceAndNewlineCharacters];
        BOOL done=(self.isAtEnd || [self skipCharacter:']']);
        for (NSUInteger i=0; result && !done; ++i)
        {
            AKABindingExpression* item = nil;

            AKABindingProvider* itemProvider = [provider providerForBindingExpressionInPrimaryExpressionArray];

            result = [self parseBindingExpression:&item
                                     withProvider:itemProvider
                                            error:error];
            if (result)
            {
                [array addObject:item];

                result = [self parseListSeparator:','
                                     orTerminator:']'
                                  terminatorFound:&done
                                            error:error];
            }
        }
        if (result && array.count > 0)
        {
            constant = [NSArray arrayWithArray:array];
        }
    }
    else if ([self isAtValidFirstNumberCharacter])
    {
        result = [self parseNumberConstant:&constant
                                      type:&type
                                     error:error];
    }
    else if (explicitScope && [self isAtValidFirstIdentifierCharacter])
    {
        NSString* identifier;
        result = [self parseIdentifier:&identifier error:error];
        if (result)
        {
            NSDictionary<NSString*, id>* namedScope = [NSScanner namedScopesAndConstants][identifier];
            if (namedScope != nil)
            {
                type = namedScope[@"type"];
                constant = namedScope[@"value"];
                if (constant == [NSNull null])
                {
                    constant = nil;
                }
            }
            else
            {
                result = NO;
                [self registerParseError:error
                                withCode:AKAParseErrorInvalidConstantOrScopeName
                              atPosition:self.scanLocation
                                  reason:[NSString stringWithFormat:@"Invalid binding scope or named constant '$%@'", identifier]];
            }
        }
    }

    if (result)
    {
        NSAssert(constant != nil ? type != nil : YES, @"Expected a defined binding expression type if a constant was found");
        if (typeStore != nil)
        {
            *typeStore = type;
        }

        if (constantStore != nil && ([type isSubclassOfClass:[AKAConstantBindingExpression class]] ||
                                     [type isSubclassOfClass:[AKAArrayBindingExpression class]]))
        {
            *constantStore = constant;
        }
    }
    
    return result;
}

- (BOOL)              parseKeyPath:(out_NSString)store
                             error:(out_NSError)error
{
    NSUInteger start = self.scanLocation;
    NSUInteger length = 0;

    BOOL expectKey = NO; // most @-operators (all but @count) require a subsequent key
    NSString* lastOperator = nil;

    BOOL done = self.isAtEnd;
    BOOL result = YES;
    while (result && !done)
    {
        // Record start of component for error reporting
        NSUInteger pathComponentStart = self.scanLocation;

        // Parse operator (@), key or extension path component:
        if ([self skipCharacter:'@'])
        {
            if (expectKey)
            {
                result = NO;
                [self registerParseError:error
                                withCode:AKAParseErrorKeyPathOperatorRequiresSubsequentKey
                              atPosition:self.scanLocation
                                  reason:[NSString stringWithFormat:@"Key path operator '@%@' requires a subsequent key, not another operator", lastOperator]];
            }
            else if ([self isAtValidFirstIdentifierCharacter])
            {
                result = [self parseIdentifier:&lastOperator error:error];
                if (result)
                {
                    NSNumber* needsKey = self.keyPathOperators[lastOperator];
                    if (needsKey != nil)
                    {
                        expectKey = needsKey.boolValue;
                    }
                    else
                    {
                        result = NO;
                        [self registerParseError:error
                                        withCode:AKAParseErrorInvalidKeyPathOperator
                                      atPosition:pathComponentStart
                                          reason:[NSString stringWithFormat:@"Invalid (unknown) key path operator '@%@'", lastOperator]];
                    }
                }
            }
            else
            {
                result = NO;
                [self registerParseError:error
                                withCode:AKAParseErrorKeyPathOperatorNameExpectedAfterAtSign
                              atPosition:self.scanLocation
                                  reason:@"Operator name expected after @"];
            }
        }
        else if ([self isAtValidFirstIdentifierCharacter])
        {
            if (expectKey)
            {
                expectKey = NO;
            }
            result = [self parseIdentifier:nil error:error];
        }
        else
        {
            [self registerParseError:error
                            withCode:AKAParseErrorInvalidKeyPathComponent
                          atPosition:pathComponentStart
                              reason:[NSString stringWithFormat:@"Invalid key path component starting with '%C'", [self.string characterAtIndex:pathComponentStart]]];
            result = NO;
        }

        if (result)
        {
            // Record end of last valid component
            length = self.scanLocation - start;

            // Done when there is no other path component separated by '.', skip separator
            done = ![self skipCharacter:'.'];
        }
    }

    if (result && expectKey)
    {
        result = NO;
        [self registerParseError:error
                        withCode:AKAParseErrorKeyPathOperatorRequiresSubsequentKey
                      atPosition:self.scanLocation
                          reason:[NSString stringWithFormat:@"Key path operator '@%@' requires a subsequent key, not another operator", lastOperator]];
    }

    if (result && store)
    {
        *store = [self.string substringWithRange:NSMakeRange(start, length)];
    }

    return result;
}

- (BOOL)           parseAttributes:(out_NSDictionary)store
                      withProvider:(AKABindingProvider*)provider
                             error:(out_NSError)error
{
    NSMutableDictionary* attributes = [AKAMutableOrderedDictionary new];
    BOOL result = [self skipCharacter:'{'];
    BOOL done = NO;
    while (result && !done)
    {
        NSString* identifier = nil;
        AKABindingExpression* attributeExpression = nil;

        [self skipWhitespaceAndNewlineCharacters];
        if (attributes.count == 0 && [self isAtCharacter:'}'])
        {
            // Allow for empty { }
            done = YES;
            break;
        }
        result = [self isAtValidFirstIdentifierCharacter];

        if (result)
        {
            result = [self parseIdentifier:&identifier
                                     error:error];
        }
        else
        {
            [self registerParseError:error
                            withCode:AKAParseErrorInvalidAttributeName
                          atPosition:self.scanLocation
                              reason:[NSString stringWithFormat:@"Invalid attribute name, expected a valid identifier, got '%C'", [self.string characterAtIndex:self.scanLocation ]]];
        }

        if (result)
        {
            [self skipWhitespaceAndNewlineCharacters];
            if ([self skipCharacter:':'])
            {
                [self skipWhitespaceAndNewlineCharacters];
                result = [self parseBindingExpression:&attributeExpression
                                         withProvider:[provider providerForAttributeNamed:identifier]
                                                error:error];
            }
            else
            {
                // "attributeName" is equivalent to "attributeName: $true"
                attributeExpression = [[AKABooleanConstantBindingExpression alloc] initWithConstant:@(YES)
                                                                                         attributes:attributes
                                                                                           provider:[provider providerForAttributeNamed:identifier]];
            }
        }

        if (result)
        {
            attributes[identifier] = attributeExpression;
            result = [self parseListSeparator:','
                                 orTerminator:'}'
                              terminatorFound:&done
                                        error:error];
        }
    }

    if (result && store != nil)
    {
        *store = attributes;
    }

    return result;
}

- (BOOL)parseListSeparator:(unichar)separator
              orTerminator:(unichar)terminator
           terminatorFound:(BOOL*_Nonnull)terminatorFound
                     error:(out_NSError)error
{
    BOOL result = YES;

    [self skipWhitespaceAndNewlineCharacters];
    BOOL done = [self skipCharacter:terminator];

    if (!done)
    {
        [self skipWhitespaceAndNewlineCharacters];
        result = [self skipCharacter:separator];
        if (result)
        {
            // Allow for trailing ','
            [self skipWhitespaceAndNewlineCharacters];
            done = [self skipCharacter:terminator];
        }
        else
        {
            [self registerParseError:error
                            withCode:AKAParseErrorUnterminatedBindingExpressionList
                          atPosition:self.scanLocation
                              reason:[NSString stringWithFormat:@"Unterminated binding expression list, expected '%C' or '%C'", separator, terminator]];
        }
    }
    *terminatorFound = done;
    return result;
}

- (BOOL)           parseIdentifier:(out_NSString)store
                             error:(out_NSError)error
{
    BOOL result = [self isAtValidFirstIdentifierCharacter];
    if (result)
    {
        NSInteger start = self.scanLocation++;
        while ([self isAtValidIdentifierCharacter])
        {
            ++self.scanLocation;
        }
        if (result && store)
        {
            *store = [self.string substringWithRange:NSMakeRange(start, self.scanLocation - start)];
        }
    }
    if (!result)
    {
        [self registerParseError:error
                        withCode:AKAParseErrorInvalidIdentifierCharacter
                      atPosition:self.scanLocation
                              reason:@"Invalid character, expected a valid identifier character"];
    }
    return result;
}

- (BOOL)       parseStringConstant:(out_NSString)stringStorage
                             error:(out_NSError)error
{
    BOOL done = NO;
    BOOL result = [self skipCharacter:'"'];
    if (result)
    {
        NSMutableString* string  = [NSMutableString new];

        while (result && !done)
        {
            if (self.isAtEnd)
            {
                [self registerParseError:error
                                withCode:AKAParseErrorUnterminatedStringConstant
                              atPosition:self.scanLocation
                                  reason:@"Unterminated string constant"];
                done = YES;
                result = NO;
            }
            else if ([self skipCharacter:'"'])
            {
                done = YES;
            }
            else if ([self skipCharacter:'\\'])
            {
                unichar escapedCharacter;
                if ([self parseEscapedCharacter:&escapedCharacter error:error])
                {
                    [string appendFormat:@"%C", escapedCharacter];
                }
                else
                {
                    done = YES;
                    result = NO;
                }
            }
            else
            {
                unichar c = [self.string characterAtIndex:self.scanLocation];
                self.scanLocation += 1;

                [string appendFormat:@"%C", c];
            }
        }

        if (result && stringStorage)
        {
            *stringStorage = [NSString stringWithString:string];
        }
    }
    else if (error != nil)
    {
        [self registerParseError:error
                        withCode:AKAParseErrorInvalidStringDelimiter
                      atPosition:self.scanLocation
                          reason:[NSString stringWithFormat:@"Invalid character introducting expected string: %U, expected \".", [self.string characterAtIndex:self.scanLocation]]];
    }


    return result;
}

- (BOOL)     parseEscapedCharacter:(out_unichar)unicharStorage
                             error:(out_NSError)error
{
    BOOL result = YES;
    unichar unescaped = '\0';
    unichar c = [self.string characterAtIndex:self.scanLocation];
    switch (c)
    {
        case 'a':
            unescaped = 0x07;
            break;
        case 'b':
            unescaped = 0x08;
            break;
        case 'f':
            unescaped = 0x0C;
            break;
        case 'n':
            unescaped = 0x0A;
            break;
        case 'r':
            unescaped = 0x0D;
            break;
        case 't':
            unescaped = 0x09;
            break;
        case 'v':
            unescaped = 0x0B;
            break;
        case '\\':
            unescaped = 0x5C;
            break;
        case '\'':
            unescaped = 0x27;
            break;
        case '\"':
            unescaped = 0x22;
            break;
        case '?':
            unescaped = 0x3F;
            break;
        case '0':
        case 'x':
        case 'u':
        case 'U':
            [self registerParseError:error
                            withCode:AKAParseErrorUnsupportedCharacterEscapeSequence
                          atPosition:self.scanLocation
                              reason:[NSString stringWithFormat:@"Character escape sequence starting with '%c' is valid but not (yet) supported by this implementation", (char)c]];
            result = NO;
            break;
    }
    if (result && unicharStorage != nil)
    {
        *unicharStorage = unescaped;
    }
    return result;
}


- (BOOL)       parseNumberConstant:(out_id)constantStore
                              type:(out_Class)typeStore
                             error:(out_NSError)error
{
    BOOL result = YES;
    Class type = nil;

    NSUInteger savedLocation = self.scanLocation;

    if ([self isAtValidFirstIntegerCharacter])
    {
        // Try to parse integer first
        long long longValue;
        type = [AKAIntegerConstantBindingExpression class];
        result = [self scanLongLong:&longValue];
        if (result && constantStore != nil)
        {
            *constantStore = [NSNumber numberWithLongLong:longValue];
        }
        // TODO: decide whether to support smaller integer types and if so, down cast if possible
    }
    if (!result || [self isAtValidDoubleCharacter])
    {
        self.scanLocation = savedLocation;
        result = YES;

        type = [AKADoubleConstantBindingExpression class];

        double doubleValue;
        result = [self scanDouble:&doubleValue];
        if (result && constantStore != nil)
        {
            *constantStore = [NSNumber numberWithDouble:doubleValue];
        }
    }

    if (result && typeStore)
    {
        *typeStore = type;
    }
    return result;
}

#pragma mark - Error Handling

- (NSString*)contextMessage
{
    return [self contextMessageWithMaxLeading:16
                                             maxTrailing:10];
}

- (NSString*)contextMessageWithMaxLeading:(NSUInteger)maxLeading
                              maxTrailing:(NSUInteger)maxTrailing
{
    NSString* result = nil;

    NSString* leadingContextElipsis = @"";
    NSString* leadingContext = @"";
    if (self.scanLocation > 0)
    {
        // Number of characters to the left of current location;
        NSUInteger leadingContextLength = self.scanLocation;

        if (leadingContextLength > maxLeading)
        {
            leadingContextLength = maxLeading;
            leadingContextElipsis = @"…";
        }

        NSRange range = NSMakeRange(self.scanLocation - leadingContextLength,
                                    leadingContextLength);

        leadingContext = [self.string substringWithRange:range];
    }

    NSString* trailingContextElipsis = @"";
    NSString* trailingContext = @"";
    if (self.string.length >= self.scanLocation+1)
    {
        NSUInteger trailingContextLength = self.string.length - (self.scanLocation + 1);

        if (trailingContextLength > maxTrailing)
        {
            trailingContextLength = maxTrailing;
            trailingContextElipsis = @"…";
        }

        NSRange range = NSMakeRange(self.scanLocation + 1, trailingContextLength);

        trailingContext = [self.string substringWithRange:range];
    }

    if (self.scanLocation < self.string.length)
    {
        result = [NSString stringWithFormat:@"“%@%@»%C«%@%@”",
                  leadingContextElipsis,
                  leadingContext,

                  [self.string characterAtIndex:self.scanLocation],

                  trailingContext,
                  trailingContextElipsis];
    }
    else
    {
        result = [NSString stringWithFormat:@"“%@%@»«%@%@”",
                  leadingContextElipsis,
                  leadingContext,

                  trailingContext,
                  trailingContextElipsis];
    }
    return result;
}

- (void)        registerParseError:(NSError* __autoreleasing __nonnull* __nullable)error
                          withCode:(AKABindingExpressionParseErrorCode)errorCode
                        atPosition:(NSUInteger)position
                            reason:(NSString*)reason
{
    if (error != nil)
    {
        NSString* context = @"";
        BOOL isOff = self.scanLocation > self.string.length;
        if (!isOff)
        {
            context = [self contextMessage];
        }
        NSString* description = [NSString stringWithFormat:@"%@\nPosition %lu%@%@", reason, (unsigned long)position, (context.length ? @": " : @""), context];
        *error = [NSError errorWithDomain:@"AKABindingExpressionParseError"
                                     code:errorCode
                                 userInfo:@{ NSLocalizedDescriptionKey: description,
                                             NSLocalizedFailureReasonErrorKey: reason }];
    }
}

#pragma mark - Scanner Tools (Convenience)

- (BOOL)    isAtCharacter:(unichar)character
{
    BOOL result = NO;
    if (!self.isAtEnd)
    {
        result = [self.string characterAtIndex:self.scanLocation] == character;
    }
    return result;
}

- (BOOL)    isAtValidKeyPathComponentFirstCharacter
{
    return [self isAtCharacter:'@'] || [self isAtValidFirstIdentifierCharacter];
}

- (BOOL)    isAtValidFirstNumberCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        unichar c = [self.string characterAtIndex:self.scanLocation];
        result = ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.');
    }
    return result;
}

- (BOOL)    isAtValidDoubleCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        unichar c = [self.string characterAtIndex:self.scanLocation];
        result = ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E');
    }
    return result;
}

- (BOOL)    isAtValidFirstIntegerCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        unichar c = [self.string characterAtIndex:self.scanLocation];
        result = ((c >= '0' && c <= '9') || c == '-');
    }
    return result;
}

- (BOOL)    isAtValidIntegerCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        unichar c = [self.string characterAtIndex:self.scanLocation];
        result = (c >= '0' && c <= '9');
    }
    return result;
}

- (BOOL)    isAtValidFirstIdentifierCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        unichar c = [self.string characterAtIndex:self.scanLocation];
        result = ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
    }
    return result;
}

- (BOOL)    isAtValidIdentifierCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        unichar c = [self.string characterAtIndex:self.scanLocation];
        result = ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_');
    }
    return result;
}

- (BOOL)    skipCharacter:(unichar)character
{
    BOOL result = [self isAtCharacter:character];
    if (result)
    {
        [self skipCurrentCharacter];
    }
    return result;
}

- (BOOL)    skipCurrentCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        self.scanLocation += 1;
    }
    return result;
}

- (BOOL)    isAtWhitespaceCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        result = [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self.string characterAtIndex:self.scanLocation]];
    }
    return result;
}

- (BOOL)    skipWhitespaceCharacters
{
    BOOL result = NO;
    while ([self isAtWhitespaceCharacter])
    {
        result |= [self skipCurrentCharacter];
    }
    return result;
}

- (BOOL)    isAtWhitespaceOrNewlineCharacter
{
    BOOL result = !self.isAtEnd;
    if (result)
    {
        result = [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self.string characterAtIndex:self.scanLocation]];
    }
    return result;
}

- (BOOL)    skipWhitespaceAndNewlineCharacters
{
    BOOL result = NO;
    while ([self isAtWhitespaceOrNewlineCharacter])
    {
        result |= [self skipCurrentCharacter];
    }
    return result;
}

@end