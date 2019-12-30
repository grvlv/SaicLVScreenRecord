//
//  SaicLVScreenRecordWriter.m
//  SaicLVScreenRecordWriter
//
//  Created by GRV on 2019/12/16.
//  Copyright © 2019 GRV. All rights reserved.
//

#import "SaicLVScreenRecordWriter.h"

@interface SaicLVScreenRecordWriter()

@property (nonatomic, weak) SaicLVScreenRecordConfig *config;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriterInput *micInput;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *tempFilePath;

@end

@implementation SaicLVScreenRecordWriter

- (instancetype)initWithConfig:(SaicLVScreenRecordConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        [self setupAsset];
    }
    return self;
}

- (void)setupAsset {
    _filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SaicLVScreenRecord"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:_filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd-HHmmss";
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    _fileName = [NSString stringWithFormat:@"%@_%@.mp4", dateStr, _config.uid];
    NSString *file = [_filePath stringByAppendingPathComponent:_fileName];
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];

    _writer = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:file] fileType:AVFileTypeMPEG4 error:nil];

    NSMutableDictionary *videoCompression = [[NSMutableDictionary alloc] init];
    videoCompression[AVVideoAverageBitRateKey] = @(_config.videoBitRate);
    videoCompression[AVVideoExpectedSourceFrameRateKey] = @(_config.videoFrameRate);
    videoCompression[AVVideoMaxKeyFrameIntervalKey] = @(_config.videoFrameRate);
    videoCompression[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel;

    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
    videoSettings[AVVideoWidthKey] = @(_config.screenRecordWidth);
    videoSettings[AVVideoHeightKey] = @(_config.screenRecordheight);
    videoSettings[AVVideoCodecKey] = AVVideoCodecTypeH264;
    videoSettings[AVVideoCompressionPropertiesKey] = videoCompression;
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    _videoInput.expectsMediaDataInRealTime = YES;
    _videoInput.transform = CGAffineTransformIdentity;

    NSDictionary *audioSettings = @{AVEncoderBitRatePerChannelKey : @(_config.audioBitRate), AVFormatIDKey : @(kAudioFormatMPEG4AAC), AVNumberOfChannelsKey : @(_config.audioNumberOfChannels), AVSampleRateKey : @(_config.audioSampleRate)};
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    _audioInput.expectsMediaDataInRealTime = YES;

    _micInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    _micInput.expectsMediaDataInRealTime = YES;

    if (_videoInput && [_writer canAddInput:_videoInput]) {
        [_writer addInput:_videoInput];
    }
    if (_audioInput && [_writer canAddInput:_audioInput]) {
        [_writer addInput:_audioInput];
    }
    if (_micInput && [_writer canAddInput:_micInput]) {
        [_writer addInput:_micInput];
    }
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer type:(RPSampleBufferType)sampleBufferType {
    if (_writer.status == AVAssetWriterStatusUnknown) {
        if ([_writer startWriting]) {
            CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startSessionAtSourceTime:timestamp];
            [self setupStatus:SaicLVScreenRecordWriterStatus_WriteStart msg:[NSString stringWithFormat:@"开始写文件 = %@", _fileName]];
        } else {
            return;
        }
    }
    if (_writer.status == AVAssetWriterStatusFailed) {
        return;
    }
    if (_writer.status == AVAssetWriterStatusCancelled) {
        return;
    }
    if (_writer.status == AVAssetWriterStatusCompleted) {
        return;
    }
    if (_writer.status == AVAssetWriterStatusWriting) {
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
        if (duration.value > 0) {
            timestamp = CMTimeAdd(timestamp, duration);
        }
        
        if (sampleBufferType == RPSampleBufferTypeVideo) {
            if (_videoInput.readyForMoreMediaData) {
                if ([_videoInput appendSampleBuffer:sampleBuffer]) {
                    [self checkFileSize];
                }
            }
        } else if (sampleBufferType == RPSampleBufferTypeAudioApp) {
            if (_audioInput.readyForMoreMediaData) {
                if ([_audioInput appendSampleBuffer:sampleBuffer]) {
                    [self checkFileSize];
                }
            }
        } else if (sampleBufferType == RPSampleBufferTypeAudioMic) {
            if (_micInput.readyForMoreMediaData) {
                if ([_micInput appendSampleBuffer:sampleBuffer]) {
                    [self checkFileSize];
                }
            }
        }
    }
}

- (void)checkFileSize {
    NSString *file = [_filePath stringByAppendingPathComponent:_fileName];
    NSInteger fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil].fileSize;
    double mb = fileSize / 1024.0f / 1024.0f;
//    [self setupStatus:SaicLVScreenRecordWriterStatus_Writing msg:[NSString stringWithFormat:@"%.2fMB", mb]];
    if (mb > _config.maxMB) {
        [self setupStatus:SaicLVScreenRecordWriterStatus_WriteNext msg:@"开始下一个"];
        if ([_delegate respondsToSelector:@selector(writeCompleted:filePath:fileName:writeObj:)]) {
            [_delegate writeCompleted:SaicLVScreenRecordWriterStatus_WriteNext filePath:_filePath fileName:_fileName writeObj:self];
        }
        [self finishWriting];
    }
}

- (void)finishWriting {
    if (_writer.status == AVAssetWriterStatusUnknown || _writer.status == AVAssetWriterStatusCompleted) {
        [self setupStatus:SaicLVScreenRecordWriterStatus_WriteFailure msg:[NSString stringWithFormat:@"写文件失败 = %@", _fileName]];
        if ([_delegate respondsToSelector:@selector(writeCompleted:filePath:fileName:writeObj:)]) {
            [_delegate writeCompleted:SaicLVScreenRecordWriterStatus_WriteFailure filePath:_filePath fileName:_fileName writeObj:self];
        }
        [self removeFile];
        return;
    }
    [_videoInput markAsFinished];
    [_audioInput markAsFinished];
    [_micInput markAsFinished];
    __weak typeof(self) weakSelf = self;
    [_writer finishWritingWithCompletionHandler:^{
        [weakSelf setupStatus:SaicLVScreenRecordWriterStatus_WriteSuccess msg:[NSString stringWithFormat:@"写文件成功 = %@", weakSelf.fileName]];
        NSString *file = [weakSelf.filePath stringByAppendingPathComponent:weakSelf.fileName];
        [weakSelf saveVideo:file];
        if ([weakSelf.delegate respondsToSelector:@selector(writeCompleted:filePath:fileName:writeObj:)]) {
            [weakSelf.delegate writeCompleted:SaicLVScreenRecordWriterStatus_WriteSuccess filePath:weakSelf.filePath fileName:weakSelf.fileName writeObj:weakSelf];
        }
    }];
}

- (void)removeFile {
    NSString *file = [_filePath stringByAppendingPathComponent:_fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
        [self setupStatus:SaicLVScreenRecordWriterStatus_WriteTempFileRemoved msg:[NSString stringWithFormat:@"删除临时文件 = %@", _fileName]];
    }
}

- (void)saveVideo:(NSString *)videoPath {
    UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
}

- (void)setupStatus:(SaicLVScreenRecordWriterStatus)status msg:(NSString *)msg {
    if ([_delegate respondsToSelector:@selector(writeStatus:message:)]) {
        [_delegate writeStatus:status message:msg];
    }
}

@end
