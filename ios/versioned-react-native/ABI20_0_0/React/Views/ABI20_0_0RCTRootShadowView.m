/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI20_0_0RCTRootShadowView.h"

#import "ABI20_0_0RCTI18nUtil.h"

@implementation ABI20_0_0RCTRootShadowView

- (instancetype)init
{
  self = [super init];
  if (self) {
    _baseDirection = [[ABI20_0_0RCTI18nUtil sharedInstance] isRTL] ? ABI20_0_0YGDirectionRTL : ABI20_0_0YGDirectionLTR;
    _availableSize = CGSizeMake(INFINITY, INFINITY);
  }
  return self;
}

- (NSSet<ABI20_0_0RCTShadowView *> *)collectViewsWithUpdatedFrames
{
  // Treating `INFINITY` as `ABI20_0_0YGUndefined` (which equals `NAN`).
  float availableWidth = _availableSize.width == INFINITY ? ABI20_0_0YGUndefined : _availableSize.width;
  float availableHeight = _availableSize.height == INFINITY ? ABI20_0_0YGUndefined : _availableSize.height;

  ABI20_0_0YGNodeCalculateLayout(self.yogaNode, availableWidth, availableHeight, _baseDirection);

  NSMutableSet<ABI20_0_0RCTShadowView *> *viewsWithNewFrame = [NSMutableSet set];
  [self applyLayoutNode:self.yogaNode viewsWithNewFrame:viewsWithNewFrame absolutePosition:CGPointZero];
  return viewsWithNewFrame;
}

@end
