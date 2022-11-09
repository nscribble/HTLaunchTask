//
//  HTLaunchTask.m
//  HTLaunchTask
//
//  Created by Jason on 2022/09/24.
//

#import "HTLaunchTask.h"

@interface HTLaunchTask ()

@end

@implementation HTLaunchTask

- (HTLaunchStage)stage {
    NSAssert(NO, @"⚠️请指定任务执行的启动阶段: %@", self);
    return HTLaunchStageNothing;
}

- (HTLaunchTaskQueue)queue {
    return HTLaunchTaskMainQueue;
}

- (HTLaunchTaskPriority)priority {
    return HTLaunchTaskPriorityDefault;
}

- (NSArray<Class<HTLaunchTaskProtocol>> *)dependencies {
    return nil;
}

// MARK: -

- (void)executeWithApplication:(UIApplication *)application
                 launchOptions:(NSDictionary *)launchOptions
                    completion:(HTLaunchTaskExecutingCompletionBlock)completion {
    !completion ?: completion(self, NO);
}


@end
