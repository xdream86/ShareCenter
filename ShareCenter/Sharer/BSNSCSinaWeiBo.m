//
//  BSNSCSinaWeiBo.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/6/1.
//
//

#import "BSNSCSinaWeiBo.h"

@interface BSNSCSinaWeiBo()
@property (nonatomic, strong) BSNSCOAuth2Client *OAuthClient;
@end

@implementation BSNSCSinaWeiBo

- (instancetype)init {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth2Client alloc] initWithClientId:BSNSCCONFIG(weiboClientId)
                                                  clientSecret:BSNSCCONFIG(weiboClientSecret)
                                             callBackURLString:BSNSCCONFIG(weiboCallBackURLString)
                                         requestTokenURLString:self.requestTokenURLString
                                          accessTokenURLString:self.accessTokenURLString
                                                    forSharer:self.class];
    
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeWeiBo;
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
    if ([shareModel.files count] > 0) {
        NSData *imageData = [shareModel fileDataAtIndex:0];
        [self shareWithImageData:imageData status:shareModel.text captcompleteBlock:^(BOOL success, NSError *error) {
            if (error.code == BSNSCAccessTokenExpireError) {
                [self logout];
            }
            BLOCK_SAFE_RUN(completeBlock, success, error);
        }];
    } else {
        [self shareWithStatus:shareModel.text  completeBlock:^(BOOL success, NSError *error) {
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

- (void)shareWithStatus:(NSString *)status completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!status.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *queryParameters = @{@"status" : status};
    NSURLRequest *request = [self.OAuthClient requestWithPath:[self shareTextURLString] params:queryParameters HTTPMethod:@"POST"];
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

- (void)shareWithImageData:(NSData *)imageData status:(NSString *)status captcompleteBlock:(void (^)(BOOL, NSError *))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!status.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareTextNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!imageData.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareImagesAttachmentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    
    NSMutableURLRequest *request = [[_OAuthClient requestWithPath:[self sharePictureURLString] params:nil HTTPMethod:@"POST"] mutableCopy];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    NSData *data = [self createBodyWithBoundary:boundary image:imageData status:status];
    
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
                if (data.length) {
                    NSError *parseError = nil;
                    NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    if (!parseError && [responseDic isKindOfClass:[NSDictionary class]]) {
                        BLOCK_SAFE_RUN(completeBlock, YES, nil);
                    } else {
                        error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRemoteDataFormatInvalidMsg];
                        BLOCK_SAFE_RUN(completeBlock, NO, error);
                    }
                } else {
                    error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRemoteDataFormatInvalidMsg];
                    BLOCK_SAFE_RUN(completeBlock, NO, error);
                }
                return;
            }
            if (statusCode == 401) {
                error = [BSNSCError errorWithCode:BSNSCAccessTokenExpireError message:BSNSCAccessTokenExpireMsg];
                BLOCK_SAFE_RUN(completeBlock, NO, error);
                return;
            }
            
            if (data.length > 0) {
                NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                error = [BSNSCError errorWithCode:BSNSCShareError message:message];
            } else {
                NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                error = [BSNSCError errorWithCode:BSNSCShareError message:message];
            }
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        }
    }];
    
    [task resume];
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                             image:(NSData *)imageData
                            status:(NSString *)status {
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[status dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"pic\"; filename=\"image.png\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [body copy];
}

- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"https://api.weibo.com/oauth2/authorize?client_id=%@&response_type=code&redirect_uri=%@", BSNSCCONFIG(weiboClientId), BSNSCCONFIG(weiboCallBackURLString)];
}

- (NSString *)accessTokenURLString {
    return @"https://api.weibo.com/oauth2/access_token";
}

- (NSString *)shareTextURLString {
    return @"https://api.weibo.com/2/statuses/update.json";
}

- (NSString *)sharePictureURLString {
    return @"https://upload.api.weibo.com/2/statuses/upload.json";
}

@end
