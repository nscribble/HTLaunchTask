//
//  HTLaunchManager.h
//  HTLaunchTask
//
//  Created by Jason on 2022/09/24.
//

#import <Foundation/Foundation.h>
#import "HTLaunchTaskDefines.h"
#import "HTLaunchTaskProtocol.h"
#import "HTLaunchTaskDispatcherProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class UIApplication;

typedef void(^HTLaunchWorkerBlock)(UIApplication *application, NSDictionary *launchOptions);

@interface HTLaunchManager : NSObject

// MARK: -

+ (instancetype)shared;

- (void)setTaskDispatcher:(id<HTLaunchTaskDispatcherProtocol>)dispatcher;

// MARK: -

/// 通过类注册启动任务
/// @param taskClass 任务类
- (void)registerTaskOfClass:(Class<HTLaunchTaskProtocol>)taskClass;

/// 通过block注册启动任务
/// @param block 工作闭包
/// @param stage 启动阶段
/// @param queue 队列
- (void)registerTaskWithBlock:(HTLaunchTaskBlock)block
                     forStage:(HTLaunchStage)stage
                        queue:(HTLaunchTaskQueue)queue;

/// 请在appdelgate的didFinishLaunchingWithOptions结束前
/// @param application application
/// @param launchOptions launchOptions
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

@end

NS_ASSUME_NONNULL_END
