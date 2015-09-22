//
//  BSNSCTumblr.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/26.
//
//

#import "BSNSCTumblr.h"

@interface BSNSCTumblr()
@property (nonatomic, strong) BSNSCOAuth1Client *OAuthClient;
@end

@implementation BSNSCTumblr
- (instancetype)init {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth1Client alloc] initWithConsumerKey:BSNSCCONFIG(tumblrConsumerKey)
                                                   consumerSecret:BSNSCCONFIG(tumblrConsumerSecret)
                                                callBackURLString:BSNSCCONFIG(tumblrCallbackURLString)
                                            requestTokenURLString:self.requestTokenURLString
                                           userAuthorizeURLString:self.userAuthorizeURLString
                                             accessTokenURLString:self.accessTokenURLString
                                                       forSharer:self.class];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeTumblr;
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

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock  {
    [self obtainBlogHostNameWithCompleteBlock:^(NSString *blogHostName, NSError *error) {
        if (!error) {
            if ([shareModel.files count] > 0) {
                NSArray *imagesURL = [shareModel.files valueForKey:@"link"];
                [self sharePhotos:imagesURL
                          caption:shareModel.text
                             tags:shareModel.tags
                   toBlogHostName:blogHostName
                    completeBlock:^(BOOL success, NSError *error) {
                        if (error.code == BSNSCAccessTokenExpireError) {
                            [self logout];
                        }
                        BLOCK_SAFE_RUN(completeBlock, success, error);
                    }];
            } else {
                [self shareWithTitle:shareModel.text
                    webPageURLString:shareModel.webPageLink
                                tags:shareModel.tags
                      toBlogHostName:blogHostName
                       completeBlock:^(BOOL success, NSError *error) {
                           if (error.code == BSNSCAccessTokenExpireError) {
                               [self logout];
                           }
                           BLOCK_SAFE_RUN(completeBlock, success, error);
                       }];
            }
        } else {
            if (error.code == BSNSCAccessTokenExpireError) {
                [self logout];
            }
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        }
    }];
}

- (void)logout {
    [self.OAuthClient logout];
}

- (void)obtainBlogHostNameWithCompleteBlock:(void(^)(NSString *blogHostName, NSError *error))completeBlock {
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self userInfoURLString] params:nil HTTPMethod:@"GET"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *getTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, nil, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
                if (data.length > 0) {
                    NSError *parseError = nil;
                    NSDictionary *responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    if (!parseError && [responseArray isKindOfClass:[NSDictionary class]]) {
                        NSString *blogHostName = [responseArray valueForKeyPath:@"response.user.name"];
                        if (blogHostName.length > 0) {
                            BLOCK_SAFE_RUN(completeBlock, blogHostName, nil);
                        } else {
                            NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCBlogNameNilMsg];
                            BLOCK_SAFE_RUN(completeBlock, nil, error);
                        }
                    } else {
                        error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCBlogNameNilMsg];
                        BLOCK_SAFE_RUN(completeBlock, nil, error);
                    }
                    
                    return;
                }
                
                if (statusCode == 401) {
                    error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
                    BLOCK_SAFE_RUN(completeBlock, nil, error);
                    return;
                }
                
                if (data.length > 0) {
                    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    error = [BSNSCError errorWithCode:BSNSCShareError message:message];
                } else {
                    NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                    error = [BSNSCError errorWithCode:BSNSCShareError message:message];
                }
                BLOCK_SAFE_RUN(completeBlock, nil, error);
            }
        }
    }];
    
    [getTask resume];
}


- (void)shareWithTitle:(NSString *)title
      webPageURLString:(NSString *)webPageURLString
                  tags:(NSString *)tags
        toBlogHostName:(NSString *)blogHostName
         completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!webPageURLString.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *queryParameters = @{@"type" : @"link", @"title" : title, @"url" : webPageURLString, @"tags" : tags};
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLStringWithHostName:blogHostName] params:queryParameters HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
                BLOCK_SAFE_RUN(completeBlock, YES, nil);
            } else if (statusCode == 401) {
                error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
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

- (void)sharePhotos:(NSArray *)imagesURL
            caption:(NSString *)caption
               tags:(NSString *)tags
     toBlogHostName:(NSString *)blogHostName
      completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (![imagesURL count]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareContentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    
    NSString *source = [imagesURL firstObject];
    NSDictionary *queryParameters = @{@"type" : @"photo", @"caption" : caption, @"source" : source, @"tags" : tags};
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLStringWithHostName:blogHostName] params:queryParameters HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
                BLOCK_SAFE_RUN(completeBlock, YES, nil);
            } else if (statusCode == 401) {
                error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
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
    return @"https://www.tumblr.com/oauth/request_token";
}

- (NSString *)userAuthorizeURLString {
    return @"https://www.tumblr.com/oauth/authorize";
}

- (NSString *)accessTokenURLString {
    return @"https://www.tumblr.com/oauth/access_token";
}

- (NSString *)shareTextURLStringWithHostName:(NSString *)hostName {
    NSString *link = [NSString stringWithFormat:@"https://api.tumblr.com/v2/blog/%@.tumblr.com/post", hostName];
    return link;
}

- (NSString *)userInfoURLString {
    return @"https://api.tumblr.com/v2/user/info";
}

@end
