/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI20_0_0RNSVGGroupManager.h"
#import "ABI20_0_0RNSVGCGFCRule.h"
#import "ABI20_0_0RNSVGGroup.h"

@implementation ABI20_0_0RNSVGGroupManager

ABI20_0_0RCT_EXPORT_MODULE()

- (ABI20_0_0RNSVGNode *)node
{
  return [ABI20_0_0RNSVGGroup new];
}

@end
