/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <ReactABI20_0_0/ABI20_0_0RCTEventDispatcher.h>

/**
 * Represents a touch event, which may be composed of several touches (one for every finger).
 * For more information on contents of passed data structures see ABI20_0_0RCTTouchHandler.
 */
@interface ABI20_0_0RCTTouchEvent : NSObject <ABI20_0_0RCTEvent>

- (instancetype)initWithEventName:(NSString *)eventName
                         ReactABI20_0_0Tag:(NSNumber *)ReactABI20_0_0Tag
                     ReactABI20_0_0Touches:(NSArray<NSDictionary *> *)ReactABI20_0_0Touches
                   changedIndexes:(NSArray<NSNumber *> *)changedIndexes
                    coalescingKey:(uint16_t)coalescingKey NS_DESIGNATED_INITIALIZER;
@end
