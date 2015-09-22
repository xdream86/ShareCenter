//
//  BSNSCShareModel.m
//  BSNShareCenter
//
//  Created by Jun Xia on 15/5/28.
//
//

#import "BSNSCShareModel.h"

@interface BSNSCShareModel()
@property (nonatomic, strong) NSMutableArray *fileModels_Private;
@end

@implementation BSNSCShareModel

- (NSString *)fileURLStringAtIndex:(NSInteger)index {
    if (index >= [self.files count]) {
        return nil;
    }
    
    BSNSCFileModel *fileModel = self.files[index];
    return fileModel.link;
}

- (NSString *)fileNameStringAtIndex:(NSInteger)index {
    if (index >= [self.files count]) {
        return nil;
    }
    
    BSNSCFileModel *fileModel = self.files[index];
    return fileModel.name;
}

- (NSData *)fileDataAtIndex:(NSInteger)index {
    if (index >= [self.files count]) {
        return nil;
    }
    
    BSNSCFileModel *fileModel = self.files[index];
    return fileModel.rawData;
}

- (BSNSCFileType)fileTypeAtInDEX:(NSInteger)index {
    if (index >= [self.files count]) {
        return BSNSCFileTypeNone;
    }
    
    BSNSCFileModel *fileModel = self.files[index];
    return fileModel.type;
}

- (BSNSCSharerType)sharerType {
    return _sharerType ? _sharerType : BSNSCSharerTypeNone;
}

- (NSString *)text {
    return _text.length > 0 ? _text : @"";
}

- (NSString *)webPageLink {
    return _webPageLink.length > 0 ? _webPageLink : @"";
}

- (NSString *)tags {
    return _tags.length > 0 ? _tags : @"";
}

- (void)pushFileModel:(BSNSCFileModel *)fileModel {
    [self.fileModels_Private addObject:fileModel];
}

- (BSNSCFileModel *)popFileModel {
    if ([self.fileModels_Private count] == 0) {
        return nil;
    }
    
    BSNSCFileModel *lastFileModel = [self.fileModels_Private lastObject];
    [self.fileModels_Private removeObject:lastFileModel];
    
    return lastFileModel;
}

- (NSArray *)files {
    return [self.fileModels_Private copy];
}

- (NSMutableArray *)fileModels_Private {
    if (!_fileModels_Private) {
        _fileModels_Private = [NSMutableArray new];
    }
    
    return _fileModels_Private;
}

@end

@interface BSNSCFileModel()
@property (nonatomic, strong) NSDateFormatter *formatter;
@end

@implementation BSNSCFileModel

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _formatter = [NSDateFormatter new];
    [_formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    
    return self;
}

- (NSString *)name {
    if (_name.length) return _name;
    
    NSString *dateString = [_formatter stringFromDate:[NSDate date]];
    if (self.type == BSNSCFileTypePdf) {
        return [NSString stringWithFormat:@"%@.pdf", dateString];
    } else if (self.type == BSNSCFileTypeImage) {
        return [NSString stringWithFormat:@"%@.png", dateString];
    } else {
        return dateString;
    }
}

- (NSString *)link {
    return _link.length ? _link : @"";
}

@end
