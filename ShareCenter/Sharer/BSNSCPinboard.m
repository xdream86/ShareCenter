//
//  BSNSCPinboard.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/6/2.
//
//

#import "BSNSCPinboard.h"
#import "NSString+BSNSCExtension.h"

@interface BSNSCPinboard ()
@property (nonatomic, strong) BSNSCBasicAuthClient *basicAuthClient;
@end

@implementation BSNSCPinboard
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
    return BSNSCSharerTypePinboard;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodBasic;
}

- (BOOL)isAuthorizated {
    return [self.basicAuthClient isAuthorizated];
}

- (void)authorizeWithUserName:(NSString *)userName password:(NSString *)password completeBlock:(void (^)(BOOL success, NSError *error))completeBlock {
    [_basicAuthClient authorizeWithUserName:userName password:password completeBlock:completeBlock];
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![self isAuthorizated]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCUnAuthorizedMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!shareModel.webPageLink.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    if (!shareModel.text.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareTextNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    NSURLRequest *request = [_basicAuthClient requestWithPath:shareTextURLString(shareModel.webPageLink, shareModel.text, shareModel.tags)
                                                       params:nil
                                                   HTTPMethod:@"GET"];
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

#pragma mark - Sharer Configure

- (NSString *)authorizeURLString {
    return @"https://api.pinboard.in/v1/user/api_token/";
}

NSString *shareTextURLString(NSString *link, NSString *title, NSString *tags) {
    NSDictionary *params = @{@"url" : link.utf8AndURLEncode,
                             @"description" : title.utf8AndURLEncode,
                             @"tags" : tags.utf8AndURLEncode ?: @"",
                             @"format" : @"json"};
    NSMutableArray *paramsArray = [NSMutableArray new];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *oneQueryString = [NSString stringWithFormat:@"%@=%@", key, obj];
        [paramsArray addObject:oneQueryString];
    }];
    NSString *paramsString = [paramsArray componentsJoinedByString:@"&"];
    NSString *path = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?%@", paramsString];
    
    return path;
}

@end
