//
//  SaicLVScreenRecordManager.m
//  SaicScreenRecordUpload
//
//  Created by GRV on 2019/12/24.
//  Copyright © 2019 GRV. All rights reserved.
//

#import "SaicLVScreenRecordManager.h"
#import "SaicLVScreenRecordWriter.h"
#import "SaicLVScreenRecordFileUpload.h"
#import <Photos/Photos.h>

@interface SaicLVScreenRecordManager()

@property (nonatomic, strong) NSDictionary *rootDic;
@property (nonatomic, strong) NSMutableArray *writers;
@property (nonatomic, strong) SaicLVScreenRecordConfig *config;

@end

@implementation SaicLVScreenRecordManager

+ (instancetype)shared {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SaicLVScreenRecordManager alloc] init];
        [instance authorize];
    });
    return instance;
}

- (void)authorize {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status != PHAuthorizationStatusAuthorized) {
                    [self setupStatus:SaicLVScreenRecordStatus_Unauthorized msg:@"相册未授权"];
                }
            }];
            break;
        }
        case PHAuthorizationStatusAuthorized:
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            [self setupStatus:SaicLVScreenRecordStatus_Unauthorized msg:@"相册未授权"];
            break;
        default:
            break;
    }
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *, NSObject *> *)setupInfo {
    [self setupStatus:SaicLVScreenRecordStatus_RecordStart msg:@"录屏开始"];
    _rootDic = setupInfo;
    _writers = [[NSMutableArray alloc] init];
    [self setupConfig];
    [self setupWriter];
    [self checkFile];
}

- (void)broadcastPaused {
    
}

- (void)broadcastResumed {
    
}

- (void)broadcastFinished {
    [[SaicLVScreenRecordFileUpload shared] stopAFMonitoring];
    [self setupStatus:SaicLVScreenRecordStatus_RecordStop msg:@"录屏结束"];
    if (_writers.count) {
        SaicLVScreenRecordWriter *writer = _writers.lastObject;
        [writer finishWriting];
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    if (!_writers.lastObject) {
        return;
    }
    SaicLVScreenRecordWriter *writer = _writers.lastObject;
    dispatch_sync(dispatch_get_main_queue(), ^{
        [writer writeSampleBuffer:sampleBuffer type:sampleBufferType];
    });
}

- (void)setupConfig {
    _config = [[SaicLVScreenRecordConfig alloc] init];
    _config.maxMB = [_rootDic[@"maxMB"] doubleValue];
    _config.screenRecordWidth = [_rootDic[@"screenRecordWidth"] integerValue];
    _config.screenRecordheight = [_rootDic[@"screenRecordheight"] integerValue];
    _config.videoFrameRate = [_rootDic[@"videoFrameRate"] integerValue];
    _config.videoBitRate = [_rootDic[@"videoBitRate"] integerValue];
    _config.audioBitRate = [_rootDic[@"audioBitRate"] integerValue];
    _config.audioSampleRate = [_rootDic[@"audioSampleRate"] integerValue];
    _config.audioNumberOfChannels = [_rootDic[@"audioNumberOfChannels"] integerValue];
    _config.uid = _rootDic[@"uid"];
    _config.uploadURL = _rootDic[@"uploadURL"];
    _config.headers = _rootDic[@"headers"];
    [SaicLVScreenRecordFileUpload shared].delegate = self;
    [[SaicLVScreenRecordFileUpload shared] configUploadURL:_config.uploadURL];
    [[SaicLVScreenRecordFileUpload shared] configHearders:_config.headers];
}

- (void)setupWriter {
    SaicLVScreenRecordWriter *writer = [[SaicLVScreenRecordWriter alloc] initWithConfig:_config];
    writer.delegate = self;
    [_writers addObject:writer];
}

- (void)checkFile {
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SaicLVScreenRecord"];
    NSArray *fileArray = [[NSFileManager defaultManager] subpathsAtPath:filePath];
    NSLog(@"%@", fileArray);
    
    for (NSString *name in fileArray) {
        NSString *file = [filePath stringByAppendingPathComponent:name];
        NSInteger fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil].fileSize;
        double mb = fileSize / 1024.0f / 1024.0f;
        NSLog(@"%f", mb);
    }
}

- (void)writeCompleted:(SaicLVScreenRecordWriterStatus)status filePath:(NSString *)filePath fileName:(NSString *)fileName writeObj:(id)obj {
    switch (status) {
        case SaicLVScreenRecordWriterStatus_WriteNext:
            [self setupWriter];
            break;
        case SaicLVScreenRecordWriterStatus_WriteSuccess:
            [_writers removeObject:obj];
            [[SaicLVScreenRecordFileUpload shared] setupFilePath:filePath fileName:fileName];
            break;
        case SaicLVScreenRecordWriterStatus_WriteFailure:
            [_writers removeObject:obj];
            break;
        default:
            break;
    }
}

- (void)writeStatus:(SaicLVScreenRecordWriterStatus)status message:(NSString *)msg {
    switch (status) {
        case SaicLVScreenRecordWriterStatus_WriteStart:
            [self setupStatus:SaicLVScreenRecordStatus_WriteStart msg:msg];
            break;
        case SaicLVScreenRecordWriterStatus_Writing:
            [self setupStatus:SaicLVScreenRecordStatus_Writing msg:msg];
            break;
        case SaicLVScreenRecordWriterStatus_WriteSuccess:
            [self setupStatus:SaicLVScreenRecordStatus_WriteSuccess msg:msg];
            break;
        case SaicLVScreenRecordWriterStatus_WriteFailure:
            [self setupStatus:SaicLVScreenRecordStatus_WriteFailure msg:msg];
            break;
        case SaicLVScreenRecordWriterStatus_WriteNext:
            [self setupStatus:SaicLVScreenRecordStatus_WriteNext msg:msg];
            break;
        case SaicLVScreenRecordWriterStatus_WriteTempFileRemoved:
            [self setupStatus:SaicLVScreenRecordStatus_WriteTempFileRemoved msg:msg];
            break;
        default:
            break;
    }
}

- (void)uploadStatus:(SaicLVScreenRecordFileUploadStatus)status message:(NSString *)msg {
    switch (status) {
        case SaicLVScreenRecordFileUploadStatus_UploadStart:
            [self checkFile];
            [self setupStatus:SaicLVScreenRecordStatus_UploadStart msg:msg];
            break;
        case SaicLVScreenRecordFileUploadStatus_UploadSuccess:
            [self setupStatus:SaicLVScreenRecordStatus_UploadSuccess msg:msg];
            break;
        case SaicLVScreenRecordFileUploadStatus_UploadFailure:
            [self setupStatus:SaicLVScreenRecordStatus_UploadFailure msg:msg];
            break;
        case SaicLVScreenRecordFileUploadStatus_UploadTempFileRemoved:
            [self setupStatus:SaicLVScreenRecordStatus_UploadTempFileRemoved msg:msg];
            break;
        case SaicLVScreenRecordFileUploadStatus_UploadNetworkError:
            [self setupStatus:SaicLVScreenRecordStatus_UploadNetworkError msg:msg];
            break;
        case SaicLVScreenRecordFileUploadStatus_Uploading:
            [self setupStatus:SaicLVScreenRecordStatus_Uploading msg:msg];
            break;
        default:
            break;
    }
}

- (void)setupStatus:(SaicLVScreenRecordStatus)status msg:(NSString *)msg {
    if ([_delegate respondsToSelector:@selector(recordStatus:message:)]) {
        [_delegate recordStatus:status message:msg];
    }
}

@end
