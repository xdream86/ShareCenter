//
//  BSNSCInstapaper.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/24.
//
//

#import "BSNSCInstapaper.h"

@interface BSNSCInstapaper ()
@property (nonatomic, strong) BSNSCBasicAuthClient *basicAuthClient;
@end

@implementation BSNSCInstapaper

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _basicAuthClient = [[BSNSCBasicAuthClient alloc] initWithAuthorizeURLString:self.authorizeURLString
                                                                     forSharer:self.class];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeInstapaper;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodBasic;
}

- (BOOL)isAuthorizated {
    return [_basicAuthClient isAuthorizated];
}

- (void)authorizeWithUserName:(NSString *)userName password:(NSString *)password completeBlock:(void (^)(BOOL success, NSError *error))completeBlock {
    [_basicAuthClient authorizeWithUserName:userName password:password completeBlock:completeBlock];
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    NSDictionary *params = @{@"title" :shareModel.text, @"url" : shareModel.webPageLink, @"selection" : shareModel.tags};
    NSURLRequest *request = [_basicAuthClient requestWithPath:[self shareTextURLString] params:params HTTPMethod:@"POST"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
    
    [postDataTask resume];
}

- (void)logout {
    [_basicAuthClient logout];
}

- (NSString *)shareTextURLString {
    return @"https://www.instapaper.com/api/add";
}

- (NSString *)authorizeURLString {
    return @"https://www.instapaper.com/api/authenticate";
}

@end
