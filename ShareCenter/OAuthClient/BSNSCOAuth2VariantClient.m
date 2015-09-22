//
//  BSNSCOAuth2VariantClient.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/19.
//
//

#import "BSNSCOAuth2VariantClient.h"
#import "BSNSCDeclarations.h"
#import "BSNSCError.h"
#import "NSDictionary+BSNSCExtension.h"
#import "NSString+BSNSCExtension.h"
#import "BSNSCKeychain.h"

@interface BSNSCOAuth2VariantClient () <UIWebViewDelegate>
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *callbackURLString;
@property (nonatomic, copy) NSString *requestTokenURLString;
@property (nonatomic, copy) NSString *authorizeTokenURLString;
@property (nonatomic, copy) NSString *accessTokenURLString;
@property (nonatomic, copy) Class sharerClass;
@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (copy) void (^webWiewDelegateHandler)(BOOL success, NSError *error);
@end

@implementation BSNSCOAuth2VariantClient

- (instancetype)initWithConsumerKey:(NSString *)consumerKey
                  callBackURLString:(NSString *)callBackURLString
              requestTokenURLString:(NSString *)requestTokenURLString
            authorizeTokenURLString:(NSString *)authorizeTokenURLString
               accessTokenURLString:(NSString *)accessTokenURLString
                          forSharer:(Class)sharerClass {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSParameterAssert(consumerKey);
    NSParameterAssert(callBackURLString);
    NSParameterAssert(requestTokenURLString);
    NSParameterAssert(authorizeTokenURLString);
    NSParameterAssert(accessTokenURLString);
    NSParameterAssert(sharerClass);
    
    _consumerKey = consumerKey;
    _callbackURLString = callBackURLString;
    _requestTokenURLString = requestTokenURLString;
    _authorizeTokenURLString = authorizeTokenURLString;
    _accessTokenURLString = accessTokenURLString;
    _sharerClass = sharerClass;
    
    return self;
}

- (void)authorizationWithWebView:(UIWebView *)webView
                   completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    self.webView = webView;
    self.webView.delegate = self;
    
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicator.center = self.webView.center;
    [self.webView addSubview:self.loadingIndicator];
    [self.loadingIndicator startAnimating];
    
    [self obtainRequestTokenWithCompleteBlock:^(NSError *error, NSString *requestToken) {
        if (requestToken.length > 0) {
            [self redirectToAuthorizationPageWithRequestToken:requestToken CompleteBlock:^(BOOL success, NSError *error) {
                if (success) {
                    [self accessTokenConvertFromRequestToken:requestToken completion:^(NSError *error, NSString *accessToken) {
                        if (accessToken.length) {
                            [self saveAccessToken:accessToken];
                            BLOCK_SAFE_RUN(completeBlock, YES, nil);
                        } else {
                            BLOCK_SAFE_RUN(completeBlock, NO, error);
                        }
                    }];
                } else {
                    BLOCK_SAFE_RUN(completeBlock, NO, error);
                }
            }];
        } else {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        }
    }];
}

- (BOOL)isAuthorizated {
    return [self accessToken].length > 0;
}

- (void)logout {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self eraseAccessToken];
}


- (NSURLRequest *)requestWithPath:(NSString *)path param:(NSDictionary *)param {
    NSMutableDictionary *allParams = [@{@"consumer_key" : self.consumerKey, @"access_token" : [self accessToken]} mutableCopy];
    [allParams addEntriesFromDictionary:param];
    NSData *postData = [allParams.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    return request;
}

#pragma mark - Helper Method
- (void)obtainRequestTokenWithCompleteBlock:(void(^)(NSError *error, NSString *requestToken))completeBlock  {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestTokenURLString]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *postParameters = @{@"consumer_key" : self.consumerKey, @"redirect_uri" : self.callbackURLString};
    NSData *postData = [postParameters.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, error, nil);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                if (data.length > 0) {
                    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSDictionary *dictionary = responseString.parametersFromQueryString;
                    NSString *code = dictionary[@"code"];
                    if (code.length > 0) {
                        BLOCK_SAFE_RUN(completeBlock, nil, code);
                    } else {
                        error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCRequestTokenNilMsg];
                        BLOCK_SAFE_RUN(completeBlock, error, nil);
                    }
                } else {
                    error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCRequestTokenNilMsg];
                    BLOCK_SAFE_RUN(completeBlock, error, nil);
                }
                
                return;
            }
            
            if (data.length > 0) {
                NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                error = [BSNSCError errorWithCode:BSNSCShareError message:message];
            } else {
                NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                error = [BSNSCError errorWithCode:BSNSCShareError message:message];
            }
            
            BLOCK_SAFE_RUN(completeBlock, error, nil);
        }
    }];
    
    [postDataTask resume];
}

- (void)redirectToAuthorizationPageWithRequestToken:(NSString *)requestToken CompleteBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    NSString *urlString = [self.authorizeTokenURLString stringByAppendingFormat:@"?request_token=%@&redirect_uri=%@", requestToken, [self callbackURLString]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setValue:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)] forHTTPHeaderField:@"User-Agent"];
    _webWiewDelegateHandler = ^(BOOL success, NSError *error) {
        completeBlock(success, error);
    };
    [_webView loadRequest:request];
}


- (void)accessTokenConvertFromRequestToken:(NSString *)requestToken completion:(void (^)(NSError *error, NSString *accessToken))completeBlock {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:self.accessTokenURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *postParamters = @{@"consumer_key" : self.consumerKey, @"code" : requestToken};
    NSData *postData = [postParamters.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, error, nil);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                if (data.length > 0) {
                    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSDictionary *dictionary = responseString.parametersFromQueryString;
                    NSString *code = dictionary[@"access_token"];
                    if (code.length > 0) {
                        BLOCK_SAFE_RUN(completeBlock, nil, code);
                    } else {
                        error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCAccessTokenNilMsg];
                        BLOCK_SAFE_RUN(completeBlock, error, nil);
                    }
                } else {
                    error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCAccessTokenNilMsg];
                    BLOCK_SAFE_RUN(completeBlock, error, nil);
                }
            } else {
                if (data.length > 0) {
                    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    error = [BSNSCError errorWithCode:BSNSCShareError message:message];
                } else {
                    NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                    error = [BSNSCError errorWithCode:BSNSCShareError message:message];
                }
                BLOCK_SAFE_RUN(completeBlock, error, nil);
            }
        }
    }];
    
    [postDataTask resume];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingIndicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.loadingIndicator startAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (_webWiewDelegateHandler) {
        NSString *urlWithoutQueryString = [request.URL.absoluteString componentsSeparatedByString:@"?"][0];
        if ([urlWithoutQueryString rangeOfString:[self callbackURLString]].location != NSNotFound) {
            _webWiewDelegateHandler(YES, nil);
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Helper Method
- (NSString *)accessToken {
    NSString *accessToken = [BSNSCKeychain defaultKeychain][self.accessTokenKey];
    return accessToken;
}

- (void)saveAccessToken:(NSString *)accessToken {
    if (accessToken.length) {
        [BSNSCKeychain defaultKeychain][self.accessTokenKey] = accessToken;
    }
}

- (void)eraseAccessToken {
    [[BSNSCKeychain defaultKeychain] removeObjectForKey:self.accessTokenKey];
}

- (NSString *)accessTokenKey {
    return [NSString stringWithFormat:@"%@-%@-accessToken", [NSString uuid], NSStringFromClass(_sharerClass)];
}

@end
