//
//  AKAControlsStyleKit.h
//  AKAControls
//
//  Created by Michael Utech on 10.04.15.
//  Copyright (c) 2015 Gripsware GmbH. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface AKAControlsStyleKit : NSObject

// Colors
+ (UIColor*)barButtonItemForegroundColor;

// Drawing Methods
+ (void)drawBackBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth;
+ (void)drawForthBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth;

// Generated Images
+ (UIImage*)imageOfBackBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth;
+ (UIImage*)imageOfForthBarButtonItemIconWithBarButtonItemStrokeWidth: (CGFloat)barButtonItemStrokeWidth;

@end
