//
//  BSNSCXAuthClient.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/24.
//
//

#import "BSNSCError.h"

@interface BSNSCBasicAuthClient : NSObject

- (instancetype)initWithAuthorizeURLString:(NSString *)authorizeURLString
                         forSharer:(Class)sharer;

- (void)authorizeWithUserName:(NSString *)userName
                     password:(NSString *)password
                completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;

- (NSURLRequest *)requestWithPath:(NSString *)path
                           params:(NSDictionary *)params
                       HTTPMethod:(NSString *)HTTPMethod;

- (BOOL)isAuthorizated;

- (void)logout;

@end
