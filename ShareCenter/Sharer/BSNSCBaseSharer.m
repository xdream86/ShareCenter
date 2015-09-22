//
//  BSNSCBaseSharer.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "BSNSCBaseSharer.h"

static NSMutableDictionary *_sharedInstances = nil;

@implementation  BSNSCSharerAbstractClass
#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeNone;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodNone;
}

- (BOOL)isAuthorizated {
    return NO;
}

- (void)authorizeWithWebView:(UIWebView *)webView completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    BLOCK_SAFE_RUN(completeBlock, NO, nil);
}

- (void)authorizeWithUserName:(NSString *)userName password:(NSString *)password completeBlock:(void (^)(BOOL, NSError *))completeBlock {
    BLOCK_SAFE_RUN(completeBlock, NO, nil);
}

- (BOOL)handLoginCallback:(NSURL *)callBackURL {
    return NO;
}

- (void)authorizeWithCompleteBlock:(void (^)(BOOL success, NSError *error))completeBlock {
    BLOCK_SAFE_RUN(completeBlock, NO, nil);
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    BLOCK_SAFE_RUN(completeBlock, NO, nil);
}

- (void)logout {
}

@end

@implementation BSNSCBaseSharer

+ (void)initialize {
    if (_sharedInstances == nil) {
        _sharedInstances = [NSMutableDictionary dictionary];
    }
}

#pragma mark - Helper Method
+ (BSNSCBaseSharer *)sharedInstance {
    id sharedInstance = nil;
    
    @synchronized(self) {
        NSString *instanceClass = NSStringFromClass(self);
        sharedInstance = [_sharedInstances objectForKey:instanceClass];
        if (sharedInstance == nil) {
            sharedInstance = [[super allocWithZone:nil] init];
            [_sharedInstances setObject:sharedInstance forKey:instanceClass];
        }
    }
    
    return sharedInstance;
}

+ (void)destroyInstance {
    [_sharedInstances removeObjectForKey:NSStringFromClass(self)];
}

+ (NSArray *)initializedInstance {
    return [_sharedInstances allValues];
}

@end
