//
//  BSNSCFacebook.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/16.
//
//

#import "BSNSCFacebook.h"

@interface BSNSCFacebook ()
@property (nonatomic, strong) BSNSCOAuth2Client *OAuthClient;
@end

@implementation BSNSCFacebook

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth2Client alloc] initWithClientId:BSNSCCONFIG(facebookClientId)
                                                  clientSecret:BSNSCCONFIG(facebookClientSecret)
                                             callBackURLString:BSNSCCONFIG(facebookCallBackURLString)
                                         requestTokenURLString:self.requestTokenURLString
                                          accessTokenURLString:self.accessTokenURLString
                                                    forSharer:self.class];
    
    return self;
}


#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeFacebook;
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
    NSString *imageURLString = [shareModel fileURLStringAtIndex:0];
    if (imageURLString.length > 0) {
        [self sharePhotoWithURLString:imageURLString caption:shareModel.text completeBlock:^(BOOL success, NSError *error) {
            if (error.code == BSNSCAccessTokenExpireError) {
                [self logout];
            }
            BLOCK_SAFE_RUN(completeBlock, success, error);
        }];
    } else {
        [self shareWithText:shareModel.text webPageLink:shareModel.webPageLink completeBlock:^(BOOL success, NSError *error) {
            if (error.code == BSNSCAccessTokenExpireError) {
                [self logout];
            }
            BLOCK_SAFE_RUN(completeBlock, success, error);
        }];
    }
}

- (void)logout {
    [self.OAuthClient logout];
}

#pragma mark - Sharer Configure
- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"https://www.facebook.com/dialog/oauth?client_id=%@&redirect_uri=%@&scope=publish_actions&response_type=code", BSNSCCONFIG(facebookClientId), BSNSCCONFIG(facebookCallBackURLString)];
}

- (NSString *)accessTokenURLString {
    return @"https://graph.facebook.com/v2.3/oauth/access_token";
}

- (NSString *)shareTextURLString {
    return @"https://graph.facebook.com/v2.3/me/feed";
}

- (NSString *)sharePhotoURLString {
    return @"https://graph.facebook.com/v2.3/me/photos";
}

# pragma mark - Helper Method
/*! Facebook的graphic API只支持传一张图片 */
- (void)sharePhotoWithURLString:(NSString *)imageURLString caption:(NSString *)caption completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!imageURLString.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareContentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *parameters = @{@"caption": caption ?: @"photo.png", @"url" : imageURLString};
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self sharePhotoURLString] params:parameters HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
            BLOCK_SAFE_RUN(completeBlock, YES, nil);
            return;
        }
        
        if (data.length) {
            NSError *parseError;
            NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
            if (!parseError && [parsedResponse isKindOfClass:[NSDictionary class]]) {
                NSUInteger errorSubCode = [parsedResponse[@"error"][@"error_subcode"] integerValue];
                NSUInteger errorCode = [parsedResponse[@"error"][@"code"] integerValue];
                
                if (errorSubCode == 458 || errorSubCode == 463 || errorSubCode == 467 || errorCode == 2500 || 200 >= errorCode || errorCode <= 299 || errorCode == 102) {
                    error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
                }
            }
        }  else {
            NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
            error = [BSNSCError errorWithCode:BSNSCShareError message:message];
        }
        
        BLOCK_SAFE_RUN(completeBlock, NO, error);
    }];
    
    [postTask resume];
}

- (void)shareWithText:(NSString *)content webPageLink:(NSString *)webPageLink completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!content.length && !webPageLink.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareContentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *parameters = @{@"message": content, @"link" : webPageLink};
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLString] params:parameters HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
            BLOCK_SAFE_RUN(completeBlock, YES, nil);
            return;
        }
        
        if (data.length) {
            NSError *parseError;
            NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
            if (!parseError && [parsedResponse isKindOfClass:[NSDictionary class]]) {
                NSUInteger errorSubCode = [parsedResponse[@"error"][@"error_subcode"] integerValue];
                NSUInteger errorCode = [parsedResponse[@"error"][@"code"] integerValue];
                
                if (errorSubCode == 458 || errorSubCode == 463 || errorSubCode == 467 || errorCode == 2500 || 200 >= errorCode || errorCode <= 299 || errorCode == 102) {
                    error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
                }
            }
        }  else {
            NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
            error = [BSNSCError errorWithCode:BSNSCShareError message:message];
        }
        
        BLOCK_SAFE_RUN(completeBlock, NO, error);
    }];
    
    [postTask resume];
}

@end
