//
//  UIViewController+BSNSCPrsentViewControllerFromVisibleViewController.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/29.
//
//

#import "UIViewController+BSNSCExtension.h"

@implementation UIViewController (BSNSCExtension)

- (void)presentVCFromVisibleVC:(UIViewController *)viewControllerToPresent completion:(void (^)(void))completion {
    [[self explorePresentedViewController] presentViewController:viewControllerToPresent animated:YES completion:completion];
}

- (void)dismissVCFromVisibleVCAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [[self explorePresentedViewController] dismissViewControllerAnimated:animated completion:completion];
}

- (UIViewController *)explorePresentedViewController {
    if ([self isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)self;
        return navController.topViewController;
    } else if (self.presentedViewController) {
        return [self.presentedViewController explorePresentedViewController];
    } else {
        return self;
    }
}

@end
