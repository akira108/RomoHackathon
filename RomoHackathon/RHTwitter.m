//
//  RHTwitter.m
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import "RHTwitter.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface RHTwitter ()
@property(nonatomic, strong)ACAccountStore *accountStore;
@end

@implementation RHTwitter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

- (void)fetchTweetsWithCompletionBlock:(void (^)(NSArray *tweets))completionBlock {
    //  Step 0: Check that the user has local Twitter accounts
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        
        //  Step 1:  Obtain access to the user's Twitter accounts
        ACAccountType *twitterAccountType = [self.accountStore
                                             accountTypeWithAccountTypeIdentifier:
                                             ACAccountTypeIdentifierTwitter];
        [self.accountStore
         requestAccessToAccountsWithType:twitterAccountType
         options:NULL
         completion:^(BOOL granted, NSError *error) {
             if (granted) {
                 //  Step 2:  Create a request
                 NSArray *twitterAccounts =
                 [self.accountStore accountsWithAccountType:twitterAccountType];
                 NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                               @"/1.1/statuses/user_timeline.json"];
                 NSDictionary *params = @{@"screen_name" : @"ikeay",
                                          @"include_rts" : @"0",
                                          @"trim_user" : @"1",
                                          @"count" : @"10"};
                 SLRequest *request =
                 [SLRequest requestForServiceType:SLServiceTypeTwitter
                                    requestMethod:SLRequestMethodGET
                                              URL:url
                                       parameters:params];
                 
                 //  Attach an account to the request
                 [request setAccount:[twitterAccounts lastObject]];
                 
                 //  Step 3:  Execute the request
                 [request performRequestWithHandler:^(NSData *responseData,
                                                      NSHTTPURLResponse *urlResponse,
                                                      NSError *error) {
                     if (responseData) {
                         if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                             NSError *jsonError;
                             // サンプルではDictionaryだけど、Arrayが戻ってきてる
                             // JSONがArrayだし。
                             NSArray *timelineData =
                             [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:NSJSONReadingAllowFragments error:&jsonError];
//                             NSLog(@"class=%@",[timelineData class]);
                             if (timelineData) {
//                                 NSLog(@"Timeline Response: %@\n", timelineData);
                                 NSString *URLPattern = @"(http://|https://){1}[\\w\\.\\-/:]+";
                                 NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:URLPattern options:0 error:&error];
                                 
                                 NSMutableArray *texts = [NSMutableArray array];
                                 for (NSDictionary *dic in timelineData) {
                                     NSString *text = [dic objectForKey:@"text"];
                                     NSString *str = [regexp stringByReplacingMatchesInString:text
                                                      options:NSMatchingReportProgress
                                                      range:NSMakeRange(0, text.length)
                                                      withTemplate:@""
                                                      ];
                                     
                                     [texts addObject:str];
                                 }
                                 if(completionBlock) {
                                     completionBlock(texts);
                                 }
                             }
                             else {
                                 // Our JSON deserialization went awry
                                 NSLog(@"JSON Error: %@", [jsonError localizedDescription]);
                             }
                         }
                         else {
                             // The server did not respond successfully... were we rate-limited?
                             NSLog(@"The response status code is %d", urlResponse.statusCode);
                         }
                     }
                 }];
             }
             else {
                 // Access was not granted, or an error occurred
                 NSLog(@"%@", [error localizedDescription]);
             }
         }];
    }
}


@end
