//
//  BSNSCError.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/9.
//
//

#import <Foundation/Foundation.h>

extern NSString* const BSNSCShareCenterErrorDomain;

extern NSString *const BSNSCUnAuthorizedMsg;
extern NSString *const BSNSCRemoteDataFormatInvalidMsg;
extern NSString *const BSNSCShareFailureMsg;
extern NSString *const BSNSCRequestTokenNilMsg;
extern NSString *const BSNSCAccessTokenNilMsg;
extern NSString *const BSNSCAccessTokenOrSecretNilMsg;
extern NSString *const BSNSCAuthCodeOrSecretNilMsg;
extern NSString *const BSNSCUserIdNilMsg;
extern NSString *const BSNSCBlogNameNilMsg;
extern NSString *const BSNSCOauthVerifierNilMsg;
extern NSString *const BSNSCUnsupportSharerMsg;
extern NSString *const BSNSCRepeatShareMsg;
extern NSString *const BSNSCShareContentNotSupportMsg;
extern NSString *const BSNSCShareContentNilMsg;
extern NSString *const BSNSCRemoteDataNilMsg;
extern NSString *const BSNSCShareAccountUnkownMsg;
extern NSString *const BSNSCAccessTokenExpireMsg;
extern NSString *const BSNSCShareTextNilMsg;
extern NSString *const BSNSCShareLinkNilMsg;
extern NSString *const BSNSCMediaAttachmentIDNilMsg;
extern NSString *const BSNSCShareImagesAttachmentNilMsg;
extern NSString *const BSNSCWeChatNoInstallMsg;

typedef NS_ENUM(NSInteger, BSNSCErrorType) {
    BSNSCShareError = 1000,
    BSNSCAuthorizationError,
    BSNSCAccessTokenExpireError
};

@interface BSNSCError : NSError
+ (NSError *)errorWithCode:(BSNSCErrorType)errorCode message:(NSString *)message;
@end
