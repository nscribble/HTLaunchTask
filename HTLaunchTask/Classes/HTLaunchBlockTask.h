//
//  HTLaunchBlockTask.h
//  HTLaunchTask
//
//  Created by Jason on 2022/11/6.
//

#import <HTLaunchTask/HTLaunchTask.h>

NS_ASSUME_NONNULL_BEGIN

@interface HTLaunchBlockTask : HTLaunchTask

+ (instancetype)taskWithBlock:(HTLaunchTaskBlock)taskBlock
                     forStage:(HTLaunchStage)stage
                        queue:(HTLaunchTaskQueue)queue;

@end

NS_ASSUME_NONNULL_END
