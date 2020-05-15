//
//  main.m
//  mwv
//
//  Created by Amit Verma on 5/11/20.
//

#import "window.h"

#define ADD_SEP() [menu addItem:[NSMenuItem separatorItem]]
#define INIT_MENU(title) {menu = [[NSMenu alloc] initWithTitle:title]; NSMenuItem* item = [[NSMenuItem alloc] init];[item setSubmenu:menu];[menubar addItem:item];}
#define ADD_ITEM(title, sel, key) [menu addItem:[[NSMenuItem alloc] initWithTitle:title action:@selector(sel) keyEquivalent:key]]

#define ADD_ITEM_MASK(title, sel, key, mask){ \
NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:title action:@selector(sel) keyEquivalent:key]; \
item.keyEquivalentModifierMask = mask; \
[menu addItem:item]; \
}

@interface MyApplicationDelegate : NSObject <NSApplicationDelegate>
@end

@implementation MyApplicationDelegate{
  NSApplication* app;
}
-(id)initWithApp:(NSApplication*) application{
  self = [super init];
  app = application;

  NSMenu* menu;
  NSMenu* menubar = [[NSMenu alloc] init];
  NSString* appName = [[NSProcessInfo processInfo] processName];

  INIT_MENU(appName);
  ADD_ITEM([@"About " stringByAppendingString:appName], orderFrontStandardAboutPanel:, @"");
  ADD_SEP();
  ADD_ITEM([@"Hide " stringByAppendingString:appName], hideAll, @"h");
  ADD_ITEM([@"Quit " stringByAppendingString:appName], terminate:, @"q");

  INIT_MENU(@"File");
  ADD_ITEM(@"New", newWindow, @"n");
  ADD_ITEM(@"Reload", reload, @"r");
  ADD_ITEM(@"Hard Reload", hardReload, @"R");
  ADD_ITEM(@"Open Location", openLocation, @"l");
  ADD_ITEM(@"Close", performClose:, @"w");

  INIT_MENU(@"Edit");
  ADD_ITEM(@"Undo", undo, @"z");
  ADD_ITEM(@"Redo", redo, @"Z");
  ADD_SEP();
  ADD_ITEM(@"Cut", cut:, @"x");
  ADD_ITEM(@"Copy", copy:, @"c");
  ADD_ITEM(@"Paste", paste:, @"v");
  ADD_SEP();
  ADD_ITEM(@"Delete", delete:, @"");
  ADD_ITEM(@"Select All", selectAll:, @"a");

  INIT_MENU(@"Window");
  ADD_ITEM_MASK(@"Zoom", performZoom:, @"z", NSEventModifierFlagCommand | NSEventModifierFlagOption);
  ADD_ITEM(@"Minimize", performMiniaturize:, @"m");
  ADD_ITEM(@"Immersive", toggleTitleBar, @"i");
  ADD_ITEM(@"Join all spaces", togglePin, @"j");
  ADD_ITEM(@"Bring All to Front", arrangeInFront:, @"");

  [app setMainMenu:menubar];
  [app setDelegate:self];
  return self;
}

- (void) run{
  [app run];
}

- (NSWindow*) getActiveWindow{
  NSWindow* currentWindow = [app keyWindow];
  if(!currentWindow && app.windows.count > 0) currentWindow = [app.windows objectAtIndex:0];
  return currentWindow;
}

- (void) newWindow{
  [[[Window alloc] init] makeKeyAndOrderFront:nil];
}

- (void) hideAll{
  [app hide:self];
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification{
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];
  [app activateIgnoringOtherApps:YES];
  [self newWindow];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
  NSLog(@"wc: %lu", (unsigned long)[app windows].count);
  return false;
}

@end

int main(int argc, const char * argv[]) {
  [[[MyApplicationDelegate alloc] initWithApp:[NSApplication sharedApplication]] run];
  return 0;
}
