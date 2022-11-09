//
//  HTLaunchTaskDispatcherProtocol.h
//  HTLaunchTask
//
//  Created by Jason on 2022/11/7.
//

#import <Foundation/Foundation.h>
#import "HTLaunchTaskDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class HTAsyncOperation;
@protocol HTLaunchTaskDispatcherProtocol;

@protocol HTLaunchTaskDispatcherDelegate <NSObject>

@end

@protocol HTLaunchTaskDispatcherProtocol <NSObject>

@property (nonatomic, weak) id<HTLaunchTaskDispatcherDelegate> delegate;

- (void)registerTaskOfClass:(Class)taskClass;

- (void)registerTaskWithBlock:(HTLaunchTaskBlock)block
                     forStage:(HTLaunchStage)stage
                        queue:(HTLaunchTaskQueue)queue;

- (void)onStagePrepare;

- (void)onStageDidFinishLaunch;

- (void)onStageFirstFrameFinished;

@end

NS_ASSUME_NONNULL_END
