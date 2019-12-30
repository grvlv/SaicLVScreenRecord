//
//  SaicLVScreenRecordConfig.h
//  SaicLVScreenRecordConfig
//
//  Created by GRV on 2019/12/16.
//  Copyright © 2019 GRV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SaicLVScreenRecordConfig : NSObject

//设置录制大小上限，最终合成的mp4会比设置的上限大.5MB左右，如果上限5MB，此参数设置4.3比较好（默认4）
@property (nonatomic) double maxMB;
//视频宽度（默认屏幕宽度）
@property (nonatomic) NSInteger screenRecordWidth;
//视频高度（默认屏幕高度）
@property (nonatomic) NSInteger screenRecordheight;
//视频帧率（默认30帧）
@property (nonatomic) NSInteger videoFrameRate;
//视频码率（码率越小，视频压缩比例越高，也越模糊，默认800000）
@property (nonatomic) NSInteger videoBitRate;
//音频码率（默认24000）
@property (nonatomic) NSInteger audioBitRate;
//音频采样率（默认22050）
@property (nonatomic) NSInteger audioSampleRate;
//音频声道（默认单声道1）
@property (nonatomic) NSInteger audioNumberOfChannels;
//用户id，最终合成mp4文件命名会拼接此id
@property (nonatomic, copy, nullable) NSString *uid;
//上传视频接口
@property (nonatomic, copy, nullable) NSString *uploadURL;
//网络请求头文件
@property (nonatomic, strong, nullable) NSDictionary *headers;

@end

NS_ASSUME_NONNULL_END
