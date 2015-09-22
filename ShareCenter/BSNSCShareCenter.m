//
//  BSNShareCenter.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/8.
//
//

#import "BSNSCShareCenter.h"
#import "BSNSCError.h"
#import "BSNSCDeclarations.h"
#import "BSNSCBaseSharer.h"
#import "NSObject+BSNSCExtension.h"
#import "BSNOAuthValidationViewController.h"
#import "BSNSCXAuthValidationViewController.h"
#import "UIViewController+BSNSCExtension.h"

#define rootViewControllerOnWindow [UIApplication sharedApplication].delegate.window.rootViewController

static NSArray *_supportSharer = nil;
static void (^_authorizationCompleteBlock)(BOOL success, NSError *error);

@interface BSNSCShareCenter()
@end

@implementation BSNSCShareCenter

+ (void)initialize {
    if (!_supportSharer) {
        _supportSharer = [BSNSCBaseSharer directSubclasses];
    }
}

+ (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (!shareModel || shareModel.sharerType == BSNSCSharerTypeNone) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareFailureMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    BSNSCBaseSharer *sharer = [self.class createSharerInstanceWithType:shareModel.sharerType];
    if ([sharer isAuthorizated]) {
        [sharer shareWithShareModel:shareModel completeBlock:completeBlock];
    } else {
        [self loginToSharer:shareModel.sharerType completeBlock:^(BOOL success, NSError *error) {
            if (success) {
                [sharer shareWithShareModel:shareModel completeBlock:completeBlock];
            } else {
                BLOCK_SAFE_RUN(completeBlock, success, error);
            }
        }];
    }
}

+ (void)logoutSharer:(BSNSCSharerType)shareType {
    BSNSCBaseSharer *sharer = [self.class createSharerInstanceWithType:shareType];
    [sharer logout];
    [sharer.class destroyInstance];
}

+ (void)logoutAllSharer {
    [_supportSharer enumerateObjectsUsingBlock:^(Class aClass, NSUInteger idx, BOOL *stop) {
        BSNSCSharerType aSharer = (BSNSCSharerType)[aClass performSelector:@selector(sharerType)];
        [self.class logoutSharer:aSharer];
    }];
}

+ (void)loginToSharer:(BSNSCSharerType)sharerType completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    } else {
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    BSNSCBaseSharer *sharer = [self.class createSharerInstanceWithType:sharerType];
    BSNSCAuthorizationMethod authorizationMethod = [sharer.class authorizationType];
    
    if (BSNSCAuthMethodBasic == authorizationMethod) {
        BSNSCXAuthValidationViewController *authorizationVC = [BSNSCXAuthValidationViewController new];
        [navigationController addChildViewController:authorizationVC];
        
        authorizationVC.cancelAuthorizationBlock = ^() {
            BLOCK_SAFE_RUN(completeBlock, NO, nil);
        };
        
        authorizationVC.submitAuthorizationBlock = ^(NSString *userName, NSString *password, AuthorizationResponseBlock authorizationResponseBlock) {
            [sharer authorizeWithUserName:userName
                                 password:password
                            completeBlock:^(BOOL success, NSError *error) {
                                BLOCK_SAFE_RUN(authorizationResponseBlock, success, error);
                                if (success) {
                                    [rootViewControllerOnWindow dismissVCFromVisibleVCAnimated:YES completion:nil];
                                    BLOCK_SAFE_RUN(completeBlock, success, nil);
                                }
                            }];
        };
        
        [rootViewControllerOnWindow presentVCFromVisibleVC:navigationController completion:nil];
    } else if (BSNSCAuthMethodOAuth == authorizationMethod) {
        BSNOAuthValidationViewController *authorizationVC = [BSNOAuthValidationViewController new];
        [navigationController addChildViewController:authorizationVC];
        
        authorizationVC.cancelAuthorizationHandler = ^() {
            BLOCK_SAFE_RUN(completeBlock, NO, nil);
        };
        
        [rootViewControllerOnWindow presentVCFromVisibleVC:navigationController completion:^{
            [sharer authorizeWithWebView:authorizationVC.webView
                           completeBlock:^(BOOL success, NSError *error) {
                               [rootViewControllerOnWindow dismissVCFromVisibleVCAnimated:YES completion:nil];
                               BLOCK_SAFE_RUN(completeBlock, success, error);
                           }];
        }];
    } else if (BSNSCAuthMethodSDK == authorizationMethod){
        [sharer authorizeWithCompleteBlock:^(BOOL success, NSError *error) {
            BLOCK_SAFE_RUN(completeBlock, success, error);
        }];
    }
}

+ (BOOL)handLoginCallback:(NSURL *)callBackURL {
    __block BOOL accepted = NO;
    [BSNSCBaseSharer.initializedInstance enumerateObjectsUsingBlock:^(BSNSCBaseSharer *oneSharer, NSUInteger idx, BOOL *stop) {
        if ([oneSharer handLoginCallback:callBackURL]) {
            accepted = YES;
            *stop = YES;
        }
    }];
    return accepted;
}

+ (BOOL)isAuthorizatedSharer:(BSNSCSharerType)sharerType {
    BSNSCBaseSharer *sharer = [self.class createSharerInstanceWithType:sharerType];
    return sharer.isAuthorizated;
}

+ (BSNSCBaseSharer *)createSharerInstanceWithType:(BSNSCSharerType)sharerType {
    __block BSNSCBaseSharer *sharedInstance;
    [_supportSharer enumerateObjectsUsingBlock:^(Class aClass, NSUInteger idx, BOOL *stop) {
        BSNSCSharerType oneSharer = (BSNSCSharerType)[aClass performSelector:@selector(sharerType)];
        if (oneSharer == sharerType) {
            sharedInstance = [aClass performSelector:@selector(sharedInstance)];
            *stop = YES;
        }
    }];
    
    return sharedInstance;
}

@end
