//
//  BSNSCDropbox.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/25.
//
//

#import "BSNSCDropbox.h"
#import "NSString+BSNSCExtension.h"

@interface BSNSCDropbox()
@property (nonatomic, strong) BSNSCOAuth2Client *OAuthClient;
@end

@implementation BSNSCDropbox

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth2Client alloc] initWithClientId:BSNSCCONFIG(dropboxClientId)
                                                  clientSecret:BSNSCCONFIG(dropboxClientSecret)
                                             callBackURLString:BSNSCCONFIG(dropboxCallBackURLString)
                                         requestTokenURLString:self.requestTokenURLString
                                          accessTokenURLString:self.accessTokenURLString
                                                    forSharer:self.class];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeDropbox;
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
    NSData *fileData = [shareModel fileDataAtIndex:0];
    NSString *fileName = [shareModel fileNameStringAtIndex:0];
    if (!fileData.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareContentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }

    NSURLRequest *request = [_OAuthClient requestWithPath:[self shareTextURLString:fileName] data:fileData HTTPMethod:@"PUT"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
    
    [task resume];
}

- (void)logout {
    [self.OAuthClient logout];
}

#pragma mark Sharer Configure
- (NSString *)shareTextURLString:(NSString *)fileNmae {
    return [NSString stringWithFormat:@"https://api-content.dropbox.com/1/files_put/auto/%@?param=val", fileNmae.utf8AndURLEncode];
}

- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"https://www.dropbox.com/1/oauth2/authorize?client_id=%@&redirect_uri=%@&response_type=code", BSNSCCONFIG(dropboxClientId), BSNSCCONFIG(dropboxCallBackURLString)];
}

- (NSString *)accessTokenURLString {
    return @"https://api.dropbox.com/1/oauth2/token";
}
@end
