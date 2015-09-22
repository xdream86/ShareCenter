//
//  BSNSCEvernote.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/6/3.
//
//

#import <ENSDK/ENSDK.h>
#import "BSNSCEvernote.h"
#import "UIViewController+BSNSCExtension.h"

@interface BSNSCEvernote () <UIWebViewDelegate>
@property (nonatomic, strong) UIWebView * webView;
@property (copy) void (^shareCompleteHandler)(BOOL success, NSError*error);
@end

@implementation BSNSCEvernote

- (instancetype)init {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [ENSession setSharedSessionConsumerKey:BSNSCCONFIG(evernoteConsumerKey)
                            consumerSecret:BSNSCCONFIG(evernoteConsumerSecret)
                              optionalHost:nil];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeEvernote;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodSDK;
}

- (BOOL)isAuthorizated {
    return [[ENSession sharedSession] isAuthenticated];
}

- (void)authorizeWithCompleteBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    UIViewController *presentedViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [[ENSession sharedSession] authenticateWithViewController:presentedViewController.explorePresentedViewController
                                           preferRegistration:NO
                                                   completion:^(NSError *authenticateError) {
                                                       BOOL success = !authenticateError;
                                                       NSError *error = authenticateError.code != ENErrorCodeCancelled ? authenticateError : nil;
                                                       BLOCK_SAFE_RUN(completeBlock, success, error);
                                                   }];
}

- (BOOL)handLoginCallback:(NSURL *)callBackURL {
    return [[ENSession sharedSession] handleOpenURL:callBackURL];
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!shareModel.webPageLink.length && !shareModel.text.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareContentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    _shareCompleteHandler = ^(BOOL success, NSError *error) {
        BLOCK_SAFE_RUN(completeBlock, !error, error);
    };
    
    if (shareModel.webPageLink.length) {
        NSURL *urlToClip = [NSURL URLWithString:shareModel.webPageLink];
        self.webView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.webView.delegate = self;
        [self.webView loadRequest:[NSURLRequest requestWithURL:urlToClip]];
    } else {
        ENNote * note = [[ENNote alloc] init];
        ENNoteContent *content = [ENNoteContent noteContentWithSanitizedHTML:shareModel.text];
        note.content = content;
        [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
            if (noteRef) {
                BLOCK_SAFE_RUN(_shareCompleteHandler, YES, nil);
            } else {
                NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareFailureMsg];
                BLOCK_SAFE_RUN(_shareCompleteHandler, NO, error);
            }
        }];
    }
}

- (void)logout {
    [[ENSession sharedSession] unauthenticate];
}

- (void)clipWebPage {
    UIWebView * webView = self.webView;
    self.webView.delegate = nil;
    [self.webView stopLoading];
    self.webView = nil;
    
    [ENNote populateNoteFromWebView:webView completion:^(ENNote * note) {
        if (!note) {
            NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareFailureMsg];
            BLOCK_SAFE_RUN(_shareCompleteHandler, NO, error);
            return;
        }
        
        [[ENSession sharedSession] uploadNote:note notebook:nil completion:^(ENNoteRef *noteRef, NSError *uploadNoteError) {
            if (noteRef) {
                BLOCK_SAFE_RUN(_shareCompleteHandler, YES, nil);
            } else {
                NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareFailureMsg];
                BLOCK_SAFE_RUN(_shareCompleteHandler, NO, error);
            }
        }];
    }];
}

#pragma mark - UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebPage) object:nil];
    self.webView = nil;
    BLOCK_SAFE_RUN(_shareCompleteHandler, NO, error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clipWebPage) object:nil];
    [self performSelector:@selector(clipWebPage) withObject:nil afterDelay:3.0];
}


@end
