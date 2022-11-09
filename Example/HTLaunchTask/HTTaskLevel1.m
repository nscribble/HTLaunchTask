//
//  HTTaskLevel1.m
//  HTLaunchTask_Example
//
//  Created by Jason on 2022/11/6.
//  Copyright © 2022 czx. All rights reserved.
//

#import "HTTaskLevel1.h"
#import "HTTaskLevel0.h"
@import HTLaunchTask;

@implementation HTTaskLevel1

HTRegisterStartUpTaskFunction() {
    [[HTLaunchManager shared] registerTaskOfClass:HTTaskLevel1.class];
}

- (HTLaunchStage)stage {
    return HTLaunchStageDidFinishLaunching;
}

- (HTLaunchTaskQueue)queue {
    return HTLaunchTaskMainQueue;
}

- (void)executeWithApplication:(UIApplication *)application
                 launchOptions:(NSDictionary *)launchOptions
                    completion:(HTLaunchTaskExecutingCompletionBlock)completion {
    NSLog(@"⚠️[%@] start executing [%@]", NSStringFromClass(self.class), NSThread.currentThread);
    NSLog(@"⚠️[%@] executing finished", NSStringFromClass(self.class));
    completion(self, YES);
}

- (NSArray<Class<HTLaunchTaskProtocol>> *)dependencies {
    return @[HTTaskLevel0.class];
}

@end
