//
//  BSNShareCenter.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/8.
//
//

#import "BSNSCDeclarations.h"
#import "BSNSCShareModel.h"

@interface BSNSCShareCenter : NSObject

/**
 * @brief 是否已经认证
 */
+ (BOOL)isAuthorizatedSharer:(BSNSCSharerType)sharer;

/**
 * @brief 单独执行认证授权
 * @note 认证成功后的凭证会被保存在本地
 */
+ (void)loginToSharer:(BSNSCSharerType)sharer completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;

/**
 * @brief 分享
 * @note  如果分享之前还没有认证授权，会自动弹出认证授权页面，授权完成后，执行分享
 */
+ (void)shareWithShareModel:(BSNSCShareModel *)shareModel completeBlock:(void(^)(BOOL success, NSError *error))completeBlock;

/**
 * @brief 处理浏览器传回的认证信息
 */
+ (BOOL)handLoginCallback:(NSURL *)callBackURL;

/**
 * @brief 退出分享账号，删除授权凭证
 */
+ (void)logoutSharer:(BSNSCSharerType)sharer;
+ (void)logoutAllSharer;
@end
