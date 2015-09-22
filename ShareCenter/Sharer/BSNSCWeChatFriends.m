//
//  BSNSCWeiXinFriends.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/6/6.
//
//

#import "BSNSCWeChatFriends.h"

#ifdef ShareCenter
#import "WXApi.h"
#else
#import <WeChatSDK_1.5/WXApi.h>
#import <WeChatSDK_1.5/WXApiObject.h>
#endif

@interface BSNSCWeChatFriends () <WXApiDelegate>
@property (copy) void (^shareCompleteHandler)(BOOL success, NSError*error);
@end

@implementation BSNSCWeChatFriends
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [WXApi registerApp:BSNSCCONFIG(weixinAppID)];
    
    return self;
}

#pragma mark - BSNSCSharerAbstractMethod
+ (BSNSCSharerType)sharerType {
    return BSNSCSharerTypeWeChatFriends;
}

+ (BSNSCAuthorizationMethod)authorizationType {
    return BSNSCAuthMethodSDK;
}

- (BOOL)isAuthorizated {
    return [WXApi isWXAppInstalled];
}

- (void)authorizeWithCompleteBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    if (![WXApi isWXAppInstalled]) {
        NSError *error = [BSNSCError errorWithCode:BSNSCAuthorizationError message:BSNSCWeChatNoInstallMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    BLOCK_SAFE_RUN(completeBlock, YES, nil);
}

- (BOOL)handLoginCallback:(NSURL *)callBackURL {
    return [WXApi handleOpenURL:callBackURL delegate:self];
}

- (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock {
    _shareCompleteHandler = ^(BOOL success, NSError *error) {
        BLOCK_SAFE_RUN(completeBlock, success, error);
    };
    
    if (!shareModel.webPageLink.length) {
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:BSNSCShareLinkNilMsg];
        BLOCK_SAFE_RUN(completeBlock, NO, error);
        return;
    }
    
    WXMediaMessage *message = [WXMediaMessage message];
    NSData *rawData = [shareModel fileDataAtIndex:0];
    if (rawData.length) {
        WXImageObject *imageObject = [WXImageObject new];
        imageObject.imageData = rawData;
        message.mediaObject = imageObject;
        message.thumbData = UIImageJPEGRepresentation([UIImage imageWithData:rawData], (32 * 1024) / rawData.length);
        message.title = shareModel.text;
    } else {
        WXWebpageObject *webPageObject = [WXWebpageObject object];
        webPageObject.webpageUrl = shareModel.webPageLink;
        message.mediaObject = webPageObject;
        message.title = shareModel.text;
    }

    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneTimeline;
    
    [WXApi sendReq:req];
}

- (void)logout {
}

#pragma mark - WXApiDelegate

-(void) onReq:(BaseReq*)req {
    
}

- (void)onResp:(BaseResp *)resp{
    if (resp.errCode == WXSuccess) {
        BLOCK_SAFE_RUN(_shareCompleteHandler, YES, nil);
    } else {
        NSString *errorMsg = [NSString stringWithFormat:@"errorcode:%d errorDescription:%@", resp.errCode, resp.errStr];
        NSError *error = [BSNSCError errorWithCode:BSNSCShareError message:errorMsg];
        BLOCK_SAFE_RUN(_shareCompleteHandler, NO, resp.errCode == WXErrCodeUserCancel ? nil : error);
    }
}

@end
