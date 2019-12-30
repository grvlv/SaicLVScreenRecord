//
//  SaicLVScreenRecordFileUpload.m
//  SaicScreenRecordUpload
//
//  Created by GRV on 2019/12/23.
//  Copyright © 2019 GRV. All rights reserved.
//

#import "SaicLVScreenRecordFileUpload.h"
#import <AFNetworking/AFNetworking.h>

@interface SaicLVScreenRecordFileUpload()

@property (nonatomic) BOOL isUploading;
@property (nonatomic, copy) NSString *uploadURL;
@property (nonatomic, strong) NSString *plistPath;
@property (nonatomic, strong) NSMutableDictionary *rootDic;
@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation SaicLVScreenRecordFileUpload

+ (instancetype)shared {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SaicLVScreenRecordFileUpload alloc] init];
        [instance configRootDic];
        [instance configNetwork];
    });
    return instance;
}

- (void)configRootDic {
    _rootDic = [[NSMutableDictionary alloc] init];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SaicLVScreenRecord"];
    NSArray *fileArray = [[NSFileManager defaultManager] subpathsAtPath:filePath];
    for (NSString *fileName in fileArray) {
        NSString *file = [filePath stringByAppendingPathComponent:fileName];
        [_rootDic setValue:file forKey:fileName];
    }
}

- (void)configNetwork {
    _manager = [AFHTTPSessionManager manager];
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    _manager.requestSerializer.timeoutInterval = 30;
    
    __weak typeof(self) weakSelf = self;
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [weakSelf uploadFile];
                break;
            default:
                break;
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)stopAFMonitoring {
    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
}

- (void)configUploadURL:(NSString *)url {
    _uploadURL = url;
}

- (void)configHearders:(NSDictionary *)headers {
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [_manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
}

- (void)setupFilePath:(NSString *)filePath fileName:(NSString *)fileName {
    NSString *file = [filePath stringByAppendingPathComponent:fileName];
    [_rootDic setValue:file forKey:fileName];
    [self uploadFile];
}

- (void)uploadFile {
    if (![self checkNetwork] || !_rootDic.count) {
        return;
    }
    NSArray *allKeys = _rootDic.allKeys;
    allKeys = [allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    NSString *fileName = allKeys.lastObject;
    NSString *file = _rootDic[fileName];
    [self uploadFile:file fileName:fileName];
}

- (BOOL)checkNetwork {
    if (![AFNetworkReachabilityManager sharedManager].reachable) {
        [self setupStatus:SaicLVScreenRecordFileUploadStatus_UploadNetworkError msg:@"网络异常"];
        return NO;
    }
    if (_isUploading) {
        [self setupStatus:SaicLVScreenRecordFileUploadStatus_Uploading msg:@"上传中..."];
        return NO;
    }
    return YES;
}

- (void)uploadFile:(NSString *)file fileName:(NSString *)fileName {
    if (!_uploadURL.length || _isUploading) {
        return;
    }
    [self setupStatus:SaicLVScreenRecordFileUploadStatus_UploadStart msg:[NSString stringWithFormat:@"开始上传 = %@", fileName]];
    _isUploading = YES;
    NSData *data = [NSData dataWithContentsOfFile:file];
    if (!data) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [_manager POST:_uploadURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"" fileName:fileName mimeType:@"video/mp4"];
    } progress:^(NSProgress *uploadProgress) {

    } success:^(NSURLSessionDataTask *task, id responseObject) {
        [weakSelf setupStatus:SaicLVScreenRecordFileUploadStatus_UploadSuccess msg:[NSString stringWithFormat:@"上传成功 = %@，文件大小 = %.2fMB", fileName, data.length / 1024.0f / 1024.0f]];
        weakSelf.isUploading = NO;
        [weakSelf.rootDic removeObjectForKey:fileName];
        [weakSelf removeFile:file];
        [weakSelf uploadFile];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf setupStatus:SaicLVScreenRecordFileUploadStatus_UploadFailure msg:[NSString stringWithFormat:@"上传失败 = %@，文件大小 = %.2fMB，error msg = %@", fileName, data.length / 1024.0f / 1024.0f, error.localizedDescription]];
        weakSelf.isUploading = NO;
        [weakSelf uploadFile];
    }];
}

- (void)removeFile:(NSString *)file {
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        if ([[NSFileManager defaultManager] removeItemAtPath:file error:nil]) {
            [self setupStatus:SaicLVScreenRecordFileUploadStatus_UploadTempFileRemoved msg:[NSString stringWithFormat:@"删除文件 = %@", file]];
        }
    }
}

- (void)setupStatus:(SaicLVScreenRecordFileUploadStatus)status msg:(NSString *)msg {
    if ([_delegate respondsToSelector:@selector(uploadStatus:message:)]) {
        [_delegate uploadStatus:status message:msg];
    }
}

@end
