//
//  BSNSCPinterest.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/22.
//
//

#import "BSNSCPinterest.h"

#ifdef ShareCenter
#import <Pinterest/Pinterest.h>
#endif

@interface BSNSCPinterest ()
//@property (nonatomic, strong) Pinterest *OAuthClient;
@end

@implementation BSNSCPinterest
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
//    _OAuthClient = [[Pinterest alloc] initWithClientId:BSNSCCONFIG(pinterestClientId)];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodOAuth;
}

+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypePinterest;
}

- (BOOL)isAuthorizated {
    return YES;
}

- (void)authorizeWithWebView:(UIWebView *)webView completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    BLOCK_SAFE_RUN(completeBlock, YES, nil);
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
//    if (![shareModel.fileModels count]) {
//        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareTextNilMsg];
//        BLOCK_SAFE_RUN(completeBlock, NO, error);
//        return;
//    }
//    
//    BSNSCFileModel *fileModel = [shareModel.fileModels firstObject];
//    NSString *imageURLString = fileModel.link;
//    
//    [self.OAuthClient createPinWithImageURL:[NSURL URLWithString:imageURLString]
//                                  sourceURL:[NSURL URLWithString:shareModel.webPageLink]
//                                description:shareModel.text];
//    BLOCK_SAFE_RUN(completeBlock, YES, nil);
}

- (void)logout {
}

@end
