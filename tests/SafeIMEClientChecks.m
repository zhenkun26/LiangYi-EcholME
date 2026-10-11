// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.
#import "SafeIMEClient.h"
#import <math.h>

// Intentionally not an IMKTextInput implementation: test optional selectors
// and hostile Objective-C client behavior without launching or contacting IMK.
@interface FixtureClient : NSObject
@property BOOL throws;
@property BOOL omitsCaret;
@property NSRect caret;
@property NSRange replacement;
@property NSRange selection;
@property NSUInteger inserts;
@property NSUInteger marks;
@property NSUInteger overrides;
@property(copy) NSString *lastText;
@property(strong) id identifier;
@end

@implementation FixtureClient
- (void)failIfRequested {
  if (self.throws) @throw [NSException exceptionWithName:@"FixtureFailure" reason:@"synthetic" userInfo:nil];
}
- (void)insertText:(id)text replacementRange:(NSRange)replacement {
  [self failIfRequested];
  self.inserts++;
  self.lastText = text;
  self.replacement = replacement;
}
- (void)setMarkedText:(id)text selectionRange:(NSRange)selection replacementRange:(NSRange)replacement {
  [self failIfRequested];
  self.marks++;
  self.lastText = [text string];
  self.selection = selection;
  self.replacement = replacement;
}
- (NSDictionary *)attributesForCharacterIndex:(NSUInteger)index lineHeightRectangle:(NSRect *)rect {
  [self failIfRequested];
  if (!self.omitsCaret) *rect = self.caret;
  return @{};
}
- (id)bundleIdentifier { [self failIfRequested]; return self.identifier; }
- (void)overrideKeyboardWithKeyboardNamed:(NSString *)name { [self failIfRequested]; self.overrides++; }
@end

static NSMutableArray<NSString *> *checks;
static void check(BOOL condition, NSString *name) {
  if (!condition) {
    fprintf(stderr, "Safe host check failed: %s\n", name.UTF8String);
    exit(1);
  }
  [checks addObject:name];
}

int main(void) {
  @autoreleasepool {
    checks = [NSMutableArray array];
    NSObject *missing = [NSObject new];
    NSAttributedString *marked = [[NSAttributedString alloc] initWithString:@"hello"];
    NSRect rect = NSZeroRect;
    check(!EcholMEInsertText(missing, @"hello"), @"missing insertion selector rejected");
    check(!EcholMESetMarkedText(missing, marked, NSMakeRange(5, 0)), @"missing marking selector rejected");
    check(!EcholMEGetCaretRect(missing, &rect), @"missing geometry selector rejected");
    check(EcholMEClientBundleIdentifier(missing) == nil, @"missing bundle selector rejected");
    EcholMEOverrideKeyboard(missing, @"com.apple.keylayout.ABC");
    check(YES, @"missing keyboard selector safely ignored");

    FixtureClient *client = [FixtureClient new];
    client.identifier = @"io.github.synthetic.Fixture";
    client.caret = NSMakeRect(-1100, -150, 1, 18);
    check(EcholMEInsertText(client, @"hello") && client.inserts == 1 && [client.lastText isEqual:@"hello"], @"insertion called once with exact synthetic text");
    check(client.replacement.location == NSNotFound && client.replacement.length == 0, @"insertion replacement uses NSNotFound");
    check(EcholMESetMarkedText(client, marked, NSMakeRange(5, 0)) && client.marks == 1, @"marking supported");
    check(NSEqualRanges(client.selection, NSMakeRange(5, 0)) && NSEqualRanges(client.replacement, NSMakeRange(NSNotFound, 0)), @"marking selection and replacement preserved");
    check(EcholMEGetCaretRect(client, &rect) && NSEqualRects(rect, client.caret), @"finite negative-origin caret supported");
    check([EcholMEClientBundleIdentifier(client) isEqual:client.identifier], @"valid bundle identifier supported");
    EcholMEOverrideKeyboard(client, @"com.apple.keylayout.ABC");
    check(client.overrides == 1, @"keyboard override called once");
    client.identifier = @7;
    check(EcholMEClientBundleIdentifier(client) == nil, @"wrong bundle return type rejected");
    client.caret = NSMakeRect(NAN, 0, 1, 18);
    check(!EcholMEGetCaretRect(client, &rect), @"NaN geometry rejected");
    client.caret = NSMakeRect(0, 0, -1, 18);
    check(!EcholMEGetCaretRect(client, &rect), @"negative width rejected");
    client.caret = NSMakeRect(0, 0, 1, 0);
    check(!EcholMEGetCaretRect(client, &rect), @"zero height rejected");
    client.omitsCaret = YES;
    rect = NSMakeRect(100, 100, 1, 18);
    check(!EcholMEGetCaretRect(client, &rect), @"unwritten rectangle cannot reuse stale geometry");
    client.throws = YES;
    check(!EcholMEInsertText(client, @"world") && client.inserts == 1, @"insertion exception contained without retry");
    check(!EcholMESetMarkedText(client, marked, NSMakeRange(5, 0)), @"marking exception contained");
    check(!EcholMEGetCaretRect(client, &rect), @"geometry exception contained");
    check(EcholMEClientBundleIdentifier(client) == nil, @"bundle exception contained");
    EcholMEOverrideKeyboard(client, @"com.apple.keylayout.ABC");
    check(client.overrides == 1, @"keyboard exception contained without retry");

    NSDictionary *report = @{ @"status": @"PASS", @"check_count": @(checks.count), @"checks": checks,
                             @"scope": @"production Objective-C host wrapper; synthetic selectors and exceptions, no IMK IPC" };
    NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:nil];
    puts([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);
  }
  return 0;
}
