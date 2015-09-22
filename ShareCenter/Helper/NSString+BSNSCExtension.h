//
//  NSString+URLEncoding.h
//  ASPinboard
//
//  Created by Dan Loewenherz on 1/29/13.
//  Copyright (c) 2013 Aurora Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BSNSCExtension)
- (NSDictionary *)parametersFromQueryString;
+ (NSString *)getNonce;
+ (NSString *)uuid;
- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
- (NSString *)utf8AndURLEncode;
- (NSString *)removeNonAsciiCharacter;
@end
