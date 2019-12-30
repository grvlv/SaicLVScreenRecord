//
//  SaicLVScreenRecordWriter.h
//  SaicLVScreenRecordWriter
//
//  Created by GRV on 2019/12/16.
//  Copyright © 2019 GRV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SaicLVScreenRecordConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SaicLVScreenRecordWriterStatus) {
    SaicLVScreenRecordWriterStatus_WriteStart,
    SaicLVScreenRecordWriterStatus_Writing,
    SaicLVScreenRecordWriterStatus_WriteSuccess,
    SaicLVScreenRecordWriterStatus_WriteFailure,
    SaicLVScreenRecordWriterStatus_WriteNext,
    SaicLVScreenRecordWriterStatus_WriteTempFileRemoved
};

@protocol SaicLVScreenRecordWriterDelegate <NSObject>

@optional
- (void)writeStatus:(SaicLVScreenRecordWriterStatus)status message:(NSString *)msg;
- (void)writeCompleted:(SaicLVScreenRecordWriterStatus)status filePath:(NSString *)filePath fileName:(NSString *)fileName writeObj:(id)obj;

@end

@interface SaicLVScreenRecordWriter : NSObject

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) AVAssetWriter *writer;

- (instancetype)initWithConfig:(SaicLVScreenRecordConfig *)config;
- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer type:(RPSampleBufferType)sampleBufferType;
- (void)finishWriting;

@end

NS_ASSUME_NONNULL_END
