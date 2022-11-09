//
//  HTAsyncOperation.m
//  HTLaunchTask
//
//  Created by Jason on 2022/11/4.
//

#import "HTAsyncOperation.h"

@interface HTAsyncOperation ()

@property (nonatomic, assign) BOOL ht_executing;
@property (nonatomic, assign) BOOL ht_finished;

@property (nonatomic, strong, readwrite) id<HTAsyncTaskProtocol> task;

@end

@implementation HTAsyncOperation

- (void)setHt_executing:(BOOL)ht_executing {
    [self willChangeValueForKey:@"isExecuting"];
    _ht_executing = ht_executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setHt_finished:(BOOL)ht_finished {
    [self willChangeValueForKey:@"isFinished"];
    _ht_finished = ht_finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isExecuting {
    return self.ht_executing;
}

- (BOOL)isFinished {
    return self.ht_finished;
}

- (BOOL)isAsynchronous {
    return YES;
}

// MARK: -

+ (instancetype)asyncOperationWithTask:(id<HTAsyncTaskProtocol>)task {
    HTAsyncOperation *operation =  [HTAsyncOperation new];
    operation.task = task;
    
    return operation;
}

// MARK: -

- (void)start {
    NSAssert(self.task != nil, @"AsyncOperation requires a task");
    if ([self isCancelled]) {
        self.ht_finished = YES;
        return;
    }
    
    self.ht_executing = YES;
    __weak typeof(self) ws = self;
    
    if (self.task) {
        [self.task executeWithApplication:[UIApplication sharedApplication]
                            launchOptions:self.launchOptions
                               completion:^(id<HTAsyncTaskProtocol>  _Nonnull task, BOOL success) {
            __strong typeof(ws) ss = ws;
            
            ss.ht_executing = NO;
            ss.ht_finished = YES;
        }];
    }
}


@end
