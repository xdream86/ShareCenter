//
//  BSNSCGooglePlus.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/22.
//
//

#import "BSNSCGooglePlus.h"
#import <GooglePlus/GooglePlus.h>

@interface BSNSCGooglePlus () <GPPSignInDelegate, GPPShareDelegate>
@property (nonatomic, strong) GPPSignIn *OAuthClient;
@property (copy) void (^authorizationCompleteHandler)(BOOL success, NSError*error);
@property (copy) void (^shareCompleteHandler)(BOOL success, NSError*error);
@end

@implementation BSNSCGooglePlus

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [GPPSignIn sharedInstance];
    _OAuthClient.shouldFetchGooglePlusUser = YES;
    _OAuthClient.clientID = BSNSCCONFIG(googlePlusClientId);
    _OAuthClient.scopes = @[@"https://www.googleapis.com/auth/plus.login"];
    _OAuthClient.delegate = self;
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeGooglePlus;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodSDK;
}

- (BOOL)isAuthorizated {
    return [self.OAuthClient authentication] != nil;
}

- (void)authorizeWithCompleteBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    _authorizationCompleteHandler = ^(BOOL success, NSError *error) {
        BLOCK_SAFE_RUN(completeBlock, !error, error);
    };
    
    [self.OAuthClient authenticate];
}

- (BOOL)handLoginCallback:(NSURL *)callBackURL {
    return [GPPURLHandler handleURL:callBackURL sourceApplication:@"com.apple.mobilesafari" annotation:nil];
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!shareModel.webPageLink.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }

    _shareCompleteHandler = ^(BOOL success, NSError *error) {
        BLOCK_SAFE_RUN(completeBlock, success, error);
    };
    
    id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    [GPPShare sharedInstance].delegate = self;
    [shareBuilder setURLToShare:[NSURL URLWithString:@"http://mercury-browser.com/"]];
    [shareBuilder setPrefillText:shareModel.text];
    [shareBuilder open];
}

- (void)logout {
    [self.OAuthClient signOut];
}

#pragma mark - GPPSignInDelegate
- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth error: (NSError *) error {
    BLOCK_SAFE_RUN(_authorizationCompleteHandler, !error, error);
}

#pragma mark - GPPShareDelegate
- (void)finishedSharingWithError:(NSError *)error {
    BLOCK_SAFE_RUN(_shareCompleteHandler, !error, error);
}

@end
