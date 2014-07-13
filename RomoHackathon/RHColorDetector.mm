//
//  RHColorDetector.m
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import "RHColorDetector.h"


using namespace cv;
using namespace std;

@interface RHColorDetector () <CvVideoCameraDelegate>

@end

@implementation RHColorDetector

- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoCamera = [[CvVideoCamera alloc] init];
        _videoCamera.delegate = self;
        _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        _videoCamera.defaultFPS = 10;
        _videoCamera.grayscaleMode = NO;
    }
    return self;
}


int iLowH = 170;
int iHighH = 179;

int iLowS = 150;
int iHighS = 255;

int iLowV = 60;
int iHighV = 255;

int iLastX = -1;
int iLastY = -1;


- (void)processImage:(cv::Mat &)imgOriginal {
        Mat imgHSV;
    
    
        cvtColor(imgOriginal, imgHSV, CV_BGR2HSV); //Convert the captured frame from BGR to HSV
        
        Mat imgThresholded;
        
        inRange(imgHSV, Scalar(iLowH, iLowS, iLowV), Scalar(iHighH, iHighS, iHighV), imgThresholded); //Threshold the image
        
        //morphological opening (remove small objects from the foreground)
        erode(imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE,Size2i(5, 5)) );
        dilate( imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, Size2i(5, 5)) );
        //morphological closing (fill small holes in the foreground)
        dilate( imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, Size2i(5, 5)) );
        erode(imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, Size2i(5, 5)) );
    
    
    //Calculate the moments of the thresholded image
    Moments oMoments = moments(imgThresholded);
    
    double dM01 = oMoments.m01;
    double dM10 = oMoments.m10;
    double dArea = oMoments.m00;
    
    // if the area <= 10000, I consider that the there are no object in the image and it's because of the noise, the area is not zero
    
    bool find = false;
    if (dArea > 100)
    {
        //calculate the position of the ball
        int posX = dM10 / dArea;
        int posY = dM01 / dArea;
        
        if (iLastX >= 0 && iLastY >= 0 && posX >= 0 && posY >= 0)
        {
            [self.delegate colorDetector:self didDetectRedAtPoint:CGPointMake(posX, posY) withArea:dArea];
            find = true;
        }
        
        iLastX = posX;
        iLastY = posY;
    }
    if(!find) [self.delegate colorDetectorDidNotDetectColor:self];    
}

@end
