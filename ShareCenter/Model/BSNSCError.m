//
//  BSNSCError.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/9.
//
//

#import "BSNSCError.h"

NSString* const BSNSCShareCenterErrorDomain = @"ShareCenterErrorDomain";

NSString *const BSNSCUnAuthorizedMsg = @"unauthorized";
NSString *const BSNSCRemoteDataFormatInvalidMsg = @"data from server return formate invalid";
NSString *const BSNSCShareFailureMsg = @"share failure, unknow reson";
NSString *const BSNSCRequestTokenNilMsg = @"request token not received";
NSString *const BSNSCAccessTokenNilMsg = @"acess token not received";
NSString *const BSNSCMediaAttachmentIDNilMsg = @"media attachment id not received";
NSString *const BSNSCAccessTokenOrSecretNilMsg = @"acess token or secret not received ";
NSString *const BSNSCAuthCodeOrSecretNilMsg = @"auth code or secretnot received ";
NSString *const BSNSCUserIdNilMsg = @"user id not received";
NSString *const BSNSCBlogNameNilMsg = @"blog name not received";
NSString *const BSNSCOauthVerifierNilMsg = @"oauth verifier not received";
NSString *const BSNSCUnsupportSharerMsg = @"unsupported sharer";
NSString *const BSNSCRepeatShareMsg = @"content repeat sharing";
NSString *const BSNSCShareContentNotSupportMsg = @"share content type not be support";
NSString *const BSNSCShareTextNilMsg = @"text fields must not be null";
NSString *const BSNSCShareImagesAttachmentNilMsg = @"share media attachment not be null";
NSString *const BSNSCShareLinkNilMsg = @"link fields must not be null";
NSString *const BSNSCShareContentNilMsg = @"share content is empty";
NSString *const BSNSCShareAccountUnkownMsg = @"please choose a account to share";
NSString *const BSNSCRemoteDataNilMsg = @"receiver data from server is empty";
NSString *const BSNSCAccessTokenExpireMsg = @"access token expire or unavilable";
NSString *const BSNSCWeChatNoInstallMsg = @"wechat not yet installed";

@implementation BSNSCError

+ (NSError *)errorWithCode:(BSNSCErrorType)errorCode message:(NSString *)message {
    NSError *error = [NSError errorWithDomain:BSNSCShareCenterErrorDomain
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(message, nil) ?: @""}];
    
    return error;
}

@end
