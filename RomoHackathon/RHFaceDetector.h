//
//  RHFaceDetector.h
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class RHFaceDetector;

@protocol RHFaceDetectorDelegate <NSObject>

- (void)faceDetector:(RHFaceDetector *)faceDetector didDetectFaceAtRegion:(CGRect)rect;

- (void)faceDetectordidNotDetectFace:(RHFaceDetector *)faceDetector;

@end
@interface RHFaceDetector : NSObject <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

- (void)setupAVCapture;
- (void)teardownAVCapture;

@property(nonatomic, weak)id<RHFaceDetectorDelegate> delegate;


@end
