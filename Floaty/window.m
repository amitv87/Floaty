//
//  Window.m
//  mwv
//
//  Created by Amit Verma on 5/11/20.
//

#import "img.h"
#import "window.h"

#define NSColorFromRGB(rgbValue) [NSColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
  green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define GET_IMG(x) [[NSImage alloc] initWithData:[NSData dataWithBytes:img_##x##_png length:img_##x##_png_len]]

static const int kMinSize = 160;
static const int kStartSize = 400;

static const char* kHtml =
"<!DOCTYPE html><html><head><title>Floaty</title><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" /></head><body oncontextmenu=\"event.preventDefault()\" style=\"margin:0 auto;overflow: hidden;color: white;display: flex; align-items: center; justify-content: center; flex-direction: column;width: 100vw;height: 100vh;-webkit-user-select: none; user-select: none;\"><h1 style=\"text-shadow: 0 0 20px black\">Floaty</h1></body></html>"
;

static CGRect kStartRect = {
  .origin = {
    .x = 0,
    .y = 0,
  },
  .size = {
    .width = kStartSize,
    .height = kStartSize,
  },
};

static NSWindowStyleMask kWindowMask = NSWindowStyleMaskBorderless
  | NSWindowStyleMaskTitled
  | NSWindowStyleMaskClosable
  | NSWindowStyleMaskResizable
  | NSWindowStyleMaskMiniaturizable
  | NSWindowStyleMaskTexturedBackground
  | NSWindowStyleMaskNonactivatingPanel
  | NSWindowStyleMaskUnifiedTitleAndToolbar
;

bool isInside(int rad, CGPoint cirlce, CGPoint point){
  if ((point.x - cirlce.x) * (point.x - cirlce.x) + (point.y - cirlce.y) * (point.y - cirlce.y) <= rad * rad) return true;
  else return false;
}

@interface Button : NSButton
@property (nullable, nonatomic) id<ButtonDelegate> delegate;
- (id) initWithRadius:(int)radius andImage:(nullable NSImage*) img andImageScale:(float)scale;
- (void)setImg:(NSImage*) img;
- (void)setColor:(NSColor*) color;
@end

@implementation NSColor (LightAndDark)
- (NSColor *)lighterColor{
  CGFloat h, s, b, a;
  [self getHue:&h saturation:&s brightness:&b alpha:&a];
  return [NSColor colorWithHue:h saturation:s brightness:MIN(b * 1.4, 1.0) alpha:a];
}
- (NSColor *)darkerColor{
  CGFloat h, s, b, a;
  [self getHue:&h saturation:&s brightness:&b alpha:&a];
  return [NSColor colorWithHue:h saturation:s brightness:b * 0.75 alpha:a];
}
@end

@implementation Button{
  int radius;
  NSColor* bgColor;
  float imageScale;
}

- (id) initWithRadius:(int)rad andImage:(nullable NSImage*) img andImageScale:(float)scale{
  int sideLen = rad * 2;

  self = [super initWithFrame:NSMakeRect(0, 0, sideLen, sideLen)];

  radius = rad;
  imageScale = scale;
  bgColor = NSColor.clearColor;

  self.bordered = NO;
  self.target = self;
  self.action = @selector(onClick:);
  self.buttonType = NSButtonTypeMomentaryChange;

  self.wantsLayer = true;
  self.layer.cornerRadius = radius;
  self.layer.masksToBounds = true;

  if(img) [self setImg:img];
  return self;
}

- (void)setImg:(NSImage*) img{
  int iconLen = radius * imageScale;
  [img setSize:NSMakeSize(iconLen, iconLen)];
  [self setImage:img];
  [self setImagePosition:NSImageOnly];
}

- (void)setColor:(NSColor*) color{
  bgColor = color;
  self.layer.backgroundColor = bgColor.CGColor;
  [self updateLayer];
}

-(void)onClick:(id)sender{
  [self.delegate onClick:self];
}

- (bool)isVaid:(NSEvent *)event{
  NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
  CGPoint circle = NSMakePoint(radius, radius);
  bool isValid = isInside(radius, circle, loc);
  return isValid;
}

- (void)mouseUp:(NSEvent *)event{
  if([self isVaid:event]) [super mouseUp:event];
}

- (void)mouseDown:(NSEvent *)event{
  if([self isVaid:event]) [super mouseDown:event];
}

- (void)drawRect:(NSRect)dirtyRect{
  NSColor* target = self.isHighlighted ? [bgColor lighterColor] : bgColor;
  self.layer.backgroundColor = target.CGColor;
  [super drawRect:dirtyRect];
}
@end

@implementation NSWindow (FullScreen)
- (BOOL)isFullScreen{
  return (([self styleMask] & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen);
}
@end

void setWindowSize(NSWindow* window, NSRect windowRect, NSRect screenRect, NSSize size, bool animate){
  float screenWidth = screenRect.origin.x + screenRect.size.width;
  float screenHeight = screenRect.origin.y + screenRect.size.height;

  if(windowRect.origin.x + windowRect.size.width == screenWidth)
    windowRect.origin.x += windowRect.size.width - size.width;
  else{
    float clippingWidth = screenWidth - (windowRect.origin.x + size.width);
    if(clippingWidth < 0) windowRect.origin.x += clippingWidth;
  }

  if(windowRect.origin.y + windowRect.size.height == screenHeight)
    windowRect.origin.y += windowRect.size.height - size.height;
  else{
    float clippingHeight = screenHeight - (windowRect.origin.y + size.height);
    if(clippingHeight < 0) windowRect.origin.y += clippingHeight;
  }

  if(windowRect.origin.x < screenRect.origin.x) windowRect.origin.x = screenRect.origin.x;
  if(windowRect.origin.y < screenRect.origin.y) windowRect.origin.y = screenRect.origin.y;

  windowRect.size = size;

  [window setFrame:windowRect display:YES animate:animate];
}

@interface RootView : NSVisualEffectView
@end

@implementation RootView
- (void)magnifyWithEvent:(NSEvent *)event{
  if([self.window isFullScreen]) return;
  NSSize ar = self.window.contentAspectRatio;
  NSRect windowRect = [self.window frame];
  NSRect screenRect = [[self.window screen] visibleFrame];

  float width, height, scale = [event magnification] + 1;

  if(ar.width * ar.height == 0){
    width = windowRect.size.width * scale;
    height = windowRect.size.height * scale;
  }
  else{
    float titleBarHeight = windowRect.size.height - [[self.window contentView] frame].size.height;
    width = windowRect.size.width * scale;
    height = (width * ar.height / ar.width) + titleBarHeight;
  }

  if(screenRect.size.width < width || screenRect.size.height < height || (width < kMinSize && height < kMinSize)) return;

  setWindowSize(self.window, windowRect, screenRect, NSMakeSize(width, height), false);
}

-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
  return YES;
}
@end


@interface WV : WKWebView
@end

@implementation WV
-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
  return YES;
}
@end

void set(WKWebViewConfiguration* conf, id value, NSString* key){
  @try{
    [conf.preferences setValue:value forKey:key];
  }
  @catch (NSException *exception) {
    NSLog(@"error setting %@ => %@", key, exception.reason);
  }
}

@implementation Window{
  WV* wv;
  RootView* rootView;
  bool isClosing;
  float contentAR;
  NSTextField* urlInput;
  Button* ddButt, *pinbutt, *reloadButt;
  NSTitlebarAccessoryViewController* tbavc;
}

- (id)init{

  self = [super initWithContentRect:kStartRect styleMask:kWindowMask backing:NSBackingStoreBuffered defer:YES];

  NSRect screenRect = [[self screen] visibleFrame];
  NSPoint point = NSMakePoint(
    screenRect.origin.x + screenRect.size.width - kStartRect.size.width,
    screenRect.origin.y
//    + screenRect.size.height - kStartRect.size.height
  );
  [self setFrameOrigin:point];

  contentAR = 0;
  isClosing = false;

  WKWebViewConfiguration* conf = [[WKWebViewConfiguration alloc] init];

  conf.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];

  set(conf, @YES, @"mediaStreamEnabled");
  set(conf, @YES, @"mediaDevicesEnabled");
  set(conf, @YES, @"screenCaptureEnabled");
  set(conf, @YES, @"peerConnectionEnabled");
//  set(conf, @YES, @"mockCaptureDevicesEnabled");
//  set(conf, @NO, @"mockCaptureDevicesPromptEnabled");
//  set(conf, @NO, @"mediaCaptureRequiresSecureConnection");

  set(conf, @YES, @"fullScreenEnabled");
  set(conf, @YES, @"allowsPictureInPictureMediaPlayback");

  set(conf, @YES, @"developerExtrasEnabled");
  set(conf, @NO, @"offlineApplicationCacheIsEnabled");

  [conf.userContentController addScriptMessageHandler:self name:@"external"];

  self.opaque = YES;
  self.movable = YES;
  self.delegate = self;
  self.releasedWhenClosed = YES;
  self.level = NSFloatingWindowLevel;
  self.movableByWindowBackground = YES;
  self.titlebarAppearsTransparent = true;
  self.minSize = NSMakeSize(kMinSize, kMinSize);
  self.maxSize = [[self screen] visibleFrame].size;
  self.preservesContentDuringLiveResize = false;
  self.collectionBehavior = NSWindowCollectionBehaviorManaged | NSWindowCollectionBehaviorParticipatesInCycle | NSWindowCollectionBehaviorFullScreenPrimary;

  float butradius = 6.5;
  float butspacing = butradius * 3;

  NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 3 * butspacing, 0)];

  ddButt = [[Button alloc] initWithRadius:butradius andImage:GET_IMG(dd) andImageScale:1.8];
  [ddButt setColor:NSColorFromRGB(0x37c8ae)];
  [ddButt setFrameOrigin:NSMakePoint(0 * butspacing, 5)];
  [ddButt setDelegate:self];
  [view addSubview:ddButt];

  reloadButt = [[Button alloc] initWithRadius:butradius andImage:GET_IMG(reload) andImageScale:1.5];
  [reloadButt setColor:NSColorFromRGB(0x0D92B9)];
  [reloadButt setFrameOrigin:NSMakePoint(1 * butspacing, 5)];
  [reloadButt setDelegate:self];
  [view addSubview:reloadButt];

  pinbutt = [[Button alloc] initWithRadius:butradius andImage:nil andImageScale:1.8];
  [pinbutt setColor:NSColorFromRGB(0xC66F90)];
  [pinbutt setFrameOrigin:NSMakePoint(2 * butspacing, 5)];
  [pinbutt setDelegate:self];
  [self setupPushPin:false];
  [view addSubview:pinbutt];

  tbavc = [[NSTitlebarAccessoryViewController alloc] init];
  tbavc.view = view;
  tbavc.layoutAttribute = NSLayoutAttributeTrailing;
  [self addTitlebarAccessoryViewController:tbavc];

  urlInput = [[NSTextField alloc] initWithFrame:NSMakeRect(0, kStartRect.size.height - 20, kStartRect.size.width, 20)];
  urlInput.placeholderString = @"type or paste a URL";
  urlInput.hidden = true;
  urlInput.bezeled = false;
  urlInput.bordered = true;
  urlInput.editable = true;
  urlInput.selectable = true;
  urlInput.target = self;
  urlInput.action = @selector(onurlInput:);
  urlInput.focusRingType = NSFocusRingTypeNone;
  urlInput.usesSingleLineMode = YES;
  urlInput.maximumNumberOfLines = 1;
  urlInput.cell.wraps = false;
  urlInput.cell.scrollable = true;
  urlInput.textColor = NSColor.whiteColor;

  urlInput.drawsBackground = YES;
  urlInput.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.5];

  urlInput.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin;

  wv = [[WV alloc] initWithFrame:kStartRect configuration:conf];
  wv.navigationDelegate = self;
  wv.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable | NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;

  @try{[wv setValue: @NO forKey: @"drawsBackground"];}
  @catch(NSException* e){}
//  wv.customUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Safari/537.36";

  [self loadStartPage];
//  [wv loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.0.177:8080/#192.168.0.137"]]];

  rootView = [[RootView alloc] initWithFrame:kStartRect];
  rootView.autoresizesSubviews = true;
  rootView.state = NSVisualEffectStateActive;
  rootView.material = NSVisualEffectMaterialAppearanceBased;
  rootView.blendingMode = NSVisualEffectBlendingModeBehindWindow;

  [rootView addSubview:wv];
  [rootView addSubview:urlInput];

  [self setContentView:rootView];

  urlInput.stringValue = wv.URL.absoluteString;

  return self;
}

- (void)loadStartPage{
  [wv loadHTMLString:[NSString stringWithUTF8String:kHtml] baseURL:nil];
}

- (void)onurlInput:(id)sender{
  if(!urlInput.stringValue.length) return;
  NSURLComponents *components = [NSURLComponents componentsWithString:urlInput.stringValue];

  if(!components.scheme){
    NSString* url = [urlInput.stringValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    components = [NSURLComponents componentsWithString:[@"http://" stringByAppendingFormat:@"%@", url]];
  }

  bool isSchemeValid = [components.scheme caseInsensitiveCompare:@"http"] == NSOrderedSame || [components.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame;

  if(!isSchemeValid){
    [self loadStartPage];
    return;
  }

  [wv loadRequest:[NSURLRequest requestWithURL:components.URL]];
}

- (void)resetSate{
  [self setTitle:wv.title];
  urlInput.stringValue = wv.URL.absoluteString;
  [wv evaluateJavaScript:@"document.body.style.backgroundColor = 'rgba(0,0,0,0)';" completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation{
  [self resetSate];
  contentAR = 0;
  [self setResizeIncrements:NSMakeSize(1, 1)];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation{
  [self resetSate];
  urlInput.hidden = true;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
  NSLog(@"didFailNavigation");
}

- (void)resetWindow{
  if([self isFullScreen]){
    pinbutt.enabled = false;
    [self setResizeIncrements:NSMakeSize(1, 1)];
    [self setMaxSize:[[self screen] frame].size];
  }
  else{
    pinbutt.enabled = true;
    if(isClosing) return;
    if(contentAR >= 0.1) [self resizeWindow];
    [self setMaxSize:[[self screen] visibleFrame].size];
  }
}

- (void)windowDidChangeScreen:(NSNotification *)notification{
  [self resetWindow];
}

- (void)windowDidChangeScreenProfile:(NSNotification *)notification{
  [self resetWindow];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification{
  [self setMaxSize:[[self screen] frame].size];
}

-(void)resizeWindow{
  NSRect windowRect = [self frame];
  NSRect screenRect = [[self screen] visibleFrame];

  float titleBarHeight = windowRect.size.height - [[self contentView] frame].size.height;
  float maxDim = fmax(windowRect.size.width, windowRect.size.height - titleBarHeight);
  NSSize size = NSMakeSize(fmin(maxDim * contentAR, maxDim), fmin(maxDim / contentAR, maxDim));
  [self setContentAspectRatio:size];

  size.height += titleBarHeight;
  setWindowSize(self, windowRect, screenRect, size, true);
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
  NSDictionary* dict = message.body;
  if(!dict) return;
  if([dict objectForKey:@"width"] && [dict objectForKey:@"height"]){
    contentAR = [dict[@"width"] floatValue] / [dict[@"height"] floatValue];
    if(![self isFullScreen]) [self resizeWindow];
  }
}

- (void)openLocation{
  urlInput.hidden = !urlInput.hidden;
  if(!urlInput.hidden){
    if(!urlInput.stringValue.length) urlInput.stringValue = wv.URL.absoluteString;
    [urlInput becomeFirstResponder];
  }
}

- (void)onClick:(Button*)button{
  if(button == pinbutt) [self togglePin];
  else if(button == ddButt) [self openLocation];
  else if(button == reloadButt) [self reload];
}

- (void)setupPushPin:(bool)active{
  [pinbutt setImg:active ? GET_IMG(pinned) : GET_IMG(pin)];
}

-(bool)checkPage{
  if([wv.URL.absoluteString caseInsensitiveCompare:@"about:blank"] != NSOrderedSame) return true;
  [self loadStartPage];
  return false;
}

- (void)reload{
  if([self checkPage]) [wv reload];
}

- (void)hardReload{
  if([self checkPage]) [wv reloadFromOrigin];
}

- (void)toggleTitleBar{
  bool isHidden = (self.styleMask & NSWindowStyleMaskFullSizeContentView) == NSWindowStyleMaskFullSizeContentView;
  if(isHidden) self.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
  else self.styleMask |= NSWindowStyleMaskFullSizeContentView;
  [[[self standardWindowButton:NSWindowCloseButton] superview] setHidden:!isHidden];
}

- (void)togglePin{
  if(!pinbutt.isEnabled) return;
  bool isPinned = (self.collectionBehavior & NSWindowCollectionBehaviorCanJoinAllSpaces) == NSWindowCollectionBehaviorCanJoinAllSpaces;
  if(isPinned){
    self.collectionBehavior &= ~NSWindowCollectionBehaviorCanJoinAllSpaces;
    self.collectionBehavior &= ~NSWindowCollectionBehaviorFullScreenAuxiliary;
    self.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
  }
  else{
    self.collectionBehavior &= ~NSWindowCollectionBehaviorFullScreenPrimary;
    self.collectionBehavior |= NSWindowCollectionBehaviorFullScreenAuxiliary;
    self.collectionBehavior |= NSWindowCollectionBehaviorCanJoinAllSpaces;
  }
  [self setupPushPin:!isPinned];
}

- (void)windowWillClose:(NSNotification *)notification{
  isClosing = true;
}

- (void)windowDidBecomeKey:(NSNotification *)notification{
  [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)cancel:(id)arg1{}

- (void)close{
  [self setContentView:nil];

  ddButt.delegate = nil;
  pinbutt.delegate = nil;
  reloadButt.delegate = nil;

  [wv removeFromSuperview];
  [ddButt removeFromSuperview];
  [pinbutt removeFromSuperview];
  [reloadButt removeFromSuperview];
  [tbavc removeFromParentViewController];

  wv = nil;
  tbavc = nil;
  ddButt = nil;
  pinbutt = nil;
  rootView = nil;
  reloadButt = nil;
  [super close];
}

@end
