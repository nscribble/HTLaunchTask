//
//  HTAsyncTaskProtocol.h
//  HTLaunchTask
//
//  Created by Jason on 2022/11/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HTAsyncTaskProtocol;

typedef void(^HTLaunchTaskBlock)(UIApplication *application, NSDictionary *launchOptions, void(^completion)(BOOL success));
typedef void(^HTLaunchTaskExecutingCompletionBlock)(id<HTAsyncTaskProtocol> task, BOOL success);

@protocol HTAsyncTaskProtocol <NSObject>

- (void)executeWithApplication:(UIApplication *)application
                 launchOptions:(NSDictionary *)launchOptions
                    completion:(HTLaunchTaskExecutingCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
