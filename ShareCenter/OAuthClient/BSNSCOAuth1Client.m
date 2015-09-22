//
//  BSNSCOAuth1.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "BSNSCOAuth1Client.h"
#import "BSNSCError.h"
#include "BSNSCHMAC.h"
#import "BSNSCDeclarations.h"
#import "NSString+BSNSCExtension.h"
#import "NSDictionary+BSNSCExtension.h"
#import "BSNSCKeychain.h"

extern NSArray * queryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * queryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * queryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (BSNSCQueryStringPair *pair in queryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * queryStringPairsFromDictionary(NSDictionary *dictionary) {
    return queryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * queryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if([value isKindOfClass:[NSDictionary class]]) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        [[[value allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] enumerateObjectsUsingBlock:^(id nestedKey, NSUInteger idx, BOOL *stop) {
            id nestedValue = [value objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:queryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }];
    } else if([value isKindOfClass:[NSArray class]]) {
        [value enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
            [mutableQueryStringComponents addObjectsFromArray:queryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }];
    } else {
        [mutableQueryStringComponents addObject:[[BSNSCQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}


@implementation BSNSCQueryStringPair
@synthesize field = _field;
@synthesize value = _value;

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return [self.field description].utf8AndURLEncode;
    } else {
        return [NSString stringWithFormat:@"%@=%@", [self.field description].utf8AndURLEncode, [self.value description].utf8AndURLEncode];
    }
}
@end

@interface BSNSCOAuth1Client() <UIWebViewDelegate>
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;
@property (nonatomic, copy) NSString *callbackURLString;
@property (nonatomic, copy) NSString *requestTokenURLString;
@property (nonatomic, copy) NSString *userAuthorizeURLString;
@property (nonatomic, copy) NSString *accessTokenURLString;
@property (nonatomic, copy) NSString *authTokenSecret;
@property (nonatomic, copy) Class sharerClass;
@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (copy) void (^webWiewDelegateHandler)(NSDictionary *oauthParams);
@end

@implementation BSNSCOAuth1Client

- (instancetype)initWithConsumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                  callBackURLString:(NSString *)callBackURLString
              requestTokenURLString:(NSString *)requestTokenURLString
             userAuthorizeURLString:(NSString *)userAuthorizeURLString
               accessTokenURLString:(NSString *)accessTokenURLString
                          forSharer:(Class)sharerClass {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSParameterAssert(consumerKey);
    NSParameterAssert(consumerSecret);
    NSParameterAssert(callBackURLString);
    NSParameterAssert(requestTokenURLString);
    NSParameterAssert(userAuthorizeURLString);
    NSParameterAssert(accessTokenURLString);
    NSParameterAssert(sharerClass);
    
    _consumerKey = consumerKey;
    _consumerSecret = consumerSecret;
    _callbackURLString = callBackURLString;
    _requestTokenURLString = requestTokenURLString;
    _userAuthorizeURLString = userAuthorizeURLString;
    _accessTokenURLString = accessTokenURLString;
    _sharerClass = sharerClass;
    
    return self;
}

- (BOOL)isAuthorizated {
    return [self accessToken].length > 0 && [self accessTokenSecret].length > 0;
}

- (void)authorizationWithWebView:(UIWebView *)webView completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    self.webView = webView;
    self.webView.delegate = self;
    
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicator.center = self.webView.center;
    [self.webView addSubview:self.loadingIndicator];
    [self.loadingIndicator startAnimating];
    
    [self obtainRequestTokenWithCompleteBlock:^(NSError *error, NSDictionary *responseParams) {
        NSString *auth_code_secret = responseParams[@"oauth_token_secret"];
        NSString *auth_code = responseParams[@"oauth_token"];
        self.authTokenSecret = auth_code_secret; // 备份一次，可能在获取accssToken的时候secret就不传回来了，后面只能用这个阶段回传的secret
        if (auth_code.length && auth_code_secret.length) {
            [self obtainVerifierWithAuthCode:auth_code completeCode:^(NSError *error, NSDictionary *responseParams) {
                if (!error) {
                    [self obtainAccessTokenWithTokenSecret:auth_code_secret
                                                oauthToken:responseParams[@"oauth_token"]
                                             oauthVerifier:responseParams[@"oauth_verifier"]
                                                completion:^(NSError *error, NSDictionary *responseParams) {
                                                    NSString *authToken = responseParams[@"oauth_token"];
                                                    NSString *authTokenSecret = responseParams[@"oauth_token_secret"];
                                                    if (authTokenSecret.length) {
                                                        self.authTokenSecret = authTokenSecret;
                                                    }
                                                    if (authToken.length && self.authTokenSecret.length) {
                                                        [self saveAccessToken:authToken tokenSecret:self.authTokenSecret];
                                                        BLOCK_SAFE_RUN(completeBlock, YES, nil);
                                                    } else {
                                                        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCAccessTokenOrSecretNilMsg];
                                                        BLOCK_SAFE_RUN(completeBlock, NO, error);
                                                    }
                                                }];
                } else {
                    NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCAuthCodeOrSecretNilMsg];
                    BLOCK_SAFE_RUN(completeBlock, NO, error);
                }
            }];
        } else {
            NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCRequestTokenNilMsg];
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        }
    }];
}

- (void)logout {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self eraseAccessTokenAndSecret];
}

- (NSURLRequest *)requestWithPath:(NSString *)path
                           params:(NSDictionary *)params
                       HTTPMethod:(NSString *)HTTPMethod {
    if (!self.isAuthorizated || !HTTPMethod) {
        return nil;
    }
    
    NSMutableDictionary *allParameters = [self standardOauthParameters];
    allParameters[@"oauth_token"] = [self accessToken];
    [allParameters addEntriesFromDictionary:params];
    NSString *parametersString = queryStringFromParameters(allParameters);
    
    NSURL *url = [NSURL URLWithString:path];
    NSString *pathURLString = [NSString stringWithFormat:@"%@://%@%@", [[url scheme] lowercaseString], [[url host] lowercaseString], [url path]];;
    
    NSString *baseString = [HTTPMethod stringByAppendingFormat:@"&%@&%@", pathURLString.utf8AndURLEncode, parametersString.utf8AndURLEncode];
    NSString *secretString = [[self consumerSecret].utf8AndURLEncode stringByAppendingFormat:@"&%@", [self accessTokenSecret].utf8AndURLEncode];
    NSString *oauth_signature = [self.class signClearText:baseString withSecret:secretString];
    allParameters[@"oauth_signature"] = oauth_signature;
    
    NSMutableArray *parameterPairs = [NSMutableArray array];
    [allParameters removeObjectsForKeys:params.allKeys];
    for (NSString *name in allParameters) {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [allParameters[name] utf8AndURLEncode]];
        [parameterPairs addObject:aPair];
    }
    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = HTTPMethod;
    
    if ([HTTPMethod isEqualToString:@"POST"] && params != nil) {
        NSData *postData = [params.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
        NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
    }
    
    return request;
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
            parameters = [self removeAppendedSubstringOnVerifierIfPresent:parameters];
            
            _webWiewDelegateHandler(parameters);
            return NO;
        }
    }
    return YES;
}

# pragma mark - Helper Method
- (void)obtainRequestTokenWithCompleteBlock:(void(^)(NSError *error, NSDictionary *responseParams))completeBlock {
    NSMutableDictionary *allParameters = [self standardOauthParameters];
    NSURL *url = [NSURL URLWithString:self.requestTokenURLString];
    NSString *request_url = [NSString stringWithFormat:@"%@://%@%@", [[url scheme] lowercaseString], [[url host] lowercaseString], [url path]];;
    NSString *parametersString = queryStringFromParameters(allParameters);
    NSString *baseString = [@"GET" stringByAppendingFormat:@"&%@&%@", request_url.utf8AndURLEncode, parametersString.utf8AndURLEncode];
    NSString *secretString = [self.consumerSecret.utf8AndURLEncode stringByAppendingString:@"&"];
    NSString *oauth_signature = [self.class signClearText:baseString withSecret:secretString];
    [allParameters setValue:oauth_signature forKey:@"oauth_signature"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request_url]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    request.HTTPMethod = @"GET";
    
    NSMutableArray *parameterPairs = [NSMutableArray array];
    for (NSString *name in allParameters) {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [allParameters[name] utf8AndURLEncode]];
        [parameterPairs addObject:aPair];
    }
    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *reponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        BLOCK_SAFE_RUN(completeBlock, nil, reponseString.parametersFromQueryString);
    }];
    [task resume];
}

- (void)obtainVerifierWithAuthCode:(NSString *)authCode completeCode:(void (^)(NSError *error, NSDictionary *responseParams))completion {
    NSString *authenticate_url = [self userAuthorizeURLString];
    authenticate_url = [authenticate_url stringByAppendingFormat:@"?oauth_token=%@", authCode];
    authenticate_url = [authenticate_url stringByAppendingFormat:@"&oauth_callback=%@", [self callbackURLString].utf8AndURLEncode];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:authenticate_url]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setValue:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)] forHTTPHeaderField:@"User-Agent"];
    
    _webWiewDelegateHandler = ^(NSDictionary *oauthParams) {
        NSString *verifier = oauthParams[@"oauth_verifier"];
        if (verifier.length) {
            BLOCK_SAFE_RUN(completion, nil, oauthParams);
        } else {
            NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCOauthVerifierNilMsg];
            BLOCK_SAFE_RUN(completion, error, nil);
        }
    };
    
    [self.webView loadRequest:request];
}

- (void)obtainAccessTokenWithTokenSecret:(NSString *)oauth_token_secret
                              oauthToken:(NSString *)oauth_token
                           oauthVerifier:(NSString *)oauth_verifier
                              completion:(void (^)(NSError *error, NSDictionary *responseParams))completion {
    
    NSMutableDictionary *allParameters = [self standardOauthParameters];
    [allParameters setValue:oauth_verifier forKey:@"oauth_verifier"];
    [allParameters setValue:oauth_token    forKey:@"oauth_token"];
    NSString *parametersString = queryStringFromParameters(allParameters);
    
    NSURL *url = [NSURL URLWithString:self.accessTokenURLString];
    NSString *path = [NSString stringWithFormat:@"%@://%@%@", [[url scheme] lowercaseString], [[url host] lowercaseString], [url path]];
    NSString *baseString = [@"POST" stringByAppendingFormat:@"&%@&%@", path.utf8AndURLEncode, parametersString.utf8AndURLEncode];
    NSString *secretString = [[self consumerSecret].utf8AndURLEncode stringByAppendingFormat:@"&%@", oauth_token_secret.utf8AndURLEncode];
    NSString *oauth_signature = [self.class signClearText:baseString withSecret:secretString];
    [allParameters setValue:oauth_signature forKey:@"oauth_signature"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self accessTokenURLString]]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    request.HTTPMethod = @"POST";
    
    NSMutableArray *parameterPairs = [NSMutableArray array];
    for (NSString *name in allParameters) {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [allParameters[name] utf8AndURLEncode]];
        [parameterPairs addObject:aPair];
    }
    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        completion(nil, responseString.parametersFromQueryString);
    }];
    [task resume];
}

#define FacebookAndTumblrAppendedString @"#_=_"

- (NSDictionary *)removeAppendedSubstringOnVerifierIfPresent:(NSDictionary *)parameters {
    NSString *oauthVerifier = parameters[@"oauth_verifier"];
    if ([oauthVerifier hasSuffix:FacebookAndTumblrAppendedString]
        && [oauthVerifier length] > FacebookAndTumblrAppendedString.length) {
        NSMutableDictionary *mutableParameters = parameters.mutableCopy;
        mutableParameters[@"oauth_verifier"] = [oauthVerifier substringToIndex:oauthVerifier.length - FacebookAndTumblrAppendedString.length];
        parameters = mutableParameters;
    }
    return parameters;
}

/*! 加密 */
+ (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret {
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
    BSNSCHmac_sha1((unsigned char *)[clearTextData bytes], [clearTextData length], (unsigned char *)[secretData bytes], [secretData length], result);
    NSData *resultData = [NSData dataWithBytes:result length:20];
    return [resultData base64EncodedStringWithOptions:0];
}

- (NSMutableDictionary *)standardOauthParameters {
    NSString *oauth_timestamp = [NSString stringWithFormat:@"%lu", (unsigned long)[NSDate.date timeIntervalSince1970]];
    NSString *oauth_nonce = [NSString getNonce];
    NSString *oauth_consumer_key = self.consumerKey;
    NSString *oauth_callback = self.callbackURLString;
    NSString *oauth_signature_method = @"HMAC-SHA1";
    NSString *oauth_version = @"1.0";
    
    NSMutableDictionary *standardParameters = [NSMutableDictionary dictionary];
    [standardParameters setValue:oauth_consumer_key     forKey:@"oauth_consumer_key"];
    [standardParameters setValue:oauth_nonce            forKey:@"oauth_nonce"];
    [standardParameters setValue:oauth_signature_method forKey:@"oauth_signature_method"];
    [standardParameters setValue:oauth_timestamp        forKey:@"oauth_timestamp"];
    [standardParameters setValue:oauth_version          forKey:@"oauth_version"];
    [standardParameters setValue:oauth_callback         forKey:@"oauth_callback"];
    
    return standardParameters;
}

- (NSString *)accessToken {
    NSString *accessToken = [BSNSCKeychain defaultKeychain][self.accessTokenKey];
    
    return accessToken;
}

- (NSString *)accessTokenSecret {
    NSString *accessTokenSecret = [BSNSCKeychain defaultKeychain][self.accessTokenSecretKey];
    
    return accessTokenSecret;
}

- (void)saveAccessToken:(NSString *)accessToken tokenSecret:(NSString *)secret{
    if (accessToken.length && secret.length) {
        [BSNSCKeychain defaultKeychain][self.accessTokenKey] = accessToken;
        [BSNSCKeychain defaultKeychain][self.accessTokenSecretKey] = secret;
    }
}

- (void)eraseAccessTokenAndSecret {
    [[BSNSCKeychain defaultKeychain] removeObjectForKey:self.accessTokenKey];
    [[BSNSCKeychain defaultKeychain] removeObjectForKey:self.accessTokenSecretKey];
}

- (NSString *)accessTokenKey {
    return [NSString stringWithFormat:@"%@-%@-accessToken", [NSString uuid], NSStringFromClass(_sharerClass)];
}

- (NSString *)accessTokenSecretKey {
    return [NSString stringWithFormat:@"%@-%@-accessTokenSecret", [NSString uuid], NSStringFromClass(_sharerClass)];
}

@end
