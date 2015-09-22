//
//  BSNSCOAuth2VariantClient.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/19.
//
//

#import "BSNSCDeclarations.h"

/**
 * OAuth2.0变体
 * @discussion 既保证了安全，也减少了认证的复杂性
 * @see http://getpocket.com/developer/docs/authentication
 */
@interface BSNSCOAuth2VariantClient : NSObject

- (instancetype)initWithConsumerKey:(NSString *)consumerKey
                  callBackURLString:(NSString *)callBackURLString
              requestTokenURLString:(NSString *)requestTokenURLString
            authorizeTokenURLString:(NSString *)authorizeTokenURLString
               accessTokenURLString:(NSString *)accessTokenURLString
                          forSharer:(Class)sharerClass;

- (void)authorizationWithWebView:(UIWebView *)webView
                   completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;

- (NSURLRequest *)requestWithPath:(NSString *)path param:(NSDictionary *)param;

- (BOOL)isAuthorizated;

- (void)logout;

@end
