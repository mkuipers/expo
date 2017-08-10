/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI20_0_0RCTViewManager.h"

#import "ABI20_0_0RCTBorderStyle.h"
#import "ABI20_0_0RCTBridge.h"
#import "ABI20_0_0RCTConvert.h"
#import "ABI20_0_0RCTEventDispatcher.h"
#import "ABI20_0_0RCTLog.h"
#import "ABI20_0_0RCTShadowView.h"
#import "ABI20_0_0RCTUIManager.h"
#import "ABI20_0_0RCTUtils.h"
#import "ABI20_0_0RCTView.h"
#import "UIView+ReactABI20_0_0.h"
#import "ABI20_0_0RCTConvert+Transform.h"

#if TARGET_OS_TV
#import "ABI20_0_0RCTTVView.h"
#endif

@implementation ABI20_0_0RCTConvert(UIAccessibilityTraits)

ABI20_0_0RCT_MULTI_ENUM_CONVERTER(UIAccessibilityTraits, (@{
  @"none": @(UIAccessibilityTraitNone),
  @"button": @(UIAccessibilityTraitButton),
  @"link": @(UIAccessibilityTraitLink),
  @"header": @(UIAccessibilityTraitHeader),
  @"search": @(UIAccessibilityTraitSearchField),
  @"image": @(UIAccessibilityTraitImage),
  @"selected": @(UIAccessibilityTraitSelected),
  @"plays": @(UIAccessibilityTraitPlaysSound),
  @"key": @(UIAccessibilityTraitKeyboardKey),
  @"text": @(UIAccessibilityTraitStaticText),
  @"summary": @(UIAccessibilityTraitSummaryElement),
  @"disabled": @(UIAccessibilityTraitNotEnabled),
  @"frequentUpdates": @(UIAccessibilityTraitUpdatesFrequently),
  @"startsMedia": @(UIAccessibilityTraitStartsMediaSession),
  @"adjustable": @(UIAccessibilityTraitAdjustable),
  @"allowsDirectInteraction": @(UIAccessibilityTraitAllowsDirectInteraction),
  @"pageTurn": @(UIAccessibilityTraitCausesPageTurn),
}), UIAccessibilityTraitNone, unsignedLongLongValue)

@end

@implementation ABI20_0_0RCTViewManager

@synthesize bridge = _bridge;

ABI20_0_0RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return ABI20_0_0RCTGetUIManagerQueue();
}

- (UIView *)view
{
#if TARGET_OS_TV
  return [ABI20_0_0RCTTVView new];
#else
  return [ABI20_0_0RCTView new];
#endif
}

- (ABI20_0_0RCTShadowView *)shadowView
{
  return [ABI20_0_0RCTShadowView new];
}

- (NSArray<NSString *> *)customBubblingEventTypes
{
  return @[

    // Generic events
    @"press",
    @"change",
    @"focus",
    @"blur",
    @"submitEditing",
    @"endEditing",
    @"keyPress",

    // Touch events
    @"touchStart",
    @"touchMove",
    @"touchCancel",
    @"touchEnd",
  ];
}

- (ABI20_0_0RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(__unused ABI20_0_0RCTShadowView *)shadowView
{
  return nil;
}

- (ABI20_0_0RCTViewManagerUIBlock)uiBlockToAmendWithShadowViewRegistry:(__unused NSDictionary<NSNumber *, ABI20_0_0RCTShadowView *> *)shadowViewRegistry
{
  return nil;
}

#pragma mark - View properties

#if TARGET_OS_TV
// Apple TV properties
ABI20_0_0RCT_EXPORT_VIEW_PROPERTY(isTVSelectable, BOOL)
ABI20_0_0RCT_EXPORT_VIEW_PROPERTY(hasTVPreferredFocus, BOOL)
ABI20_0_0RCT_EXPORT_VIEW_PROPERTY(tvParallaxProperties, NSDictionary)
#endif

ABI20_0_0RCT_EXPORT_VIEW_PROPERTY(nativeID, NSString)

// Acessibility related properties
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(accessible, ReactABI20_0_0AccessibilityElement.isAccessibilityElement, BOOL)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(accessibilityLabel, ReactABI20_0_0AccessibilityElement.accessibilityLabel, NSString)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(accessibilityTraits, ReactABI20_0_0AccessibilityElement.accessibilityTraits, UIAccessibilityTraits)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(accessibilityViewIsModal, ReactABI20_0_0AccessibilityElement.accessibilityViewIsModal, BOOL)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(onAccessibilityTap, ReactABI20_0_0AccessibilityElement.onAccessibilityTap, ABI20_0_0RCTDirectEventBlock)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(onMagicTap, ReactABI20_0_0AccessibilityElement.onMagicTap, ABI20_0_0RCTDirectEventBlock)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(testID, ReactABI20_0_0AccessibilityElement.accessibilityIdentifier, NSString)

ABI20_0_0RCT_EXPORT_VIEW_PROPERTY(backgroundColor, UIColor)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(backfaceVisibility, layer.doubleSided, css_backface_visibility_t)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(opacity, alpha, CGFloat)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(shadowColor, layer.shadowColor, CGColor)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(shadowOffset, layer.shadowOffset, CGSize)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(shadowOpacity, layer.shadowOpacity, float)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(shadowRadius, layer.shadowRadius, CGFloat)
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(overflow, ABI20_0_0YGOverflow, ABI20_0_0RCTView)
{
  if (json) {
    view.clipsToBounds = [ABI20_0_0RCTConvert ABI20_0_0YGOverflow:json] != ABI20_0_0YGOverflowVisible;
  } else {
    view.clipsToBounds = defaultView.clipsToBounds;
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(shouldRasterizeIOS, BOOL, ABI20_0_0RCTView)
{
  view.layer.shouldRasterize = json ? [ABI20_0_0RCTConvert BOOL:json] : defaultView.layer.shouldRasterize;
  view.layer.rasterizationScale = view.layer.shouldRasterize ? [UIScreen mainScreen].scale : defaultView.layer.rasterizationScale;
}

ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(transform, CATransform3D, ABI20_0_0RCTView)
{
  view.layer.transform = json ? [ABI20_0_0RCTConvert CATransform3D:json] : defaultView.layer.transform;
  // TODO: Improve this by enabling edge antialiasing only for transforms with rotation or skewing
  view.layer.allowsEdgeAntialiasing = !CATransform3DIsIdentity(view.layer.transform);
}

ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(pointerEvents, ABI20_0_0RCTPointerEvents, ABI20_0_0RCTView)
{
  if ([view respondsToSelector:@selector(setPointerEvents:)]) {
    view.pointerEvents = json ? [ABI20_0_0RCTConvert ABI20_0_0RCTPointerEvents:json] : defaultView.pointerEvents;
    return;
  }

  if (!json) {
    view.userInteractionEnabled = defaultView.userInteractionEnabled;
    return;
  }

  switch ([ABI20_0_0RCTConvert ABI20_0_0RCTPointerEvents:json]) {
    case ABI20_0_0RCTPointerEventsUnspecified:
      // Pointer events "unspecified" acts as if a stylesheet had not specified,
      // which is different than "auto" in CSS (which cannot and will not be
      // supported in `ReactABI20_0_0`. "auto" may override a parent's "none".
      // Unspecified values do not.
      // This wouldn't override a container view's `userInteractionEnabled = NO`
      view.userInteractionEnabled = YES;
    case ABI20_0_0RCTPointerEventsNone:
      view.userInteractionEnabled = NO;
      break;
    default:
      ABI20_0_0RCTLogError(@"UIView base class does not support pointerEvent value: %@", json);
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(removeClippedSubviews, BOOL, ABI20_0_0RCTView)
{
  if ([view respondsToSelector:@selector(setRemoveClippedSubviews:)]) {
    view.removeClippedSubviews = json ? [ABI20_0_0RCTConvert BOOL:json] : defaultView.removeClippedSubviews;
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(borderRadius, CGFloat, ABI20_0_0RCTView) {
  if ([view respondsToSelector:@selector(setBorderRadius:)]) {
    view.borderRadius = json ? [ABI20_0_0RCTConvert CGFloat:json] : defaultView.borderRadius;
  } else {
    view.layer.cornerRadius = json ? [ABI20_0_0RCTConvert CGFloat:json] : defaultView.layer.cornerRadius;
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(borderColor, CGColor, ABI20_0_0RCTView)
{
  if ([view respondsToSelector:@selector(setBorderColor:)]) {
    view.borderColor = json ? [ABI20_0_0RCTConvert CGColor:json] : defaultView.borderColor;
  } else {
    view.layer.borderColor = json ? [ABI20_0_0RCTConvert CGColor:json] : defaultView.layer.borderColor;
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(borderWidth, float, ABI20_0_0RCTView)
{
  if ([view respondsToSelector:@selector(setBorderWidth:)]) {
    view.borderWidth = json ? [ABI20_0_0RCTConvert CGFloat:json] : defaultView.borderWidth;
  } else {
    view.layer.borderWidth = json ? [ABI20_0_0RCTConvert CGFloat:json] : defaultView.layer.borderWidth;
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(borderStyle, ABI20_0_0RCTBorderStyle, ABI20_0_0RCTView)
{
  if ([view respondsToSelector:@selector(setBorderStyle:)]) {
    view.borderStyle = json ? [ABI20_0_0RCTConvert ABI20_0_0RCTBorderStyle:json] : defaultView.borderStyle;
  }
}
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(hitSlop, UIEdgeInsets, ABI20_0_0RCTView)
{
  if ([view respondsToSelector:@selector(setHitTestEdgeInsets:)]) {
    if (json) {
      UIEdgeInsets hitSlopInsets = [ABI20_0_0RCTConvert UIEdgeInsets:json];
      view.hitTestEdgeInsets = UIEdgeInsetsMake(-hitSlopInsets.top, -hitSlopInsets.left, -hitSlopInsets.bottom, -hitSlopInsets.right);
    } else {
      view.hitTestEdgeInsets = defaultView.hitTestEdgeInsets;
    }
  }
}

#define ABI20_0_0RCT_VIEW_BORDER_PROPERTY(SIDE)                                  \
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Width, float, ABI20_0_0RCTView)           \
{                                                                       \
  if ([view respondsToSelector:@selector(setBorder##SIDE##Width:)]) {   \
    view.border##SIDE##Width = json ? [ABI20_0_0RCTConvert CGFloat:json] : defaultView.border##SIDE##Width; \
  }                                                                     \
}                                                                       \
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Color, UIColor, ABI20_0_0RCTView)         \
{                                                                       \
  if ([view respondsToSelector:@selector(setBorder##SIDE##Color:)]) {   \
    view.border##SIDE##Color = json ? [ABI20_0_0RCTConvert CGColor:json] : defaultView.border##SIDE##Color; \
  }                                                                     \
}

ABI20_0_0RCT_VIEW_BORDER_PROPERTY(Top)
ABI20_0_0RCT_VIEW_BORDER_PROPERTY(Right)
ABI20_0_0RCT_VIEW_BORDER_PROPERTY(Bottom)
ABI20_0_0RCT_VIEW_BORDER_PROPERTY(Left)

#define ABI20_0_0RCT_VIEW_BORDER_RADIUS_PROPERTY(SIDE)                           \
ABI20_0_0RCT_CUSTOM_VIEW_PROPERTY(border##SIDE##Radius, CGFloat, ABI20_0_0RCTView)        \
{                                                                       \
  if ([view respondsToSelector:@selector(setBorder##SIDE##Radius:)]) {  \
    view.border##SIDE##Radius = json ? [ABI20_0_0RCTConvert CGFloat:json] : defaultView.border##SIDE##Radius; \
  }                                                                     \
}                                                                       \

ABI20_0_0RCT_VIEW_BORDER_RADIUS_PROPERTY(TopLeft)
ABI20_0_0RCT_VIEW_BORDER_RADIUS_PROPERTY(TopRight)
ABI20_0_0RCT_VIEW_BORDER_RADIUS_PROPERTY(BottomLeft)
ABI20_0_0RCT_VIEW_BORDER_RADIUS_PROPERTY(BottomRight)

ABI20_0_0RCT_REMAP_VIEW_PROPERTY(display, ReactABI20_0_0Display, ABI20_0_0YGDisplay)
ABI20_0_0RCT_REMAP_VIEW_PROPERTY(zIndex, ReactABI20_0_0ZIndex, NSInteger)

#pragma mark - ShadowView properties

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(backgroundColor, UIColor)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(top, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(right, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(bottom, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(left, ABI20_0_0YGValue);

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(width, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(height, ABI20_0_0YGValue)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(minWidth, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(maxWidth, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(minHeight, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(maxHeight, ABI20_0_0YGValue)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(borderTopWidth, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(borderRightWidth, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(borderBottomWidth, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(borderLeftWidth, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(borderWidth, float)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(marginTop, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(marginRight, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(marginBottom, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(marginLeft, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(marginVertical, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(marginHorizontal, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(margin, ABI20_0_0YGValue)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(paddingTop, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(paddingRight, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(paddingBottom, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(paddingLeft, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(paddingVertical, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(paddingHorizontal, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(padding, ABI20_0_0YGValue)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(flex, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(flexGrow, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(flexShrink, float)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(flexBasis, ABI20_0_0YGValue)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(flexDirection, ABI20_0_0YGFlexDirection)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(flexWrap, ABI20_0_0YGWrap)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(justifyContent, ABI20_0_0YGJustify)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(alignItems, ABI20_0_0YGAlign)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(alignSelf, ABI20_0_0YGAlign)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(alignContent, ABI20_0_0YGAlign)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(position, ABI20_0_0YGPositionType)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(aspectRatio, float)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(overflow, ABI20_0_0YGOverflow)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(display, ABI20_0_0YGDisplay)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(onLayout, ABI20_0_0RCTDirectEventBlock)

ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(zIndex, NSInteger)
ABI20_0_0RCT_EXPORT_SHADOW_PROPERTY(direction, ABI20_0_0YGDirection)

@end
