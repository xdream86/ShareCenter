//
//  BSNSCTwitter.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "BSNSCTwitter.h"

@interface BSNSCTwitter()
@property (nonatomic, strong) BSNSCOAuth1Client *OAuthClient;
@end

@implementation BSNSCTwitter

- (instancetype)init {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth1Client alloc] initWithConsumerKey:BSNSCCONFIG(twitterConsumerKey)
                                                   consumerSecret:BSNSCCONFIG(twitterConsumerSecret)
                                                callBackURLString:BSNSCCONFIG(twitterCallbackURLString)
                                            requestTokenURLString:self.requestTokenURLString
                                           userAuthorizeURLString:self.userAuthorizeURLString
                                             accessTokenURLString:self.accessTokenURLString
                                                       forSharer:self.class];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeTwitter;
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
        NSArray *imagesData = [shareModel.files valueForKey:@"rawData"];
        [self uploadMedia:imagesData completeBlock:^(NSDictionary *response, NSError *error) {
            NSNumber *attachmentID = response[@"media_id"];
            if (attachmentID) {
                [self shareWithText:shareModel.text attachmentID:attachmentID completeBlock:^(BOOL success, NSError *error) {
                    if (error.code == BSNSCAccessTokenExpireError) {
                        [self logout];
                    }
                    BLOCK_SAFE_RUN(completeBlock, success, error);
                }];
            } else {
                error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCMediaAttachmentIDNilMsg];
                BLOCK_SAFE_RUN(completeBlock, NO, error);
            }
        }];
    } else {
        [self shareWithText:shareModel.text attachmentID:nil completeBlock:^(BOOL success, NSError *error) {
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

- (void)shareWithText:(NSString *)text attachmentID:(NSNumber *)attachmentID completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!text.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareTextNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSMutableDictionary *queryParameters = [@{@"status" : text} mutableCopy];
    if (attachmentID) {
        [queryParameters setObject:attachmentID forKey:@"media_ids"];
    }
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

- (void)uploadMedia:(NSArray *)images completeBlock:(void(^)(NSDictionary *response, NSError *error)) completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, nil, error);
        return;
    }
    
    if (![images count]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareImagesAttachmentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, nil, error);
        return;
    }
    
    NSMutableURLRequest *request = [[_OAuthClient requestWithPath:[self uploadMediaURLString] params:nil HTTPMethod:@"POST"] mutableCopy];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    NSData *data = [self createBodyWithBoundary:boundary images:images];
    
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, nil, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 202 || statusCode == 201) {
                if (data.length) {
                    NSError *parseError = nil;
                    NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                    if (!parseError && [responseDic isKindOfClass:[NSDictionary class]]) {
                        BLOCK_SAFE_RUN(completeBlock, responseDic, nil);
                    } else {
                        error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRemoteDataFormatInvalidMsg];
                        BLOCK_SAFE_RUN(completeBlock, nil, error);
                    }
                } else {
                    error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCRemoteDataFormatInvalidMsg];
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
    
    [task resume];
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                            images:(NSArray *)images {
    NSMutableData *body = [NSMutableData data];
    
    [images enumerateObjectsUsingBlock:^(NSData *oneImageData, NSUInteger idx, BOOL *stop) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"image%d.png\"\r\n", (int)idx] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:oneImageData];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        /*! Twitter只支持4张图片*/
        if (idx + 1 == 4) {
            *stop = YES;
        }
    }];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [body copy];
}

- (NSString *)requestTokenURLString {
    return @"https://api.twitter.com/oauth/request_token";
}

- (NSString *)userAuthorizeURLString {
    return @"https://api.twitter.com/oauth/authorize";
}

- (NSString *)accessTokenURLString {
    return @"https://api.twitter.com/oauth/access_token";
}

- (NSString *)shareTextURLString {
    return @"https://api.twitter.com/1.1/statuses/update.json";
}

- (NSString *)uploadMediaURLString {
    return @"https://upload.twitter.com/1.1/media/upload.json";
}

@end
