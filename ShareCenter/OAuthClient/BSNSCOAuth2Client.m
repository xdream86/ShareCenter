//
//  BSNSCOAuth2.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "BSNSCOAuth2Client.h"
#import "BSNSCDeclarations.h"
#import "NSString+BSNSCExtension.h"
#import "NSDictionary+BSNSCExtension.h"
#import "BSNSCSinaWeiBo.h"
#import "BSNSCDelicious.h"
#import "BSNSCKeychain.h"

@interface BSNSCOAuth2Client() <UIWebViewDelegate>
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSString *callbackURLString;
@property (nonatomic, copy) NSString *requestTokenURLString;
@property (nonatomic, copy) NSString *accessTokenURLString;
@property (nonatomic, copy) Class sharerClass;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (copy) void (^webWiewDelegateHandler)(NSDictionary *oauthParams);
@end

@implementation BSNSCOAuth2Client

- (instancetype)initWithClientId:(NSString *)clientId
                    clientSecret:(NSString *)clientSecret
               callBackURLString:(NSString *)callBackURLString
           requestTokenURLString:(NSString *)requestTokenURLString
            accessTokenURLString:(NSString *)accessTokenURLString
                       forSharer:(Class)sharerClass {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSParameterAssert(clientId);
    NSParameterAssert(clientSecret);
    NSParameterAssert(callBackURLString);
    NSParameterAssert(requestTokenURLString);
    NSParameterAssert(accessTokenURLString);
    NSParameterAssert(sharerClass);
    
    _clientId = clientId;
    _clientSecret = clientSecret;
    _callbackURLString = callBackURLString;
    _requestTokenURLString = requestTokenURLString;
    _accessTokenURLString = accessTokenURLString;
    _sharerClass = sharerClass;
    
    return self;
}

- (BOOL)isAuthorizated {
    return [self accessToken].length > 0;
}

- (NSURLRequest *)requestWithPath:(NSString *)path
                           params:(NSDictionary *)params
                       HTTPMethod:(NSString *)HTTPMethod {
    if (!self.isAuthorizated) {
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    if (![NSStringFromClass(self.sharerClass) isEqualToString:NSStringFromClass([BSNSCSinaWeiBo class])]) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", [self accessToken]] forHTTPHeaderField:@"Authorization"];
    } else {
        [request setValue:[NSString stringWithFormat:@"OAuth2 %@", [self accessToken]] forHTTPHeaderField:@"Authorization"];
    }
    
    request.HTTPMethod = HTTPMethod;
    
    if ([HTTPMethod isEqualToString:@"POST"] && params != nil) {
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSData *postData = [params.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:postData];
        NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    }
    
    return [request copy];
}

- (NSURLRequest *)requestWithPath:(NSString *)path
                             data:(NSData *)data
                       HTTPMethod:(NSString *)HTTPMethod {
    if (!self.isAuthorizated) {
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setValue:[NSString stringWithFormat:@"Bearer %@", [self accessToken]] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = HTTPMethod;
    if (data) {
        [request setValue:@"application/form-data" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:data];
        NSString *postLength = [NSString stringWithFormat:@"%d", (int)[data length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    }
    
    return [request copy];
}

- (void)authorizationWithWebView:(UIWebView *)webView completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    self.webView = webView;
    self.webView.delegate = self;
    
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicator.center = self.webView.center;
    [self.webView addSubview:self.loadingIndicator];
    
    [self obtainAuthCodeWithCompleteBlock:^(NSString *authCode, NSError *error) {
        if (authCode.length) {
            [self.loadingIndicator startAnimating];
            [self obtainAccessTokenWithAuthCode:authCode completeBlock:^(NSString *accessToken, NSError *error) {
                [self.loadingIndicator stopAnimating];
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
}

- (void)logout {
    [self.webView stringByEvaluatingJavaScriptFromString:@"localStorage.clear();"];
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self eraseAccessToken];
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
            NSString *queryString = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@"?"].location + 1];
            NSDictionary *parameters = queryString.parametersFromQueryString;
            _webWiewDelegateHandler(parameters);
            return NO;
        }
    }
    return YES;
}

# pragma mark - Helper Method
- (void)obtainAuthCodeWithCompleteBlock:(void(^)(NSString *authCode, NSError *error))completeBlock {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestTokenURLString]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setValue:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)] forHTTPHeaderField:@"User-Agent"];
    
    _webWiewDelegateHandler = ^(NSDictionary *oauthParams) {
        NSString *authCode = oauthParams[@"code"];
        if (authCode.length) {
            BLOCK_SAFE_RUN(completeBlock, authCode, nil);
        } else {
            NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRequestTokenNilMsg];
            BLOCK_SAFE_RUN(completeBlock, nil, error);
        }
    };
    
    [self.webView loadRequest:request];
}

- (void)obtainAccessTokenWithAuthCode:(NSString *)authorizationCode completeBlock:(void(^)(NSString *accessToken, NSError *error))completeBlock {
    NSURL *url = [NSURL URLWithString:self.accessTokenURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSString *grant_type = @"authorization_code";
    if ([NSStringFromClass(self.sharerClass) isEqualToString:NSStringFromClass([BSNSCDelicious class])]) {
        grant_type = @"code";
    }
    
    NSDictionary *postParameters = @{@"client_id" : self.clientId,
                                     @"client_secret" : self.clientSecret,
                                     @"redirect_uri" : self.callbackURLString,
                                     @"code" : authorizationCode,
                                     @"grant_type" : grant_type};
    NSData *postData = [postParameters.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, nil, error);
            return;
        }
        
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode == 200) {
            if (data.length > 0) {
                NSError *parseError = nil;
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                if (!parseError && [responseDictionary isKindOfClass:[NSDictionary class]]) {
                    NSString *accessToken = responseDictionary[@"access_token"];
                    if (accessToken.length > 0) {
                        BLOCK_SAFE_RUN(completeBlock, accessToken, nil);
                    } else {
                        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCAccessTokenNilMsg];
                        BLOCK_SAFE_RUN(completeBlock, nil, error);
                    }
                } else {
                    NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCRemoteDataFormatInvalidMsg];
                    BLOCK_SAFE_RUN(completeBlock, nil, error);
                }
                
            } else {
                error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCAccessTokenNilMsg];
                BLOCK_SAFE_RUN(completeBlock, nil, error);
            }
            
            return;
        }
        
        if (data.length > 0) {
            NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:message];
        } else {
            NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
            error = [BSNSCError errorWithCode:BSNSCShareError message:message];
        }
        BLOCK_SAFE_RUN(completeBlock, nil, error);
    }];
    
    [postDataTask resume];
}

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
