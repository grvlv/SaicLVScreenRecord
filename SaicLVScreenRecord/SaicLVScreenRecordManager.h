//
//  SaicLVScreenRecordManager.h
//  SaicScreenRecordUpload
//
//  Created by GRV on 2019/12/24.
//  Copyright © 2019 GRV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SaicLVScreenRecordStatus) {
    SaicLVScreenRecordStatus_Default,                   //默认状态
    SaicLVScreenRecordStatus_Unauthorized,              //用户相册未授权
    SaicLVScreenRecordStatus_RecordStart,               //录屏开始
    SaicLVScreenRecordStatus_RecordStop,                //录屏停止
    SaicLVScreenRecordStatus_WriteStart,                //流文件采集开始
    SaicLVScreenRecordStatus_Writing,                   //流文件采集中
    SaicLVScreenRecordStatus_WriteSuccess,              //mp4合成成功
    SaicLVScreenRecordStatus_WriteFailure,              //mp4合成失败
    SaicLVScreenRecordStatus_WriteNext,                 //流文件采集到达设置上限大小，开始新的采集
    SaicLVScreenRecordStatus_WriteTempFileRemoved,      //mp4临时文件删除
    SaicLVScreenRecordStatus_UploadStart,               //文件上传开始
    SaicLVScreenRecordStatus_UploadSuccess,             //文件上传成功
    SaicLVScreenRecordStatus_UploadFailure,             //文件上传失败
    SaicLVScreenRecordStatus_UploadTempFileRemoved,     //文件上传成功后将文件从本地删除
    SaicLVScreenRecordStatus_UploadNetworkError,        //文件上传网络异常
    SaicLVScreenRecordStatus_Uploading                  //文件上传中
};

@protocol SaicLVScreenRecordDelegate <NSObject>

@optional
//获取录屏状态
- (void)recordStatus:(SaicLVScreenRecordStatus)status message:(NSString *)msg;

@end

@interface SaicLVScreenRecordManager : NSObject

@property (nonatomic, weak) id delegate;

+ (instancetype)shared;
//录屏开始前的配置，从SampleHandle同名方法调用
- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *, NSObject *> *)setupInfo;
//录屏暂停和恢复
- (void)broadcastPaused;
- (void)broadcastResumed;
//录屏结束
- (void)broadcastFinished;
//获取流文件
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;

@end

NS_ASSUME_NONNULL_END
