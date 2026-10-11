// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN
BOOL EcholMEInsertText(id client, NSString *text);
BOOL EcholMESetMarkedText(id client, NSAttributedString *text, NSRange selection);
BOOL EcholMEGetCaretRect(id client, NSRect *rect);
NSString * _Nullable EcholMEClientBundleIdentifier(id client);
void EcholMEOverrideKeyboard(id client, NSString *name);
NS_ASSUME_NONNULL_END
