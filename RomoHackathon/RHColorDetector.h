//
//  RHColorDetector.h
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <opencv2/highgui/cap_ios.h>
#import <opencv2/imgproc/imgproc_c.h>

@class RHColorDetector;

@protocol RHColorDetectorProtocol <NSObject>
@property (nonatomic, strong)CvVideoCamera *videoCamera;

- (void)colorDetector:(RHColorDetector *)colorDetector didDetectRedAtPoint:(CGPoint)point withArea:(double)area;

- (void)colorDetectorDidNotDetectColor:(RHColorDetector *)colorDetector;

@end
@interface RHColorDetector : NSObject
@property (nonatomic, strong)CvVideoCamera *videoCamera;
@property(weak, nonatomic)id<RHColorDetectorProtocol>delegate;
@end
