//
//  BSNSCPocket.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/19.
//
//

#import "BSNSCPocket.h"
#import "BSNSCOAuth2VariantClient.h"

@interface BSNSCPocket()
@property (nonatomic, strong) BSNSCOAuth2VariantClient *OAuthClient;
@end

@implementation BSNSCPocket

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth2VariantClient alloc] initWithConsumerKey:BSNSCCONFIG(pocketConsumerKey)
                                                       callBackURLString:BSNSCCONFIG(pocketCallbackURLString)
                                                   requestTokenURLString:self.requestTokenURLString
                                                 authorizeTokenURLString:self.authorizeTokenURLString
                                                    accessTokenURLString:self.accessTokenURLString
                                                              forSharer:self.class];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypePocket;
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
    if (shareModel.webPageLink.length == 0) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSString *sharedLink = shareModel.webPageLink;
    if (![sharedLink hasPrefix:@"http://"]) {
        sharedLink = [@"http://" stringByAppendingString:sharedLink];
    }
    
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLString] param:@{@"url" : sharedLink, @"title" : shareModel.text, @"tags" : shareModel.tags}];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
            return;
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
                BLOCK_SAFE_RUN(completeBlock, YES, nil);
            } else if (statusCode == 401) {
                error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
                BLOCK_SAFE_RUN(completeBlock, NO, error);
            } else {
                if (data.length) {
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

- (void)logout {
    [self.OAuthClient logout];
}

#pragma mark Sharer Configure
- (NSString *)requestTokenURLString {
    return @"https://getpocket.com/v3/oauth/request";
}

- (NSString *)authorizeTokenURLString {
    return @"https://getpocket.com/auth/authorize";
}

- (NSString *)accessTokenURLString {
    return @"https://getpocket.com/v3/oauth/authorize";
}

- (NSString *)shareTextURLString {
    return @"https://getpocket.com/v3/add";
}

@end
