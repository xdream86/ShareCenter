//
//  AppDelegate.m
//  BSNShareCenterDemo
//
//  Created by Jun Xia on 15/5/7.
//
//

#import "AppDelegate.h"
#import "BSNSCConfiguration.h"
#import "MyConfigurator.h"
#import "BSNSCShareCenter.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    MyConfigurator *configurator = [[MyConfigurator alloc] init];
    
    [BSNSCConfiguration sharedInstanceWithConfigurator:configurator];
    
    return YES;
}

- (BOOL)application: (UIApplication *)application openURL: (NSURL *)url sourceApplication: (NSString *)sourceApplication annotation: (id)annotation {
    if ([BSNSCShareCenter handLoginCallback:url]) {
        return YES;
    }
    
    return NO;
}

@end
