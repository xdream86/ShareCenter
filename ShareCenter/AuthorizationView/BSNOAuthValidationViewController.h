//
//  BSNAuthenticationViewController.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/8.
//
//

#import "BSNSCDeclarations.h"
#import "BSNSCShareCenter.h"

@interface BSNOAuthValidationViewController : UIViewController
@property (strong, nonatomic, readonly) UIWebView *webView;
@property (nonatomic, copy) void (^cancelAuthorizationHandler)(void);
@end
