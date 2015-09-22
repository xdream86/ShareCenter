//
//  NSDictionary+QueryParameters.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/20.
//
//

#import "NSDictionary+BSNSCExtension.h"
#import "NSString+BSNSCExtension.h"

@implementation NSDictionary (BSNSCExtension)

- (NSString *)queryParameter {
    NSMutableArray *parameterPair = [NSMutableArray new];
    [self enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
        NSString *aPair;
        if (!value || [value isEqual:[NSNull null]]) {
            aPair = [field description].utf8AndURLEncode;
        } else {
            aPair = [NSString stringWithFormat:@"%@=%@", [field description].utf8AndURLEncode, [value description].utf8AndURLEncode];
        }
        [parameterPair addObject:aPair];
    }];
    
    return [parameterPair componentsJoinedByString:@"&"];
}

@end
