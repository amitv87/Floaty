//
//  Window.h
//  mwv
//
//  Created by Amit Verma on 5/11/20.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Button;

@protocol WindowDelegate <NSObject>
- (void)togglePin;
- (void)softReload;
- (void)hardReload;
- (void)openLocation;
- (void)toggleTitleBar;
- (void)toggleFillVideo;
- (void)toggleDevConsole;
@end

@protocol ButtonDelegate <NSObject>
- (void) onClick:(Button*)button;
@end

@interface Window : NSPanel<NSWindowDelegate, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate, WindowDelegate, ButtonDelegate>
- (id)init;
@end

NS_ASSUME_NONNULL_END
