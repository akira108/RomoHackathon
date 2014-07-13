//
//  RHAlarmSettingViewController.m
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import "RHAlarmSettingViewController.h"

@interface RHAlarmSettingViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end

@implementation RHAlarmSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents * components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSDate * date = [cal dateFromComponents:components];
    [self.datePicker setDate:date animated:YES];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelAction:(id)sender {
    [self.delegate alarmSettingViewControllerCancelled:self];
}

- (IBAction)doneAction:(id)sender {
    [self.delegate alarmSettingViewController:self doneWithDuration:self.datePicker.countDownDuration];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
