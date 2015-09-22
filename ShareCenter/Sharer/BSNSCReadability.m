//
//  BSNSCReadability.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/13.
//
//

#import "BSNSCReadability.h"

@interface BSNSCReadability()
@property (nonatomic, strong) BSNSCOAuth1Client *OAuthClient;
@end

@implementation BSNSCReadability

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth1Client alloc] initWithConsumerKey:BSNSCCONFIG(readabilityConsumerKey)
                                                   consumerSecret:BSNSCCONFIG(readabilityConsumerSecret)
                                                callBackURLString:BSNSCCONFIG(readabilityCallbackURLString)
                                            requestTokenURLString:self.requestTokenURLString
                                           userAuthorizeURLString:self.userAuthorizeURLString
                                             accessTokenURLString:self.accessTokenURLString
                                                       forSharer:self.class];
    
    return self;
}

# pragma mark - BSNSCShareProtocol
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeReadability;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodOAuth;
}

- (BOOL)isAuthorizated {
    return [self.OAuthClient isAuthorizated];
}

- (void)authorizeWithWebView:(UIWebView *)webView completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    [self.OAuthClient authorizationWithWebView:webView completeBlock:completeBlock];
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    [self shareWithText:shareModel.text webPageLink:shareModel.webPageLink completeBlock:^(BOOL success, NSError *error) {
        if (error.code == BSNSCAccessTokenExpireError) {
            [self logout];
        }
        BLOCK_SAFE_RUN(completeBlock, success, error);
    }];
}

- (void)logout {
    [self.OAuthClient logout];
}

- (void)shareWithText:(NSString *)text webPageLink:(NSString *)webPageLink completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!webPageLink.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *queryParameters = @{@"url" : webPageLink};
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLString]
                                                       params:queryParameters
                                                   HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) { // 202 表示已经接受，正在处理，也认为成功了
                BLOCK_SAFE_RUN(completeBlock, YES, nil);
            } else if (statusCode == 401) {
                error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
                BLOCK_SAFE_RUN(completeBlock, NO, error);
            } else if (statusCode == 409) {
                error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRepeatShareMsg];
                BLOCK_SAFE_RUN(completeBlock, NO, error);
            } else {
                if (data.length > 0) {
                    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    error = [BSNSCError errorWithCode:BSNSCShareError message:message];
                } else {
                    NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                    error = [BSNSCError errorWithCode:BSNSCShareError message:message];
                }
                
                BLOCK_SAFE_RUN(completeBlock, NO, error);
            }
        }
    }];
    
    [postDataTask resume];
}

- (NSString *)requestTokenURLString {
    return @"https://www.readability.com/api/rest/v1/oauth/request_token";
}

- (NSString *)userAuthorizeURLString {
    return @"https://www.readability.com/api/rest/v1/oauth/authorize";
}

- (NSString *)accessTokenURLString {
    return @"https://www.readability.com/api/rest/v1/oauth/access_token";
}

- (NSString *)shareTextURLString {
    return @"https://www.readability.com/api/rest/v1/bookmarks";
}

@end
