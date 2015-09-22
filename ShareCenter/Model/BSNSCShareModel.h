//
//  BSNSCShareModel.h
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/28.
//
//

#import <Foundation/Foundation.h>
#import "BSNSCDeclarations.h"

typedef NS_ENUM(NSInteger, BSNSCFileType) {
    BSNSCFileTypeNone,
    BSNSCFileTypePdf,
    BSNSCFileTypeImage
};

@interface BSNSCFileModel : NSObject
@property (nonatomic, assign) BSNSCFileType type;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, strong) NSData *rawData;
@end

@interface BSNSCShareModel : NSObject
@property (nonatomic, assign) BSNSCSharerType sharerType;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *webPageLink;
@property (nonatomic, copy) NSString *tags; // 多个tag则用逗号分隔
@property (nonatomic, strong, readonly) NSArray *files;

- (void)pushFileModel:(BSNSCFileModel *)fileModel;
- (BSNSCFileModel *)popFileModel;

/*! 便利方法 */
- (NSString *)fileNameStringAtIndex:(NSInteger)index;
- (NSString *)fileURLStringAtIndex:(NSInteger)index;
- (NSData *)fileDataAtIndex:(NSInteger)index;
- (BSNSCFileType)fileTypeAtInDEX:(NSInteger)index;
@end

