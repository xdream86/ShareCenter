//
//  BSNSCOAuth2.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "BSNSCDeclarations.h"
#import "BSNSCError.h"

@interface BSNSCOAuth2Client : NSObject
- (instancetype)initWithClientId:(NSString *)clientId
                    clientSecret:(NSString *)clientSecret
               callBackURLString:(NSString *)callBackURLString
           requestTokenURLString:(NSString *)requestTokenURLString
            accessTokenURLString:(NSString *)accessTokenURLString
                       forSharer:(Class)sharerClass;

- (void)authorizationWithWebView:(UIWebView *)webView
                   completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;

- (NSURLRequest *)requestWithPath:(NSString *)path
                           params:(NSDictionary *)params
                       HTTPMethod:(NSString *)HTTPMethod;

- (NSURLRequest *)requestWithPath:(NSString *)path
                             data:(NSData *)data
                       HTTPMethod:(NSString *)HTTPMethod;

- (BOOL)isAuthorizated;

- (void)logout;
@end
