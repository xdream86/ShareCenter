//
//  BSNSCBaseShareSharer.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import <UIKit/UIKit.h>
#import "BSNSCDeclarations.h"
#import "BSNSCConfiguration.h"
#import "BSNSCDefaultConfigurator.h"
#import "BSNSCOAuth1Client.h"
#import "BSNSCOAuth2Client.h"
#import "BSNSCOAuth2VariantClient.h"
#import "BSNSCBasicAuthClient.h"
#import "BSNSCShareModel.h"

@interface  BSNSCSharerAbstractClass : NSObject
+ (BSNSCSharerType)sharerType;
+ (BSNSCAuthorizationMethod)authorizationType;
- (BOOL)isAuthorizated;
- (BOOL)handLoginCallback:(NSURL *)callBackURL;
- (void)authorizeWithCompleteBlock:(void (^)(BOOL success, NSError *error))completeBlock;
- (void)authorizeWithWebView:(UIWebView *)webView completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;
- (void)authorizeWithUserName:(NSString *)userName password:(NSString *)password completeBlock:(void (^)(BOOL, NSError *))completeBlock;
- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;
- (void)logout;
@end

@interface BSNSCBaseSharer : BSNSCSharerAbstractClass
+ (BSNSCBaseSharer *)sharedInstance;
+ (NSArray *)initializedInstance;
+ (void)destroyInstance;
@end
