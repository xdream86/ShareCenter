//
//  MyConfigurator.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/18.
//
//

#import "MyConfigurator.h"

@implementation MyConfigurator

- (NSString *)bufferClientId {
    return @"";
}

- (NSString *)bufferClientSecret {
    return @"";
}

- (NSString *)bufferCallBackURLString {
    return @"";
}

- (NSString *)deliciousClientId {
    return @"";
}

- (NSString *)deliciousClientSecret {
    return @"";
}

- (NSString *)deliciousCallBackURLString {
    return @"";
}

- (NSString *)facebookClientId {
    return @"";
}

- (NSString *)facebookClientSecret {
    return @"";
}

- (NSString *)facebookCallBackURLString {
    return @"";
}

- (NSString *)twitterConsumerKey {
    return @"";
}

- (NSString *)twitterConsumerSecret {
    return @"";
}

- (NSString *)twitterCallbackURLString {
    return @"";
}

- (NSString *)readabilityConsumerKey {
    return @"";
}

- (NSString *)readabilityConsumerSecret {
    return @"";
}

- (NSString *)readabilityCallbackURLString {
    return @"";
}

- (NSString *)pocketConsumerKey {
    return @"";
}

- (NSString *)pocketCallbackURLString {
    return @"";
}

- (NSString *)googlePlusClientId {
    return @"";
}

- (NSString *)googlePlusSecret {
    return @"";
}

- (NSString *)pinterestClientId {
    return @"";
}

- (NSString *)dropboxClientId {
    return @"";
}

- (NSString *)dropboxClientSecret {
    return @"";
}

- (NSString *)dropboxCallBackURLString {
    return @"";
}

- (NSString *)tumblrConsumerKey {
    return @"";
}

- (NSString *)tumblrConsumerSecret {
    return @"";
}

- (NSString *)tumblrCallbackURLString {
    return @"";
}

- (NSString *)weiboClientId {
    return @"";
}

- (NSString *)weiboClientSecret {
    return @"";
}

- (NSString *)weiboCallBackURLString {
    return @"";
}

- (NSString *)linkedinClientId {
    return @"";
}

- (NSString *)linkedinClientSecret {
    return @"";
}

- (NSString *)linkedinCallBackURLString {
    return @"";
}

- (NSString *)evernoteConsumerKey {
    return @"";
}

- (NSString *)evernoteConsumerSecret {
    return @"";
}

- (NSString *)evernoteCallbackURLString {
    NSString *callbackScheme = [self.evernoteConsumerKey stringByReplacingOccurrencesOfString:@"_" withString:@"+"];
    return [NSString stringWithFormat:@"%@://response", callbackScheme];
}

- (NSString *)weixinAppID {
    return @"";
}

@end
