//
//  NSObject+ClassHierarchy.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/17.
//
//

#import "NSObject+BSNSCExtension.h"
#import "objc/runtime.h"

@implementation NSObject (BSNSCExtension)

+ (NSArray *)directSubclasses {
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        superClass = class_getSuperclass(superClass);
        if (superClass == self.class) {
            [result addObject:classes[i]];
        }
    }
    
    free(classes);

    return result;
}

@end
