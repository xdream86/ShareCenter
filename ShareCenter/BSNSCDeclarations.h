//
//  BSNSCDeclarations.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

@import Foundation;
@import UIKit;
@import SystemConfiguration;
@import Security;
@import MediaPlayer;
@import CoreData;
@import CoreText;
@import CoreMotion;
@import CoreLocation;
@import CoreGraphics;
@import AssetsLibrary;
@import AddressBook;
@import MobileCoreServices;
@import MessageUI;

/*! 超时时间 */
#define kTimeOutInvervalForRequest 10

#ifndef __IPHONE_7_0
#warning "This project uses features only available in iOS SDK 7.0 and later."
#endif

/*! 单例 */
#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \

/*! 调试信息 */
#ifdef DEBUG
#define _BSNSCKDebugShowLogs
#endif

#ifdef _BSNSCKDebugShowLogs
#define BSNSCDebugShowLogs			1
#define BSNSCLog( s, ... ) NSLog( @"<%s %@:(%d)> %@", __func__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define BSNSCDebugShowLogs			0
#define BSNSCLog( s, ... )
#endif

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

/*! 安全调用block */
#define BLOCK_SAFE_RUN(block, ...) block ? dispatch_async(dispatch_get_main_queue(), ^{\
block(__VA_ARGS__); \
}): nil

typedef NS_ENUM(NSInteger, BSNSCSharerType) {
    BSNSCSharerTypeNone,
    BSNSCSharerTypeBuffer,
    BSNSCSharerTypeDelicious,
    BSNSCSharerTypeReadability,
    BSNSCSharerTypeFacebook,
    BSNSCSharerTypeTwitter,
    BSNSCSharerTypePocket,
    BSNSCSharerTypeGooglePlus,
    BSNSCSharerTypePinterest,
    BSNSCSharerTypeInstapaper,
    BSNSCSharerTypeDropbox,
    BSNSCSharerTypeTumblr,
    BSNSCSharerTypeWeiBo,
    BSNSCSharerTypeLinkedIn,
    BSNSCSharerTypePinboard,
    BSNSCSharerTypeEvernote,
    BSNSCSharerTypeWeChat,
    BSNSCSharerTypeWeChatFriends,
};

typedef NS_ENUM(NSInteger, BSNSCAuthorizationMethod) {
    BSNSCAuthMethodNone,
    BSNSCAuthMethodBasic,
    BSNSCAuthMethodOAuth,
    BSNSCAuthMethodSDK
};
