//
//  AKAViewBinding.h
//  AKABeacon
//
//  Created by Michael Utech on 13.10.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import UIKit;

#import "AKABinding.h"

/**
 * Abstract base class for bindings which target views.
 */
@interface AKAViewBinding: AKABinding

/**
 The bindings target view (redeclared with restricted type UIView).
 */
@property(nonatomic, readonly, weak, nullable) UIView*                    target;

@end


