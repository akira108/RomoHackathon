//
//  RHViewController.m
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import "RHViewController.h"
#import <RMCore/RMCore.h>
#import <RMCharacter/RMCharacter.h>
#import "RHAlarmSettingViewController.h"
#import "RHTwitter.h"
#import "RHFaceDetector.h"
#import "RHColorDetector.h"
#import <AVFoundation/AVFoundation.h>

@interface RHViewController () <RMCoreDelegate, RHAlarmSettinViewControllerDelegate, AVSpeechSynthesizerDelegate, RHColorDetectorProtocol>
@property (nonatomic, strong) RMCoreRobot<HeadTiltProtocol, DriveProtocol, LEDProtocol> *robot;
@property (nonatomic, strong) RMCharacter *romo;
@property (weak, nonatomic) IBOutlet UIView *romoView;
@property (nonatomic, strong)NSTimer *dateTimer;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)NSUInteger tick;
@property (weak, nonatomic) IBOutlet UILabel *hourLabel;
@property (weak, nonatomic) IBOutlet UILabel *minuteLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UIView *alarmSettingContainer;
@property (nonatomic, assign) CGRect alarmSettingContainerFrame;

@property (nonatomic, strong) NSDate *alarmDate;

@property (weak, nonatomic) IBOutlet UIButton *wakeUpButton;
@property (weak, nonatomic) IBOutlet UIButton *alarmCancelButton;
@property (weak, nonatomic) IBOutlet UIButton *alarmButton;
@property (nonatomic, strong) UIView *darkenView;

@property (nonatomic, strong) NSArray *tweets;
@property (nonatomic, strong) AVSpeechSynthesizer* speechSynthesizer;

//@property (nonatomic, strong) RHFaceDetector *faceDetector;
@property (nonatomic, strong) RHColorDetector *colorDetector;

@property (nonatomic, assign) NSUInteger tweetCount;

@property (nonatomic, assign, getter = isWakingUp) BOOL wakingUp;
@end

@implementation RHViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [RMCore setDelegate:self];
    self.romo = [RMCharacter Romo];
	// Do any additional setup after loading the view, typically from a nib.
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(romoViewDidTap:)];
    
    UITapGestureRecognizer *tripleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTripleTap:)];
    tripleTapRecognizer.numberOfTapsRequired = 3;
    
    [self.romoView addGestureRecognizer:tapRecognizer];
    [self.romoView addGestureRecognizer:tripleTapRecognizer];
    
    // timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy/MM/dd"];
    
    self.alarmSettingContainer.hidden = NO;
    self.alarmSettingContainerFrame = self.alarmSettingContainer.frame;
    
    self.alarmSettingContainer.frame = ({
        CGRect frame = self.alarmSettingContainer.frame;
        frame = CGRectOffset(frame, 0.0f, CGRectGetHeight(frame));
        frame;
    });
    
    self.darkenView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.darkenView.userInteractionEnabled = NO;
    self.darkenView.backgroundColor = [UIColor colorWithRed:0.012 green:0.012 blue:0.075 alpha:1.000];
    self.darkenView.alpha = 0.0f;
    [self.view insertSubview:self.darkenView belowSubview:self.alarmCancelButton];
    
    
    self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    self.speechSynthesizer.delegate = self;

//    self.faceDetector = [[RHFaceDetector alloc] init];
//    self.faceDetector.delegate = self;
//    [self.faceDetector setupAVCapture];
    
    self.colorDetector = [[RHColorDetector alloc] init];
    self.colorDetector.delegate = self;
    
    RHTwitter *twitter = [[RHTwitter alloc] init];
    
    __weak __typeof(self) self_ = self;
    [twitter fetchTweetsWithCompletionBlock:^(NSArray *tweets) {
        NSLog(@"tweets = %@", tweets);
        self_.tweets = tweets;
    }];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Embed"])
    {
        UINavigationController *navController = segue.destinationViewController;
        RHAlarmSettingViewController *alarmSettingViewController = [navController.viewControllers firstObject];
        alarmSettingViewController.delegate = self;
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.romo addToSuperview:self.romoView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.romo.expression = RMCharacterExpressionExcited;

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.romo removeFromSuperview];
    [self.colorDetector.videoCamera stop];
}

#pragma mark - Alarm

- (void)alarmSettingViewControllerCancelled:(RHAlarmSettingViewController *)alarmSettingController {
    [self hideAlarmSetting];
}

- (void)alarmSettingViewController:(RHAlarmSettingViewController *)alarmSettingController doneWithDuration:(NSTimeInterval)duration {
    
    self.alarmButton.alpha = 0.0f;
    self.alarmCancelButton.alpha = 1.0f;
    self.alarmDate = [NSDate dateWithTimeIntervalSinceNow:duration];
    [self hideAlarmSetting];
    self.romo.emotion = RMCharacterEmotionSleepy;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.romo.emotion = RMCharacterEmotionSleeping;
    });
    
    [UIView animateWithDuration:3.0f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.darkenView.alpha = 0.8;
    } completion:^(BOOL finished) {
    }];
}

- (void)wakeupAnimation {
    [UIView animateWithDuration:0.3 animations:^{
        self.alarmDate = nil;
        self.darkenView.alpha = 0.0f;
        if(self.wakingUp) {
            self.alarmCancelButton.alpha = 0.0f;
            self.alarmButton.alpha = 0.0f;
            self.wakeUpButton.alpha = 1.0f;
        } else {
            self.alarmCancelButton.alpha = 0.0f;
            self.alarmButton.alpha = 1.0f;
            self.wakeUpButton.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        self.romo.emotion = RMCharacterEmotionHappy;
    }];
}
- (IBAction)cancelAlarmAction:(id)sender {
    [self wakeupAnimation];
}

- (IBAction)alarmSettingAction:(id)sender {
    [self showAlarmSetting];
}

-(void)showAlarmSetting {
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.95 initialSpringVelocity:20.0 options:kNilOptions animations:^{
        self.alarmSettingContainer.frame = self.alarmSettingContainerFrame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideAlarmSetting {
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.95 initialSpringVelocity:20.0 options:kNilOptions animations:^{
        self.alarmSettingContainer.frame = ({
            CGRect frame = self.alarmSettingContainer.frame;
            frame = CGRectOffset(frame, 0.0f, CGRectGetHeight(frame));
            frame;
        });
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark Clock
    
- (NSString *)timeStringWithTimeInteger:(NSInteger)time {
    NSString *string = [NSString stringWithFormat:@"%02d", time];
    return string;
}

- (void)updateClock {
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps;
    
    self.dateLabel.text = [self.dateFormatter stringFromDate:date];
    
    // 時分秒をとりだす
    comps = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
                        fromDate:date];
    NSInteger hour = [comps hour];
    NSInteger minute = [comps minute];
    NSInteger second = [comps second];
    
    self.hourLabel.text = [self timeStringWithTimeInteger:hour];
    self.minuteLabel.text = [self timeStringWithTimeInteger:minute];
    self.secondLabel.text = [self timeStringWithTimeInteger:second];
}

- (void)updateRomo {
    RMPoint3D point;
    if(self.tick%2 == 0) {
        point =RMPoint3DMake(-1.0, 0.0, 0.5);
    } else {
        point = RMPoint3DMake(1.0, 0.0, 0.5);
    }
    [self.romo lookAtPoint:point animated:YES];
}

- (void)speechString:(NSString *)string {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja-JP"];
    utterance.voice = voice;
    utterance.preUtteranceDelay = 0.2f;
    utterance.rate = 0.4;
    utterance.pitchMultiplier = 2.0f;
    
    // AVSpeechSynthesizerにAVSpeechUtteranceを設定して読んでもらう
    [self.speechSynthesizer speakUtterance:utterance];
}
- (void)beginSpeechingTweets {
    self.tweetCount = 0;
    [self speechTweet];
}

- (void)speechTweet {
    NSString* speakingText = self.tweets[self.tweetCount];
    [self speechString:speakingText];
}

- (IBAction)wakedUpAction:(id)sender {
    [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    self.wakingUp = NO;
    [self wakeupAnimation];
    [self.colorDetector.videoCamera stop];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.tweetCount++;
    if(self.tweetCount == [self.tweets count] || !self.isWakingUp) {
        return;
    }
    [self speechTweet];
}

- (void)wakeUpIfNeeded {
    if(!self.alarmDate) return;
    
    NSComparisonResult result = [[NSDate date] compare:self.alarmDate];
    
    if(result == NSOrderedDescending) {
        // wake up!!!
        self.wakingUp = YES;
        [self.colorDetector.videoCamera start];
        [self beginSpeechingTweets];
        [self wakeupAnimation];
        self.romo.emotion = RMCharacterEmotionCurious;
        self.romo.expression = RMCharacterExpressionExcited;
    }
}

- (void)onTimer:(NSTimer *)timer {
    [self updateRomo];
    [self updateClock];
    [self wakeUpIfNeeded];
    self.tick++;
}

#pragma mark Gesture Recognizer 

- (void)romoViewDidTap:(UITapGestureRecognizer *)tapRecognizer {
    if(self.alarmDate) return;
    [self.romo mumble];
}

- (void)handleTripleTap:(UITapGestureRecognizer *)tapRecognizer {
    self.alarmDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
}

#pragma mark - Romo Delegate
- (void)robotDidConnect:(RMCoreRobot *)robot {
    if(robot.isDrivable && robot.isHeadTiltable && robot.isLEDEquipped) {
        self.robot = (RMCoreRobot<HeadTiltProtocol, DriveProtocol, LEDProtocol> *)robot;
        [self.robot turnByAngle:90.0 withRadius:RM_DRIVE_RADIUS_TURN_IN_PLACE completion:nil];
    }
}

- (void)robotDidDisconnect:(RMCoreRobot *)robot {
    if(robot == self.robot) {
        self.robot = nil;
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - move Romo
#define AREA_THRESHOLD (500000)
#define AREA_THRESHOLD_WIDTH (200000)

- (void)colorDetectorDidNotDetectColor:(RHColorDetector *)colorDetector {
    if(!self.robot.isDrivable) return;
    [self.robot stopDriving];
}

- (void)colorDetector:(RHColorDetector *)colorDetector didDetectRedAtPoint:(CGPoint)point withArea:(double)area {
    NSLog(@"area = %lf, at (%f, %f)", area, point.x, point.y);
    if(!self.robot.isDrivable) return;
    if(area > AREA_THRESHOLD - AREA_THRESHOLD_WIDTH && area < AREA_THRESHOLD + AREA_THRESHOLD_WIDTH) {
        [self.robot stopDriving];
        return;
    }
    if (area > AREA_THRESHOLD) {
        self.romo.emotion = RMCharacterExpressionScared;
        [self.robot driveBackwardWithSpeed:0.8];
    } else {
        self.romo.emotion = RMCharacterExpressionSmack;
        [self.robot driveForwardWithSpeed:1.2];
    }
}

//- (void)faceDetectordidNotDetectFace:(RHFaceDetector *)faceDetector {
//    if(!self.robot.isDrivable) return;
//    [self.robot stopDriving];
//}
//
//- (void)faceDetector:(RHFaceDetector *)faceDetector didDetectFaceAtRegion:(CGRect)rect {
//    CGFloat area = CGRectGetWidth(rect) * CGRectGetHeight(rect);
//    NSLog(@"area = %f", area);
//    
//    if(!self.robot.isDrivable) return;
//    if(area > AREA_THRESHOLD - AREA_THRESHOLD_WIDTH && area < AREA_THRESHOLD + AREA_THRESHOLD_WIDTH) {
//        [self.robot stopDriving];
//        return;
//    }
//    if (area > AREA_THRESHOLD) {
//        [self.robot driveBackwardWithSpeed:0.5];
//    } else {
//        [self.robot driveForwardWithSpeed:0.5];
//    }
//}
//
//- (void)proximitySensorStateDidChange:(NSNotification *)notification
//{
//    if(!self.robot.isDrivable) return;
//    if([UIDevice currentDevice].proximityState) {
//        RMCharacterExpression expression = self.romo.expression;
//        self.romo.emotion = RMCharacterExpressionScared;;
//        [self.robot driveBackwardWithSpeed:0.5];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.robot stopDriving];
//            self.romo.expression = expression;
//        });
//    }
//}
@end
