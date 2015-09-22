//
//  BSNSCDelicious.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/13.
//
//

#import "BSNSCDelicious.h"
#import "NSDictionary+BSNSCExtension.h"
#import "BSNSCXMLDictionaryParser.h"
#import "NSString+BSNSCExtension.h"

@interface BSNSCDelicious()
@property (nonatomic, strong) BSNSCOAuth2Client *OAuthClient;
@end

@implementation BSNSCDelicious

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth2Client alloc] initWithClientId:BSNSCCONFIG(deliciousClientId)
                                                  clientSecret:BSNSCCONFIG(deliciousClientSecret)
                                             callBackURLString:BSNSCCONFIG(deliciousCallBackURLString)
                                         requestTokenURLString:self.requestTokenURLString
                                          accessTokenURLString:self.accessTokenURLString
                                                    forSharer:self.class];
    
    [[BSNSCXMLDictionaryParser sharedInstance] setAlwaysUseArrays:YES];
    [[BSNSCXMLDictionaryParser sharedInstance] setAttributesMode:XMLDictionaryAttributesModeUnprefixed];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeDelicious;
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
    [self shareWithText:shareModel.text link:shareModel.webPageLink tags:shareModel.tags completeBlock:^(BOOL success, NSError *error) {
        if (error.code == BSNSCAccessTokenExpireError) {
            [self logout];
        }
        BLOCK_SAFE_RUN(completeBlock, success, error);
    }];
}

- (void)shareWithText:(NSString *)sharedText link:(NSString *)sharedLink tags:(NSString *)tags completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!sharedLink.length || !sharedText.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *parameters = @{@"description": [[sharedText utf8AndURLEncode] utf8AndURLEncode], // delicious API问题，对于中文需要双urlencode
                                 @"url" : [sharedLink utf8AndURLEncode],
                                 @"replace" : @YES,
                                 @"tags" : tags};
    NSString *path = [[self shareTextURLString] stringByAppendingFormat:@"?%@", parameters.queryParameter];
    NSURLRequest *request = [self.OAuthClient requestWithPath:path params:nil HTTPMethod:@"GET"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *getTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
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
    
    [getTask resume];
}

- (void)logout {
    [self.OAuthClient logout];
}

#pragma mark Sharer Configure
- (NSString *)shareTextURLString {
    return @"http://api.del.icio.us/v1/posts/add";
}

- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"https://delicious.com/auth/authorize?client_id=%@&redirect_uri=%@&response_type=code", BSNSCCONFIG(deliciousClientId), BSNSCCONFIG(deliciousCallBackURLString)];
}

- (NSString *)accessTokenURLString {
    return @"https://avosapi.delicious.com/api/v1/oauth/token";
}

@end
