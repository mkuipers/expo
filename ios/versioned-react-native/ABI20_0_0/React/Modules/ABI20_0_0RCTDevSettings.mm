/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI20_0_0RCTDevSettings.h"

#import <objc/runtime.h>

#import <JavaScriptCore/JavaScriptCore.h>

#import <ABI20_0_0jschelpers/ABI20_0_0JavaScriptCore.h>

#import "ABI20_0_0RCTBridge+Private.h"
#import "ABI20_0_0RCTBridgeModule.h"
#import "ABI20_0_0RCTEventDispatcher.h"
#import "ABI20_0_0RCTJSCSamplingProfiler.h"
#import "ABI20_0_0RCTJSEnvironment.h"
#import "ABI20_0_0RCTLog.h"
#import "ABI20_0_0RCTProfile.h"
#import "ABI20_0_0RCTUtils.h"

NSString *const kABI20_0_0RCTDevSettingProfilingEnabled = @"profilingEnabled";
NSString *const kABI20_0_0RCTDevSettingHotLoadingEnabled = @"hotLoadingEnabled";
NSString *const kABI20_0_0RCTDevSettingLiveReloadEnabled = @"liveReloadEnabled";
NSString *const kABI20_0_0RCTDevSettingIsInspectorShown = @"showInspector";
NSString *const kABI20_0_0RCTDevSettingIsDebuggingRemotely = @"isDebuggingRemotely";
NSString *const kABI20_0_0RCTDevSettingExecutorOverrideClass = @"executor-override";
NSString *const kABI20_0_0RCTDevSettingShakeToShowDevMenu = @"shakeToShow";
NSString *const kABI20_0_0RCTDevSettingIsPerfMonitorShown = @"ABI20_0_0RCTPerfMonitorKey";
NSString *const kABI20_0_0RCTDevSettingIsJSCProfilingEnabled = @"ABI20_0_0RCTJSCProfilerEnabled";
NSString *const kABI20_0_0RCTDevSettingStartSamplingProfilerOnLaunch = @"startSamplingProfilerOnLaunch";

NSString *const kABI20_0_0RCTDevSettingsUserDefaultsKey = @"ABI20_0_0RCTDevMenu";

#define ENABLE_PACKAGER_CONNECTION ABI20_0_0RCT_DEV && __has_include("ABI20_0_0RCTPackagerConnection.h")

#if ENABLE_PACKAGER_CONNECTION
#import "ABI20_0_0RCTPackagerConnection.h"
#endif

#define ENABLE_INSPECTOR ABI20_0_0RCT_DEV && __has_include("ABI20_0_0RCTInspectorDevServerHelper")

#if ENABLE_INSPECTOR
#import "ABI20_0_0RCTInspectorDevServerHelper.h"
#endif

#if ABI20_0_0RCT_DEV

@interface ABI20_0_0RCTDevSettingsUserDefaultsDataSource : NSObject <ABI20_0_0RCTDevSettingsDataSource>

@end

@implementation ABI20_0_0RCTDevSettingsUserDefaultsDataSource {
  NSMutableDictionary *_settings;
  NSUserDefaults *_userDefaults;
}

- (instancetype)init
{
  return [self initWithDefaultValues:nil];
}

- (instancetype)initWithDefaultValues:(NSDictionary *)defaultValues
{
  if (self = [super init]) {
    _userDefaults = [NSUserDefaults standardUserDefaults];
    if (defaultValues) {
      [self _reloadWithDefaults:defaultValues];
    }
  }
  return self;
}

- (void)updateSettingWithValue:(id)value forKey:(NSString *)key
{
  ABI20_0_0RCTAssert((key != nil), @"%@", [NSString stringWithFormat:@"%@: Tried to update nil key", [self class]]);

  id currentValue = [self settingForKey:key];
  if (currentValue == value || [currentValue isEqual:value]) {
    return;
  }
  if (value) {
    _settings[key] = value;
  } else {
    [_settings removeObjectForKey:key];
  }
  [_userDefaults setObject:_settings forKey:kABI20_0_0RCTDevSettingsUserDefaultsKey];
}

- (id)settingForKey:(NSString *)key
{
  return _settings[key];
}

- (void)_reloadWithDefaults:(NSDictionary *)defaultValues
{
  NSDictionary *existingSettings = [_userDefaults objectForKey:kABI20_0_0RCTDevSettingsUserDefaultsKey];
  _settings = existingSettings ? [existingSettings mutableCopy] : [NSMutableDictionary dictionary];
  for (NSString *key in [defaultValues keyEnumerator]) {
    if (!_settings[key]) {
      _settings[key] = defaultValues[key];
    }
  }
  [_userDefaults setObject:_settings forKey:kABI20_0_0RCTDevSettingsUserDefaultsKey];
}

@end

@interface ABI20_0_0RCTDevSettings () <ABI20_0_0RCTBridgeModule, ABI20_0_0RCTInvalidating>
{
  NSURLSessionDataTask *_liveReloadUpdateTask;
  NSURL *_liveReloadURL;
  BOOL _isJSLoaded;

#if ENABLE_PACKAGER_CONNECTION
  ABI20_0_0RCTPackagerConnection *_packagerConnection;
#endif
}

@property (nonatomic, strong) Class executorClass;
@property (nonatomic, readwrite, strong) id<ABI20_0_0RCTDevSettingsDataSource> dataSource;

@end

@implementation ABI20_0_0RCTDevSettings

@synthesize bridge = _bridge;

ABI20_0_0RCT_EXPORT_MODULE()

- (instancetype)init
{
  // default behavior is to use NSUserDefaults
  NSDictionary *defaultValues = @{
    kABI20_0_0RCTDevSettingShakeToShowDevMenu: @YES,
  };
  ABI20_0_0RCTDevSettingsUserDefaultsDataSource *dataSource = [[ABI20_0_0RCTDevSettingsUserDefaultsDataSource alloc] initWithDefaultValues:defaultValues];
  return [self initWithDataSource:dataSource];
}

- (instancetype)initWithDataSource:(id<ABI20_0_0RCTDevSettingsDataSource>)dataSource
{
  if (self = [super init]) {
    _dataSource = dataSource;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsLoaded:)
                                                 name:ABI20_0_0RCTJavaScriptDidLoadNotification
                                               object:nil];

    // Delay setup until after Bridge init
    dispatch_async(dispatch_get_main_queue(), ^{
      [self _synchronizeAllSettings];
    });
  }
  return self;
}

- (void)setBridge:(ABI20_0_0RCTBridge *)bridge
{
  ABI20_0_0RCTAssert(_bridge == nil, @"ABI20_0_0RCTDevSettings module should not be reused");
  _bridge = bridge;
  [self _configurePackagerConnection];

#if ENABLE_INSPECTOR
  // we need this dispatch back to the main thread because even though this
  // is executed on the main thread, at this point the bridge is not yet
  // finished with its initialisation. But it does finish by the time it
  // relinquishes control of the main thread, so only queue on the JS thread
  // after the current main thread operation is done.
  dispatch_async(dispatch_get_main_queue(), ^{
    [bridge dispatchBlock:^{
      [ABI20_0_0RCTInspectorDevServerHelper connectForContext:bridge.jsContextRef
                                       withBundleURL:bridge.bundleURL];
    } queue:ABI20_0_0RCTJSThread];
  });
#endif
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)invalidate
{
  [_liveReloadUpdateTask cancel];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_updateSettingWithValue:(id)value forKey:(NSString *)key
{
  [_dataSource updateSettingWithValue:value forKey:key];
}

- (id)settingForKey:(NSString *)key
{
  return [_dataSource settingForKey:key];
}

- (BOOL)isRemoteDebuggingAvailable
{
  Class jsDebuggingExecutorClass = objc_lookUpClass("ABI20_0_0RCTWebSocketExecutor");
  return (jsDebuggingExecutorClass != nil);
}

- (BOOL)isHotLoadingAvailable
{
  return _bridge.bundleURL && !_bridge.bundleURL.fileURL; // Only works when running from server
}

- (BOOL)isLiveReloadAvailable
{
  return (_liveReloadURL != nil);
}

- (BOOL)isJSCSamplingProfilerAvailable
{
  return JSC_JSSamplingProfilerEnabled(_bridge.jsContextRef);
}

ABI20_0_0RCT_EXPORT_METHOD(reload)
{
  [_bridge reload];
}

ABI20_0_0RCT_EXPORT_METHOD(setIsShakeToShowDevMenuEnabled:(BOOL)enabled)
{
  [self _updateSettingWithValue:@(enabled) forKey:kABI20_0_0RCTDevSettingShakeToShowDevMenu];
}

- (BOOL)isShakeToShowDevMenuEnabled
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingShakeToShowDevMenu] boolValue];
}

ABI20_0_0RCT_EXPORT_METHOD(setIsDebuggingRemotely:(BOOL)enabled)
{
  [self _updateSettingWithValue:@(enabled) forKey:kABI20_0_0RCTDevSettingIsDebuggingRemotely];
  [self _remoteDebugSettingDidChange];
}

- (BOOL)isDebuggingRemotely
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingIsDebuggingRemotely] boolValue];
}

- (void)_remoteDebugSettingDidChange
{
  // This value is passed as a command-line argument, so fall back to reading from NSUserDefaults directly
  NSString *executorOverride = [[NSUserDefaults standardUserDefaults] stringForKey:kABI20_0_0RCTDevSettingExecutorOverrideClass];
  Class executorOverrideClass = executorOverride ? NSClassFromString(executorOverride) : nil;
  if (executorOverrideClass) {
    self.executorClass = executorOverrideClass;
  } else {
    BOOL enabled = self.isRemoteDebuggingAvailable && self.isDebuggingRemotely;
    self.executorClass = enabled ? objc_getClass("ABI20_0_0RCTWebSocketExecutor") : nil;
  }
}

ABI20_0_0RCT_EXPORT_METHOD(setProfilingEnabled:(BOOL)enabled)
{
  [self _updateSettingWithValue:@(enabled) forKey:kABI20_0_0RCTDevSettingProfilingEnabled];
  [self _profilingSettingDidChange];
}

- (BOOL)isProfilingEnabled
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingProfilingEnabled] boolValue];
}

- (void)_profilingSettingDidChange
{
  BOOL enabled = self.isProfilingEnabled;
  if (_liveReloadURL && enabled != ABI20_0_0RCTProfileIsProfiling()) {
    if (enabled) {
      [_bridge startProfiling];
    } else {
      [_bridge stopProfiling:^(NSData *logData) {
        ABI20_0_0RCTProfileSendResult(self->_bridge, @"systrace", logData);
      }];
    }
  }
}

ABI20_0_0RCT_EXPORT_METHOD(setLiveReloadEnabled:(BOOL)enabled)
{
  [self _updateSettingWithValue:@(enabled) forKey:kABI20_0_0RCTDevSettingLiveReloadEnabled];
  [self _liveReloadSettingDidChange];
}

- (BOOL)isLiveReloadEnabled
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingLiveReloadEnabled] boolValue];
}

- (void)_liveReloadSettingDidChange
{
  BOOL liveReloadEnabled = (self.isLiveReloadAvailable && self.isLiveReloadEnabled);
  if (liveReloadEnabled) {
    [self _pollForLiveReload];
  } else {
    [_liveReloadUpdateTask cancel];
    _liveReloadUpdateTask = nil;
  }
}

ABI20_0_0RCT_EXPORT_METHOD(setHotLoadingEnabled:(BOOL)enabled)
{
  [self _updateSettingWithValue:@(enabled) forKey:kABI20_0_0RCTDevSettingHotLoadingEnabled];
  [self _hotLoadingSettingDidChange];
}

- (BOOL)isHotLoadingEnabled
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingHotLoadingEnabled] boolValue];
}

- (void)_hotLoadingSettingDidChange
{
  BOOL hotLoadingEnabled = self.isHotLoadingAvailable && self.isHotLoadingEnabled;
  if (ABI20_0_0RCTGetURLQueryParam(_bridge.bundleURL, @"hot").boolValue != hotLoadingEnabled) {
    _bridge.bundleURL = ABI20_0_0RCTURLByReplacingQueryParam(_bridge.bundleURL, @"hot",
                                                    hotLoadingEnabled ? @"true" : nil);
    [_bridge reload];
  }
}

ABI20_0_0RCT_EXPORT_METHOD(toggleElementInspector)
{
  BOOL value = [[self settingForKey:kABI20_0_0RCTDevSettingIsInspectorShown] boolValue];
  [self _updateSettingWithValue:@(!value) forKey:kABI20_0_0RCTDevSettingIsInspectorShown];

  if (_isJSLoaded) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"toggleElementInspector" body:nil];
#pragma clang diagnostic pop
  }
}

- (void)toggleJSCSamplingProfiler
{
  JSContext *context = _bridge.jsContext;
  JSGlobalContextRef globalContext = context.JSGlobalContextRef;
  // JSPokeSamplingProfiler() toggles the profiling process
  JSValueRef jsResult = JSC_JSPokeSamplingProfiler(globalContext);

  if (JSC_JSValueGetType(globalContext, jsResult) != kJSTypeNull) {
    NSString *results = [[JSC_JSValue(globalContext) valueWithJSValueRef:jsResult inContext:context] toObject];
    ABI20_0_0RCTJSCSamplingProfiler *profilerModule = [_bridge moduleForClass:[ABI20_0_0RCTJSCSamplingProfiler class]];
    [profilerModule operationCompletedWithResults:results];
  }
}

- (BOOL)isElementInspectorShown
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingIsInspectorShown] boolValue];
}

- (void)setIsPerfMonitorShown:(BOOL)isPerfMonitorShown
{
  [self _updateSettingWithValue:@(isPerfMonitorShown) forKey:kABI20_0_0RCTDevSettingIsPerfMonitorShown];
}

- (BOOL)isPerfMonitorShown
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingIsPerfMonitorShown] boolValue];
}

- (void)setIsJSCProfilingEnabled:(BOOL)isJSCProfilingEnabled
{
  [self _updateSettingWithValue:@(isJSCProfilingEnabled) forKey:kABI20_0_0RCTDevSettingIsJSCProfilingEnabled];
}

- (BOOL)isJSCProfilingEnabled
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingIsJSCProfilingEnabled] boolValue];
}

- (void)setStartSamplingProfilerOnLaunch:(BOOL)startSamplingProfilerOnLaunch
{
  [self _updateSettingWithValue:@(startSamplingProfilerOnLaunch) forKey:kABI20_0_0RCTDevSettingStartSamplingProfilerOnLaunch];
}

- (BOOL)startSamplingProfilerOnLaunch
{
  return [[self settingForKey:kABI20_0_0RCTDevSettingStartSamplingProfilerOnLaunch] boolValue];
}

- (void)setExecutorClass:(Class)executorClass
{
  _executorClass = executorClass;
  if (_bridge.executorClass != executorClass) {

    // TODO (6929129): we can remove this special case test once we have better
    // support for custom executors in the dev menu. But right now this is
    // needed to prevent overriding a custom executor with the default if a
    // custom executor has been set directly on the bridge
    if (executorClass == Nil &&
        _bridge.executorClass != objc_lookUpClass("ABI20_0_0RCTWebSocketExecutor")) {
      return;
    }

    _bridge.executorClass = executorClass;
    [_bridge reload];
  }
}

#if ENABLE_PACKAGER_CONNECTION

- (void)addHandler:(id<ABI20_0_0RCTPackagerClientMethod>)handler forPackagerMethod:(NSString *)name
{
  ABI20_0_0RCTAssert(_packagerConnection, @"Expected packager connection");
  [_packagerConnection addHandler:handler forMethod:name];
}

#elif ABI20_0_0RCT_DEV

- (void)addHandler:(id<ABI20_0_0RCTPackagerClientMethod>)handler forPackagerMethod:(NSString *)name {}

#endif

#pragma mark - Internal

- (void)_configurePackagerConnection
{
#if ENABLE_PACKAGER_CONNECTION
  if (_packagerConnection) {
    return;
  }

  _packagerConnection = [ABI20_0_0RCTPackagerConnection connectionForBridge:_bridge];
#endif
}

/**
 *  Query the data source for all possible settings and make sure we're doing the right
 *  thing for the state of each setting.
 */
- (void)_synchronizeAllSettings
{
  [self _hotLoadingSettingDidChange];
  [self _liveReloadSettingDidChange];
  [self _remoteDebugSettingDidChange];
  [self _profilingSettingDidChange];
}

- (void)_pollForLiveReload
{
  if (!_isJSLoaded || ![[self settingForKey:kABI20_0_0RCTDevSettingLiveReloadEnabled] boolValue] || !_liveReloadURL) {
    return;
  }

  if (_liveReloadUpdateTask) {
    return;
  }

  __weak ABI20_0_0RCTDevSettings *weakSelf = self;
  _liveReloadUpdateTask = [[NSURLSession sharedSession] dataTaskWithURL:_liveReloadURL completionHandler:
                           ^(__unused NSData *data, NSURLResponse *response, NSError *error) {

                             dispatch_async(dispatch_get_main_queue(), ^{
                               __strong ABI20_0_0RCTDevSettings *strongSelf = weakSelf;
                               if (strongSelf && [[strongSelf settingForKey:kABI20_0_0RCTDevSettingLiveReloadEnabled] boolValue]) {
                                 NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
                                 if (!error && HTTPResponse.statusCode == 205) {
                                   [strongSelf reload];
                                 } else {
                                   if (error.code != NSURLErrorCancelled) {
                                     strongSelf->_liveReloadUpdateTask = nil;
                                     [strongSelf _pollForLiveReload];
                                   }
                                 }
                               }
                             });

                           }];

  [_liveReloadUpdateTask resume];
}

- (void)jsLoaded:(NSNotification *)notification
{
  if (notification.userInfo[@"bridge"] != _bridge) {
    return;
  }

  _isJSLoaded = YES;

  // Check if live reloading is available
  NSURL *scriptURL = _bridge.bundleURL;
  if (![scriptURL isFileURL]) {
    // Live reloading is disabled when running from bundled JS file
    _liveReloadURL = [[NSURL alloc] initWithString:@"/onchange" relativeToURL:scriptURL];
  } else {
    _liveReloadURL = nil;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    // update state again after the bridge has finished loading
    [self _synchronizeAllSettings];

    // Inspector can only be shown after JS has loaded
    if ([self isElementInspectorShown]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      [self.bridge.eventDispatcher sendDeviceEventWithName:@"toggleElementInspector" body:nil];
#pragma clang diagnostic pop
    }
  });
}

@end

#else // #if ABI20_0_0RCT_DEV

@implementation ABI20_0_0RCTDevSettings

- (instancetype)initWithDataSource:(id<ABI20_0_0RCTDevSettingsDataSource>)dataSource { return [super init]; }
- (BOOL)isHotLoadingAvailable { return NO; }
- (BOOL)isLiveReloadAvailable { return NO; }
- (BOOL)isRemoteDebuggingAvailable { return NO; }
- (id)settingForKey:(NSString *)key { return nil; }
- (void)reload {}
- (void)toggleElementInspector {}
- (void)toggleJSCSamplingProfiler {}

@end

#endif

@implementation ABI20_0_0RCTBridge (ABI20_0_0RCTDevSettings)

- (ABI20_0_0RCTDevSettings *)devSettings
{
#if ABI20_0_0RCT_DEV
  return [self moduleForClass:[ABI20_0_0RCTDevSettings class]];
#else
  return nil;
#endif
}

@end
