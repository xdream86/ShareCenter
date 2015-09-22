//
//  BSNSCXAuthClient.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/24.
//
//

#import "BSNSCBasicAuthClient.h"
#import "BSNSCDeclarations.h"
#import "NSString+BSNSCExtension.h"
#import "NSDictionary+BSNSCExtension.h"
#import "BSNSCKeychain.h"

@interface BSNSCCredential : NSObject
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *password;
@end
@implementation BSNSCCredential
@end

@interface BSNSCBasicAuthClient()
@property (nonatomic, copy) NSString *authorizeURLString;
@property (nonatomic, copy) Class sharer;
@end

@implementation BSNSCBasicAuthClient

- (instancetype)initWithAuthorizeURLString:(NSString *)authorizeURLString
                                 forSharer:(Class)sharer {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _authorizeURLString = authorizeURLString;
    _sharer = sharer;
    
    return self;
}

- (void)authorizeWithUserName:(NSString *)userName
                     password:(NSString *)password
                completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_authorizeURLString]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setHTTPMethod:@"GET"];
    NSString *combineUserNameAndPwdString = [NSString stringWithFormat:@"%@:%@", userName, password];
    NSData *combineUserNameAndPwdData = [combineUserNameAndPwdString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [combineUserNameAndPwdData base64EncodedStringWithOptions:0];
    [request setValue:[NSString stringWithFormat:@"Basic %@", base64String] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            BLOCK_SAFE_RUN(completeBlock, NO, error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 200) {
            BSNSCCredential *credential = [BSNSCCredential new];
            credential.userName = userName;
            credential.password = password;
            [self saveCredential:credential];
            BLOCK_SAFE_RUN(completeBlock, YES, nil);
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
    }];
    [task resume];
}


- (NSURLRequest *)requestWithPath:(NSString *)path
                           params:(NSDictionary *)params
                       HTTPMethod:(NSString *)HTTPMethod {
    if (!self.isAuthorizated) {
        return nil;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
    request.timeoutInterval = kTimeOutInvervalForRequest;
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    BSNSCCredential *credential = [self credential];
    NSString *combineUserNameAndPwdString = [NSString stringWithFormat:@"%@:%@", credential.userName, credential.password];
    NSData *combineUserNameAndPwdData = [combineUserNameAndPwdString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [combineUserNameAndPwdData base64EncodedStringWithOptions:0];
    [request setValue:[NSString stringWithFormat:@"Basic %@", base64String] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = HTTPMethod;
    
    if ([HTTPMethod isEqualToString:@"POST"] && params != nil) {
        NSData *postData = [params.queryParameter dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:postData];
        NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    }
    
    return request;
}

- (BOOL)isAuthorizated {
    BSNSCCredential *credential = [self credential];
    return credential.userName.length && credential.password.length;
}

- (void)logout {
    [self eraseCredential];
}

#pragma mark - Helper Method
- (BSNSCCredential *)credential {
    NSString *userName = [BSNSCKeychain defaultKeychain][self.userNamekey];
    NSString *password = [BSNSCKeychain defaultKeychain][self.passwordkey];
    BSNSCCredential *credential = [BSNSCCredential new];
    credential.userName = userName;
    credential.password = password;
    
    return credential;
}

- (void)saveCredential:(BSNSCCredential *)credential {
    if (credential.userName.length && credential.password.length) {
        [BSNSCKeychain defaultKeychain][self.userNamekey] = credential.userName;
        [BSNSCKeychain defaultKeychain][self.passwordkey] = credential.password;
    }
}

- (void)eraseCredential {
    [[BSNSCKeychain defaultKeychain] removeObjectForKey:self.userNamekey];
    [[BSNSCKeychain defaultKeychain] removeObjectForKey:self.passwordkey];
}

- (NSString *)userNamekey {
    return [NSString stringWithFormat:@"%@-%@-username", [NSString uuid], NSStringFromClass(_sharer)];
}

- (NSString *)passwordkey {
    return [NSString stringWithFormat:@"%@-%@-password", [NSString uuid], NSStringFromClass(_sharer)];
}

@end
