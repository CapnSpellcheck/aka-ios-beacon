//
//  AKAControlsStyleKit.m
//  AKAControls
//
//  Created by Michael Utech on 10.04.15.
//  Copyright (c) 2015 Gripsware GmbH. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import "AKAControlsStyleKit.h"


@implementation AKAControlsStyleKit

#pragma mark Cache

static UIColor* _barButtonItemForegroundColor = nil;

#pragma mark Initialization

+ (void)initialize
{
    // Colors Initialization
    _barButtonItemForegroundColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];

}

#pragma mark Colors

+ (UIColor*)barButtonItemForegroundColor { return _barButtonItemForegroundColor; }

#pragma mark Drawing Methods

+ (void)drawBackBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(29, 8)];
    [bezierPath addLineToPoint: CGPointMake(15, 21.6)];
    [bezierPath addLineToPoint: CGPointMake(29, 36)];
    [AKAControlsStyleKit.barButtonItemForegroundColor setStroke];
    bezierPath.lineWidth = barButtonItemStrokeWidth;
    [bezierPath stroke];
}

+ (void)drawForthBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth
{

    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(15, 8)];
    [bezierPath addLineToPoint: CGPointMake(29, 21.6)];
    [bezierPath addLineToPoint: CGPointMake(15, 36)];
    [AKAControlsStyleKit.barButtonItemForegroundColor setStroke];
    bezierPath.lineWidth = barButtonItemStrokeWidth;
    [bezierPath stroke];
}

#pragma mark Generated Images

+ (UIImage*)imageOfBackBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(44, 44), NO, 0.0f);
    [AKAControlsStyleKit drawBackBarButtonItemIconWithBarButtonItemStrokeWidth: barButtonItemStrokeWidth];

    UIImage* imageOfBackBarButtonItemIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfBackBarButtonItemIcon;
}

+ (UIImage*)imageOfForthBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(44, 44), NO, 0.0f);
    [AKAControlsStyleKit drawForthBarButtonItemIconWithBarButtonItemStrokeWidth: barButtonItemStrokeWidth];

    UIImage* imageOfForthBarButtonItemIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageOfForthBarButtonItemIcon;
}

@end
