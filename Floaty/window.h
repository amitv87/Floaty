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
- (void)reload;
- (void)togglePin;
- (void)hardReload;
- (void)openLocation;
- (void)toggleTitleBar;
@end

@protocol ButtonDelegate <NSObject>
- (void) onClick:(Button*)button;
@end

@interface Window : NSPanel<NSWindowDelegate, WKScriptMessageHandler, WKNavigationDelegate, WindowDelegate, ButtonDelegate>
- (id)init;
@end

NS_ASSUME_NONNULL_END
