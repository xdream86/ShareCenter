//
//  BSNSCLinkedIn.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/6/2.
//
//

#import "BSNSCLinkedIn.h"
#import "NSString+BSNSCExtension.h"

@interface BSNSCLinkedIn()
@property (nonatomic, strong) BSNSCOAuth2Client *OAuthClient;
@end

@implementation BSNSCLinkedIn
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _OAuthClient = [[BSNSCOAuth2Client alloc] initWithClientId:BSNSCCONFIG(linkedinClientId)
                                                  clientSecret:BSNSCCONFIG(linkedinClientSecret)
                                             callBackURLString:BSNSCCONFIG(linkedinCallBackURLString)
                                         requestTokenURLString:self.requestTokenURLString
                                          accessTokenURLString:self.accessTokenURLString
                                                    forSharer:self.class];
    
    return self;
}


#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeLinkedIn;
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
    [self shareTitle:shareModel.text webPageURLString:shareModel.webPageLink imageURLString:imageURLString completeBlock:^(BOOL success, NSError *error) {
        if (error.code == BSNSCAccessTokenExpireError) {
            [self logout];
        }
        BLOCK_SAFE_RUN(completeBlock, success, error);
    }];
}

- (void)logout {
    [self.OAuthClient logout];
}

#pragma mark - Sharer Configure
- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?client_id=%@&redirect_uri=%@&scope=%@&response_type=code&state=xoiwqlsdfjaowe", BSNSCCONFIG(linkedinClientId), BSNSCCONFIG(linkedinCallBackURLString), @"r_basicprofile w_share".utf8AndURLEncode];
}

- (NSString *)accessTokenURLString {
    return @"https://www.linkedin.com/uas/oauth2/accessToken";
}

- (NSString *)shareTextURLString {
    return @"https://api.linkedin.com/v1/people/~/shares?format=json";
}

# pragma mark - Helper Method
- (void)shareTitle:(NSString *)title webPageURLString:(NSString *)webPageURLString imageURLString:(NSString *)imageURLString completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!title.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareContentNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSDictionary *dictionary = @{@"comment" : title,
                                 @"content" : @{@"submitted-url" : webPageURLString ?: @"", @"submitted-image-url" : imageURLString ?: @""},
                                 @"visibility" :@{@"code" : @"anyone"}};
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:nil];
    NSMutableURLRequest *request = [[self.OAuthClient requestWithPath:[self shareTextURLString] data:JSONData HTTPMethod:@"POST"] mutableCopy];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
        } else {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200 || statusCode == 201 || statusCode == 202) {
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
    
    [postTask resume];
}

@end
