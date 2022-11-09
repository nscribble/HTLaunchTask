//
//  HTLaunchBlockTask.m
//  HTLaunchTask
//
//  Created by Jason on 2022/11/6.
//

#import "HTLaunchBlockTask.h"

@interface HTLaunchBlockTask ()

@property (nonatomic, copy) HTLaunchTaskBlock taskBlock;
@property (nonatomic, assign) HTLaunchStage stage;
@property (nonatomic, assign) HTLaunchTaskQueue queue;

@end

@implementation HTLaunchBlockTask

+ (instancetype)taskWithBlock:(HTLaunchTaskBlock)taskBlock
                     forStage:(HTLaunchStage)stage
                        queue:(HTLaunchTaskQueue)queue {
    HTLaunchBlockTask *task = [HTLaunchBlockTask new];
    task.taskBlock = taskBlock;
    task.stage = stage;
    task.queue = queue;
    
    return task;
}

// MARK: -



// MARK: -

- (void)executeWithApplication:(UIApplication *)application launchOptions:(NSDictionary *)launchOptions completion:(HTLaunchTaskExecutingCompletionBlock)completion {
    NSAssert(self.taskBlock != nil, @"⚠️taskBlock should not be nil!");
    if (!self.taskBlock) {
        completion(self, NO);
        return;
    }
    
    __weak typeof(self) ws = self;
    self.taskBlock(application, launchOptions, ^(BOOL success) {
        __strong typeof(ws) ss = ws;
        !completion ?: completion(ss, success);
    });
}

@end
