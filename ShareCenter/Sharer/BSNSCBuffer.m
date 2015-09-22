//
//  BSNSCBuffer.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/13.
//
//

#import "BSNSCBuffer.h"

@interface BSNSCBuffer ()
@property (nonatomic, strong) BSNSCOAuth2Client *OAuthClient;
@end

@implementation BSNSCBuffer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _OAuthClient = [[BSNSCOAuth2Client alloc] initWithClientId:BSNSCCONFIG(bufferClientId)
                                                  clientSecret:BSNSCCONFIG(bufferClientSecret)
                                             callBackURLString:BSNSCCONFIG(bufferCallBackURLString)
                                         requestTokenURLString:self.requestTokenURLString
                                          accessTokenURLString:self.accessTokenURLString
                                                    forSharer:self.class];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeBuffer;
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
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self obtainUserAccountIdWithCompleteBlock:^(NSArray *userIds, NSError *error) {
        if (!error) {
            [weakSelf shareWithText:shareModel.text
                        webPageLink:shareModel.webPageLink
                          imageLink:[shareModel fileURLStringAtIndex:0]
                           toUserId:userIds
                      completeBlock:^(BOOL success, NSError *error) {
                          if (error.code == BSNSCAccessTokenExpireError) {
                              [self logout];
                          }
                          BLOCK_SAFE_RUN(completeBlock, success, error);
                      }];
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

#pragma mark Sharer Configure
- (NSString *)userInfoURLString {
    return @"https://api.bufferapp.com/1/profiles.json";
}

- (NSString *)shareTextURLString {
    return @"https://api.bufferapp.com/1/updates/create.json";
}

- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"https://bufferapp.com/oauth2/authorize?client_id=%@&redirect_uri=%@&response_type=code", BSNSCCONFIG(bufferClientId), BSNSCCONFIG(bufferCallBackURLString)];
}

- (NSString *)accessTokenURLString {
    return @"https://api.bufferapp.com/1/oauth2/token.json";
}

# pragma mark - Helper Method
- (void)obtainUserAccountIdWithCompleteBlock:(void(^)(NSArray *userIds, NSError *error))completeBlock {
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
                    NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    if (!parseError && [responseArray isKindOfClass:[NSArray class]]) {
                        NSMutableArray *userIds = [NSMutableArray new];
                        [responseArray enumerateObjectsUsingBlock:^(NSDictionary *oneUserProfile, NSUInteger idx, BOOL *stop) {
                            if ([oneUserProfile isKindOfClass:[NSDictionary class]]) {
                                NSString *profileId = oneUserProfile[@"_id"];
                                if (profileId.length) {
                                    [userIds addObject:profileId];
                                }
                            }
                        }];
                        BLOCK_SAFE_RUN(completeBlock, [userIds copy], nil);
                    } else {
                        error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRemoteDataFormatInvalidMsg];
                        BLOCK_SAFE_RUN(completeBlock, nil, error);
                    }
                } else {
                    error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCUserIdNilMsg];
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
    }];
    
    [getTask resume];
}

- (void)shareWithText:(NSString *)content
          webPageLink:(NSString *)webPageLink
            imageLink:(NSString *)imageLink
             toUserId:(NSArray *)userIds
        completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (!content.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareTextNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (![userIds count]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareAccountUnkownMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSMutableDictionary *parameters = [@{@"text" : content ?: @"", @"now" : @YES, @"shorten" : @NO} mutableCopy];
    if (webPageLink.length) {
        [parameters setObject:webPageLink forKey:@"media[link]"];
    }
    
    if (imageLink.length) {
        [parameters setObject:imageLink forKey:@"media[photo]"];
        [parameters setObject:imageLink forKey:@"media[thumbnail]"];
    }
    
    [userIds enumerateObjectsUsingBlock:^(NSString *oneUserId, NSUInteger idx, BOOL *stop) {
        if (oneUserId.length) {
            [parameters setObject:oneUserId forKey:[NSString stringWithFormat:@"profile_ids[%d]", (int)idx]];
        }
    }];
    
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLString]
                                                       params:parameters
                                                   HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
    
    [task resume];
}

@end