//
//  HTTaskLevel0.m
//  HTLaunchTask_Example
//
//  Created by Jason on 2022/11/6.
//  Copyright © 2022 czx. All rights reserved.
//

#import "HTTaskLevel0.h"
@import HTLaunchTask;

@implementation HTTaskLevel0

HTRegisterStartUpTaskFunction() {
    [[HTLaunchManager shared] registerTaskOfClass:HTTaskLevel0.class];
}

- (HTLaunchStage)stage {
    return HTLaunchStagePrepare;
}

- (HTLaunchTaskQueue)queue {
    return HTLaunchTaskMainQueue;
}

- (void)executeWithApplication:(UIApplication *)application
                 launchOptions:(NSDictionary *)launchOptions
                    completion:(HTLaunchTaskExecutingCompletionBlock)completion {
    NSLog(@"⚠️[%@] start executing [%@]", NSStringFromClass(self.class), NSThread.currentThread);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"⚠️[%@] executing finished", NSStringFromClass(self.class));
        completion(self, YES);
    });
}

- (NSArray<Class<HTLaunchTaskProtocol>> *)dependencies {
    return @[];
}

@end
