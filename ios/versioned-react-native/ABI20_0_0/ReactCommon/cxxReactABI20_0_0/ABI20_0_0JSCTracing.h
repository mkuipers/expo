// Copyright 2004-present Facebook. All Rights Reserved.

#pragma once

#if defined(WITH_JSC_EXTRA_TRACING) || DEBUG

#include <inttypes.h>
#include <ABI20_0_0jschelpers/ABI20_0_0JavaScriptCore.h>

namespace facebook {
namespace ReactABI20_0_0 {

uint64_t tracingTagFromJSValue(JSContextRef ctx, JSValueRef value, JSValueRef* exception);
void addNativeTracingHooks(JSGlobalContextRef ctx);

} }

#endif
