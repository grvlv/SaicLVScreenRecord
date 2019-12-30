//
//  SaicLVScreenRecordConfig.m
//  SaicLVScreenRecordConfig
//
//  Created by GRV on 2019/12/16.
//  Copyright © 2019 GRV. All rights reserved.
//

#import "SaicLVScreenRecordConfig.h"
#import <UIKit/UIKit.h>

@implementation SaicLVScreenRecordConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        _maxMB = 4.0f;
        _screenRecordWidth = size.width;
        _screenRecordheight = size.height;
        _videoFrameRate = 30;
        _videoBitRate = 800000;
        _audioBitRate = 24000;
        _audioSampleRate = 22050;
        _audioNumberOfChannels = 1;
    }
    return self;
}

- (void)setMaxMB:(double)maxMB {
    _maxMB = 4.5f;
    if (maxMB) {
        _maxMB = maxMB;
    }
}

- (void)setScreenRecordWidth:(NSInteger)screenRecordWidth {
    _screenRecordWidth = [UIScreen mainScreen].bounds.size.width;
    if (screenRecordWidth) {
        _screenRecordWidth = screenRecordWidth;
    }
}

- (void)setScreenRecordheight:(NSInteger)screenRecordheight {
    _screenRecordheight = [UIScreen mainScreen].bounds.size.height;
    if (screenRecordheight) {
        _screenRecordheight = screenRecordheight;
    }
}

- (void)setVideoFrameRate:(NSInteger)videoFrameRate {
    _videoFrameRate = 30;
    if (videoFrameRate) {
        _videoFrameRate = videoFrameRate;
    }
}

- (void)setVideoBitRate:(NSInteger)videoBitRate {
    _videoBitRate = 800000;
    if (videoBitRate) {
        _videoBitRate = videoBitRate;
    }
}

- (void)setAudioBitRate:(NSInteger)audioBitRate {
    _audioBitRate = 24000;
    if (audioBitRate) {
        _audioBitRate = audioBitRate;
    }
}

- (void)setAudioSampleRate:(NSInteger)audioSampleRate {
    _audioSampleRate = 22050;
    if (audioSampleRate) {
        _audioSampleRate = audioSampleRate;
    }
}

- (void)setAudioNumberOfChannels:(NSInteger)audioNumberOfChannels {
    _audioNumberOfChannels = 1;
    if (audioNumberOfChannels) {
        _audioNumberOfChannels = audioNumberOfChannels;
    }
}

@end
