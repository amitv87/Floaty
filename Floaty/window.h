//
//  Window.h
//  mwv
//
//  Created by Amit Verma on 5/11/20.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Button;

@protocol PanelDelegate <NSObject>
- (void)reload;
- (void)hardReload;
- (void)openMenu;
- (void)togglePin;
- (void)toggleTitleBar;
@end

@protocol ButtonDelegate <NSObject>
- (void) onClick:(Button*)button;
@end

@interface Window : NSPanel<NSWindowDelegate, WKScriptMessageHandler, WKNavigationDelegate, NSMenuDelegate, PanelDelegate, ButtonDelegate>
- (id)init;
@end

NS_ASSUME_NONNULL_END
