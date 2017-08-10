/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI20_0_0RCTImageSource.h"
#import "ABI20_0_0RCTUtils.h"

@interface ABI20_0_0RCTImageSource ()

@property (nonatomic, assign) BOOL packagerAsset;

@end

@implementation ABI20_0_0RCTImageSource

- (instancetype)initWithURLRequest:(NSURLRequest *)request size:(CGSize)size scale:(CGFloat)scale
{
  if ((self = [super init])) {
    _request = [request copy];
    _size = size;
    _scale = scale;
  }
  return self;
}

- (instancetype)imageSourceWithSize:(CGSize)size scale:(CGFloat)scale
{
  ABI20_0_0RCTImageSource *imageSource = [[ABI20_0_0RCTImageSource alloc] initWithURLRequest:_request
                                                                      size:size
                                                                     scale:scale];
  imageSource.packagerAsset = _packagerAsset;
  return imageSource;
}

- (BOOL)isEqual:(ABI20_0_0RCTImageSource *)object
{
  if (![object isKindOfClass:[ABI20_0_0RCTImageSource class]]) {
    return NO;
  }
  return [_request isEqual:object.request] && _scale == object.scale &&
  (CGSizeEqualToSize(_size, object.size) || CGSizeEqualToSize(object.size, CGSizeZero));
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<ABI20_0_0RCTImageSource: %p URL=%@, size=%@, scale=%0.f>",
          self, _request.URL, NSStringFromCGSize(_size), _scale];
}

@end

@implementation ABI20_0_0RCTConvert (ImageSource)

+ (ABI20_0_0RCTImageSource *)ABI20_0_0RCTImageSource:(id)json
{
  if (!json) {
    return nil;
  }

  NSURLRequest *request;
  CGSize size = CGSizeZero;
  CGFloat scale = 1.0;
  BOOL packagerAsset = NO;
  if ([json isKindOfClass:[NSDictionary class]]) {
    if (!(request = [self NSURLRequest:json])) {
      return nil;
    }
    size = [self CGSize:json];
    scale = [self CGFloat:json[@"scale"]] ?: [self BOOL:json[@"deprecated"]] ? 0.0 : 1.0;
    packagerAsset = [self BOOL:json[@"__packager_asset"]];
  } else if ([json isKindOfClass:[NSString class]]) {
    request = [self NSURLRequest:json];
  } else {
    ABI20_0_0RCTLogConvertError(json, @"an image. Did you forget to call resolveAssetSource() on the JS side?");
    return nil;
  }

  ABI20_0_0RCTImageSource *imageSource = [[ABI20_0_0RCTImageSource alloc] initWithURLRequest:request
                                                                      size:size
                                                                     scale:scale];
  imageSource.packagerAsset = packagerAsset;
  return imageSource;
}

ABI20_0_0RCT_ARRAY_CONVERTER(ABI20_0_0RCTImageSource)

@end
