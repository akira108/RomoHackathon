//
//  RHAlarmSettingViewController.h
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RHAlarmSettingViewController;

@protocol RHAlarmSettinViewControllerDelegate <NSObject>

- (void)alarmSettingViewControllerCancelled:(RHAlarmSettingViewController *)alarmSettingController;
- (void)alarmSettingViewController:(RHAlarmSettingViewController *)alarmSettingController doneWithDuration:(NSTimeInterval)duration;

@end

@interface RHAlarmSettingViewController : UIViewController
@property (nonatomic, weak)id<RHAlarmSettinViewControllerDelegate> delegate;

@end
