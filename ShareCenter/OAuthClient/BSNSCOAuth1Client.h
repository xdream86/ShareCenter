//
//  BSNSCOAuth1.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "BSNSCDeclarations.h"

@interface BSNSCOAuth1Client : NSObject

- (instancetype)initWithConsumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                  callBackURLString:(NSString *)callBackURLString
              requestTokenURLString:(NSString *)requestTokenURLString
             userAuthorizeURLString:(NSString *)userAuthorizeURLString
               accessTokenURLString:(NSString *)accessTokenURLString
                          forSharer:(Class)sharerClass;

- (void)authorizationWithWebView:(UIWebView *)webView
                   completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;

- (NSURLRequest *)requestWithPath:(NSString *)path
                           params:(NSDictionary *)params
                       HTTPMethod:(NSString *)HTTPMethod;

- (BOOL)isAuthorizated;

- (void)logout;

@end


@interface BSNSCQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;
- (NSString *)URLEncodedStringValue;
@end