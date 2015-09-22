//
//  BSNSCOAuthValidationViewController.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/24.
//
//

#import <UIKit/UIKit.h>
typedef void (^AuthorizationResponseBlock)(BOOL success, NSError *error);
typedef void (^CancelAuthorizationBlock)(void);
typedef void (^SubmitAuthorizationBlock)(NSString *userName, NSString *password, AuthorizationResponseBlock responseBlock);

@interface BSNSCXAuthValidationViewController : UIViewController
/**
 * 信号输出
 * 传递登陆凭证给认证模块
 */
@property (nonatomic, copy) CancelAuthorizationBlock cancelAuthorizationBlock;
@property (nonatomic, copy) SubmitAuthorizationBlock submitAuthorizationBlock;

/**
 * 信号输入
 * 用户提交登录凭证之后，认证模块回传认证结果
 */
@property (nonatomic, copy) AuthorizationResponseBlock authorizationResponseBlock;

@end

