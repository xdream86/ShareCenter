//
//  BSNSCConfiguration.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/17.
//
//

#import <Foundation/Foundation.h>
@class BSNSCDefaultConfigurator;

@interface BSNSCConfiguration : NSObject 

+ (BSNSCConfiguration*)sharedInstance;
+ (BSNSCConfiguration*)sharedInstanceWithConfigurator:(BSNSCDefaultConfigurator*)config;

- (id)configurationValue:(NSString*)selector withObject:(id)object;

#define BSNSCCONFIG(_CONFIG_KEY) [[BSNSCConfiguration sharedInstance] configurationValue:@#_CONFIG_KEY withObject:nil]
#define BSNSCCONFIG_WITH_ARGUMENT(_CONFIG_KEY, _CONFIG_ARG) [[BSNSCConfiguration sharedInstance] configurationValue:@#_CONFIG_KEY withObject:_CONFIG_ARG]

@end
