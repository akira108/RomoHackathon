//
//  RHTwitter.h
//  RomoHackathon
//
//  Created by Akira Iwaya on 2014/07/13.
//  Copyright (c) 2014年 akira108. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RHTwitter : NSObject

- (void)fetchTweetsWithCompletionBlock:(void (^)(NSArray *tweets))completionBlock;

@end
