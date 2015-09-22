//
//  BSNSCDefaultConfigurator.h
// BSNShareCenter
//  Created by Jun Xia on 15/5/17.
//
//

#import <Foundation/Foundation.h>


@interface BSNSCDefaultConfigurator : NSObject 

- (NSString *)bufferClientId;
- (NSString *)bufferClientSecret;
- (NSString *)bufferCallBackURLString;

- (NSString *)deliciousClientId;
- (NSString *)deliciousClientSecret;
- (NSString *)deliciousCallBackURLString;

- (NSString *)facebookClientId;
- (NSString *)facebookClientSecret;
- (NSString *)facebookCallBackURLString;

- (NSString *)twitterConsumerKey;
- (NSString *)twitterConsumerSecret;
- (NSString *)twitterCallbackURLString;

- (NSString *)readabilityConsumerKey;
- (NSString *)readabilityConsumerSecret;
- (NSString *)readabilityCallbackURLString;

- (NSString *)pocketConsumerKey;
- (NSString *)pocketCallbackURLString;

- (NSString *)googlePlusClientId;
- (NSString *)googlePlusSecret;

- (NSString *)pinterestClientId;

- (NSString *)dropboxClientId;
- (NSString *)dropboxClientSecret;
- (NSString *)dropboxCallBackURLString;

- (NSString *)tumblrConsumerKey;
- (NSString *)tumblrConsumerSecret;
- (NSString *)tumblrCallbackURLString;

- (NSString *)weiboClientId;
- (NSString *)weiboClientSecret;
- (NSString *)weiboCallBackURLString;

- (NSString *)linkedinClientId;
- (NSString *)linkedinClientSecret;
- (NSString *)linkedinCallBackURLString;

- (NSString *)evernoteConsumerKey;
- (NSString *)evernoteConsumerSecret;
- (NSString *)evernoteCallbackURLString;

- (NSString *)weixinAppID;
@end
