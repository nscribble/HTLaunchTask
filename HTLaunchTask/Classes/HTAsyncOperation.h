//
//  HTAsyncOperation.h
//  HTLaunchTask
//
//  Created by Jason on 2022/11/4.
//

#import <Foundation/Foundation.h>
#import "HTAsyncTaskProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HTLaunchTaskProtocol;

@interface HTAsyncOperation : NSOperation

@property (nonatomic, strong, readonly) id<HTAsyncTaskProtocol> task;

@property (nonatomic, strong) NSDictionary  *launchOptions;

+ (instancetype)asyncOperationWithTask:(id<HTAsyncTaskProtocol>)task;

@end

NS_ASSUME_NONNULL_END
