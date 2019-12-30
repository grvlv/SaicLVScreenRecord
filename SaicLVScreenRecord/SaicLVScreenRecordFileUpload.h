//
//  SaicLVScreenRecordFileUpload.h
//  SaicScreenRecordUpload
//
//  Created by GRV on 2019/12/23.
//  Copyright © 2019 GRV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SaicLVScreenRecordFileUploadStatus) {
    SaicLVScreenRecordFileUploadStatus_UploadStart,
    SaicLVScreenRecordFileUploadStatus_UploadSuccess,
    SaicLVScreenRecordFileUploadStatus_UploadFailure,
    SaicLVScreenRecordFileUploadStatus_UploadTempFileRemoved,
    SaicLVScreenRecordFileUploadStatus_UploadNetworkError,
    SaicLVScreenRecordFileUploadStatus_Uploading
};

@protocol SaicLVScreenRecordFileUploadDelegate <NSObject>

@optional
- (void)uploadStatus:(SaicLVScreenRecordFileUploadStatus)status message:(NSString *)msg;

@end

@interface SaicLVScreenRecordFileUpload : NSObject

@property (nonatomic, weak) id delegate;

+ (instancetype)shared;
- (void)configUploadURL:(NSString *)url;
- (void)configHearders:(NSDictionary *)headers;
- (void)setupFilePath:(NSString *)filePath fileName:(NSString *)fileName;
- (void)stopAFMonitoring;

@end

NS_ASSUME_NONNULL_END
