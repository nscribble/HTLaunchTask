//
//  HTLaunchTaskProtocol.h
//  HTLaunchTask
//
//  Created by Jason on 2022/09/24.
//

#import <Foundation/Foundation.h>
#import "HTLaunchTaskDefines.h"
#import "HTAsyncTaskProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HTLaunchTaskProtocol <HTAsyncTaskProtocol>

/// 指定执行的启动阶段
- (HTLaunchStage)stage;

/// 任务执行队列类型
- (HTLaunchTaskQueue)queue;

/// 任务优先级
/// @note 排在ConcurrentQueue的任务无需指定优先级
/// @note 有依赖关系的任务请勿使用优先级表达依赖关系，以免形成优先级反转
- (HTLaunchTaskPriority)priority;

/// 依赖任务
- (NSArray<Class<HTLaunchTaskProtocol>> *)dependencies;

@end



NS_ASSUME_NONNULL_END
