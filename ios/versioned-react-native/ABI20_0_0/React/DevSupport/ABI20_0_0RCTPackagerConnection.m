/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI20_0_0RCTPackagerConnection.h"

#import <objc/runtime.h>

#import <ReactABI20_0_0/ABI20_0_0RCTAssert.h>
#import <ReactABI20_0_0/ABI20_0_0RCTBridge.h>
#import <ReactABI20_0_0/ABI20_0_0RCTConvert.h>
#import <ReactABI20_0_0/ABI20_0_0RCTDefines.h>
#import <ReactABI20_0_0/ABI20_0_0RCTLog.h>
#import <ReactABI20_0_0/ABI20_0_0RCTReconnectingWebSocket.h>
#import <ReactABI20_0_0/ABI20_0_0RCTSRWebSocket.h>
#import <ReactABI20_0_0/ABI20_0_0RCTUtils.h>
#import <ReactABI20_0_0/ABI20_0_0RCTWebSocketObserverProtocol.h>

#import "ABI20_0_0RCTPackagerConnectionBridgeConfig.h"
#import "ABI20_0_0RCTReloadPackagerMethod.h"
#import "ABI20_0_0RCTSamplingProfilerPackagerMethod.h"

#if ABI20_0_0RCT_DEV

@interface ABI20_0_0RCTPackagerConnection () <ABI20_0_0RCTWebSocketProtocolDelegate>
@end

@implementation ABI20_0_0RCTPackagerConnection {
  NSURL *_packagerURL;
  ABI20_0_0RCTReconnectingWebSocket *_socket;
  NSMutableDictionary<NSString *, id<ABI20_0_0RCTPackagerClientMethod>> *_handlers;
}

+ (instancetype)connectionForBridge:(ABI20_0_0RCTBridge *)bridge
{
  ABI20_0_0RCTPackagerConnectionBridgeConfig *config = [[ABI20_0_0RCTPackagerConnectionBridgeConfig alloc] initWithBridge:bridge];
  return [[[self class] alloc] initWithConfig:config];
}

- (instancetype)initWithConfig:(id<ABI20_0_0RCTPackagerConnectionConfig>)config
{
  if (self = [super init]) {
    _packagerURL = [config packagerURL];
    _handlers = [[config defaultPackagerMethods] mutableCopy];

    [self connect];
  }
  return self;
}

- (void)connect
{
  ABI20_0_0RCTAssertMainQueue();

  NSURL *url = _packagerURL;
  if (!url) {
    return;
  }

  // The jsPackagerClient is a static map that holds different packager clients per the packagerURL
  // In case many instances of DevMenu are created, the latest instance that use the same URL as
  // previous instances will override given packager client's method handlers
  static NSMutableDictionary<NSString *, ABI20_0_0RCTReconnectingWebSocket *> *socketConnections = nil;
  if (socketConnections == nil) {
    socketConnections = [NSMutableDictionary new];
  }

  NSString *key = [url absoluteString];
  ABI20_0_0RCTReconnectingWebSocket *webSocket = socketConnections[key];
  if (!webSocket) {
    webSocket = [[ABI20_0_0RCTReconnectingWebSocket alloc] initWithURL:url];
    [webSocket start];
    socketConnections[key] = webSocket;
  }

  webSocket.delegate = self;
}

- (void)addHandler:(id<ABI20_0_0RCTPackagerClientMethod>)handler forMethod:(NSString *)name
{
  _handlers[name] = handler;
}

static BOOL isSupportedVersion(NSNumber *version)
{
  NSArray<NSNumber *> *const kSupportedVersions = @[ @(ABI20_0_0RCT_PACKAGER_CLIENT_PROTOCOL_VERSION) ];
  return [kSupportedVersions containsObject:version];
}

#pragma mark - ABI20_0_0RCTWebSocketProtocolDelegate

- (void)webSocket:(ABI20_0_0RCTSRWebSocket *)webSocket didReceiveMessage:(id)message
{
  if (!_handlers) {
    return;
  }

  NSError *error = nil;
  NSDictionary<NSString *, id> *msg = ABI20_0_0RCTJSONParse(message, &error);

  if (error) {
    ABI20_0_0RCTLogError(@"%@ failed to parse message with error %@\n<message>\n%@\n</message>", [self class], error, msg);
    return;
  }

  if (!isSupportedVersion(msg[@"version"])) {
    ABI20_0_0RCTLogError(@"%@ received message with not supported version %@", [self class], msg[@"version"]);
    return;
  }

  id<ABI20_0_0RCTPackagerClientMethod> methodHandler = _handlers[msg[@"method"]];
  if (!methodHandler) {
    if (msg[@"id"]) {
      NSString *errorMsg = [NSString stringWithFormat:@"%@ no handler found for method %@", [self class], msg[@"method"]];
      ABI20_0_0RCTLogError(errorMsg, msg[@"method"]);
      [[[ABI20_0_0RCTPackagerClientResponder alloc] initWithId:msg[@"id"]
                                               socket:webSocket] respondWithError:errorMsg];
    }
    return; // If it was a broadcast then we ignore it gracefully
  }

  if (msg[@"id"]) {
    [methodHandler handleRequest:msg[@"params"]
                   withResponder:[[ABI20_0_0RCTPackagerClientResponder alloc] initWithId:msg[@"id"]
                                                                         socket:webSocket]];
  } else {
    [methodHandler handleNotification:msg[@"params"]];
  }
}

@end

#endif
