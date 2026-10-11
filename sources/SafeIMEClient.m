// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.
#import "SafeIMEClient.h"
#import <InputMethodKit/InputMethodKit.h>
#import <math.h>

// Swift do/catch cannot catch Objective-C NSException. Check optional host
// selectors and contain those exceptions without logging text/client details.
BOOL EcholMEInsertText(id client, NSString *text) {
  @try {
    if (![client respondsToSelector:@selector(insertText:replacementRange:)]) return NO;
    [(id<IMKTextInput>)client insertText:text replacementRange:NSMakeRange(NSNotFound, 0)];
    return YES;
  } @catch (NSException *exception) { return NO; }
}

BOOL EcholMESetMarkedText(id client, NSAttributedString *text, NSRange selection) {
  @try {
    if (![client respondsToSelector:@selector(setMarkedText:selectionRange:replacementRange:)]) return NO;
    [(id<IMKTextInput>)client setMarkedText:text selectionRange:selection
                         replacementRange:NSMakeRange(NSNotFound, 0)];
    return YES;
  } @catch (NSException *exception) { return NO; }
}

BOOL EcholMEGetCaretRect(id client, NSRect *rect) {
  if (rect == NULL) return NO;
  *rect = NSZeroRect;
  @try {
    if (![client respondsToSelector:@selector(attributesForCharacterIndex:lineHeightRectangle:)]) return NO;
    [(id<IMKTextInput>)client attributesForCharacterIndex:0 lineHeightRectangle:rect];
    return isfinite(rect->origin.x) && isfinite(rect->origin.y) &&
           isfinite(rect->size.width) && rect->size.width >= 0 &&
           isfinite(rect->size.height) && rect->size.height > 0;
  } @catch (NSException *exception) { return NO; }
}

NSString *EcholMEClientBundleIdentifier(id client) {
  @try {
    if (![client respondsToSelector:@selector(bundleIdentifier)]) return nil;
    id value = [(id<IMKTextInput>)client bundleIdentifier];
    return [value isKindOfClass:[NSString class]] ? value : nil;
  } @catch (NSException *exception) { return nil; }
}

void EcholMEOverrideKeyboard(id client, NSString *name) {
  @try {
    if ([client respondsToSelector:@selector(overrideKeyboardWithKeyboardNamed:)]) {
      [(id<IMKTextInput>)client overrideKeyboardWithKeyboardNamed:name];
    }
  } @catch (NSException *exception) { /* Keep primary input usable. */ }
}
