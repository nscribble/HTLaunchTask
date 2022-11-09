//
//  HTLaunchManager.m
//  HTLaunchTask
//
//  Created by Jason on 2022/09/24.
//

#import "HTLaunchManager.h"
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/getsect.h>
#import <objc/runtime.h>
#import <os/lock.h>

#import "HTLaunchTaskProtocol.h"
#import "HTLaunchTaskDispatcherProtocol.h"
#import "HTAsyncOperation.h"
#import "HTLaunchBlockTask.h"

NSInteger const HTLaunchTaskPriorityLow = 0;
NSInteger const HTLaunchTaskPriorityDefault = 200;
NSInteger const HTLaunchTaskPriorityHigh = 1000;

/// todo: dag.
@interface HTLaunchTaskDispatcher : NSObject<HTLaunchTaskDispatcherProtocol>

@property (nonatomic, strong) NSOperationQueue *asyncQueue;
@property (nonatomic, strong) NSOperationQueue *mainQueue;

@property (nonatomic, strong) NSDictionary *launchOptions;

@property (nonatomic, strong) NSMutableSet<HTAsyncOperation *> *prepareOperations;
@property (nonatomic, strong) NSMutableSet<HTAsyncOperation *> *didFinishLaunchOperations;
@property (nonatomic, strong) NSMutableSet<HTAsyncOperation *> *afterFirstFrameOperations;

@property (nonatomic, strong) NSMutableDictionary<NSString *, HTAsyncOperation *> *task2Operations;
@property (nonatomic, strong) NSMapTable<NSString *, HTAsyncOperation *> *task2OperationsMap;
@property (nonatomic, strong) NSMapTable<NSString *, id<HTLaunchTaskProtocol>> *cls2TaskMap;

@end

@implementation HTLaunchTaskDispatcher

@synthesize delegate;

// MARK: - Registering Task

- (void)registerTaskWithBlock:(HTLaunchTaskBlock)block
                     forStage:(HTLaunchStage)stage
                        queue:(HTLaunchTaskQueue)queue {
    HTLaunchBlockTask *task = [HTLaunchBlockTask taskWithBlock:block forStage:stage queue:queue];
    HTAsyncOperation *operation = [HTAsyncOperation asyncOperationWithTask:task];
    operation.launchOptions = self.launchOptions;
    
    [self addOperation:operation forStage:stage];
}

- (void)registerTaskOfClass:(Class)taskClass {
    NSString *key = NSStringFromClass(taskClass);
    id<HTLaunchTaskProtocol> task = [self addTaskOfClass:taskClass];
    HTAsyncOperation *operation = [self.task2OperationsMap objectForKey:key];
    
    [self addOperation:operation forStage:task.stage];
}

- (id<HTLaunchTaskProtocol>)addTaskOfClass:(Class)taskClass {
    NSString *key = NSStringFromClass(taskClass);
    if (!key) {
        return nil;
    }
    
    id<HTLaunchTaskProtocol> task = [self.cls2TaskMap objectForKey:key];
    if (!task) {
        task = [[taskClass alloc] init];
        [self.cls2TaskMap setObject:task forKey:key];
        
        HTAsyncOperation *operation = [HTAsyncOperation asyncOperationWithTask:task];
        operation.launchOptions = self.launchOptions;
        [self.task2OperationsMap setObject:operation forKey:key];
        self.task2Operations[key] = operation;
        
        HTLaunchStage stage = [task stage];
        
        NSArray<Class<HTLaunchTaskProtocol>> *dependencies = task.dependencies;
        [dependencies enumerateObjectsUsingBlock:^(Class<HTLaunchTaskProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *depTaskKey = NSStringFromClass(obj);;
            NSAssert(![depTaskKey isEqual:key], @"⚠️should not depend on task itself");
            
            id<HTLaunchTaskProtocol> depTask = [self addTaskOfClass:obj];
            NSAssert([depTask stage] <= stage, @"⚠️stage of depended task(%@) should not be later than task(%@) itself", depTaskKey, key);
            
            HTAsyncOperation *depOperation = [self.task2OperationsMap objectForKey:depTaskKey];
            if (depOperation) {
                [operation addDependency:depOperation];
            }
        }];
    }
    
    return task;
}

- (id<HTLaunchTaskProtocol>)taskForClass:(Class)taskClass {
    NSString *key = NSStringFromClass(taskClass);
    if (!key) {
        return nil;
    }
    
    id<HTLaunchTaskProtocol> task = [self.cls2TaskMap objectForKey:key];
    return task;
}

- (void)addOperation:(HTAsyncOperation *)operation forStage:(HTLaunchStage)stage {
    switch (stage) {
        case HTLaunchStagePrepare: {
            [self.prepareOperations addObject:operation];
            break;
        }
        case HTLaunchStageDidFinishLaunching: {
            [self.didFinishLaunchOperations addObject:operation];
            break;
        }
        case HTLaunchStageAfterFirstFrame: {
            [self.afterFirstFrameOperations addObject:operation];
            break;
        }
            
        default:
            break;
    }
}

// MARK: -

- (void)onStagePrepare {
    NSSet<HTAsyncOperation *> *ops = [self.prepareOperations copy];
    [self.prepareOperations removeAllObjects];
    [self enqueueOperations:ops];
}

- (void)onStageDidFinishLaunch {
    NSSet<HTAsyncOperation *> *ops = [self.didFinishLaunchOperations copy];
    [self.didFinishLaunchOperations removeAllObjects];
    [self enqueueOperations:ops];
}

- (void)onStageFirstFrameFinished {
    NSSet<HTAsyncOperation *> *ops = [self.afterFirstFrameOperations copy];
    [self.afterFirstFrameOperations removeAllObjects];
    [self enqueueOperations:ops];
}

- (void)enqueueOperations:(NSSet<HTAsyncOperation *> *)operations {
    self.asyncQueue.suspended = YES;
    self.mainQueue.suspended = YES;
    [operations enumerateObjectsUsingBlock:^(HTAsyncOperation * _Nonnull obj, BOOL * _Nonnull stop) {
        id<HTLaunchTaskProtocol> task = (id)obj.task;//
        HTLaunchTaskQueue queue = task.queue;
        
        switch (queue) {
            case HTLaunchTaskMainQueue: {
                [self.mainQueue addOperation:obj];
                break;
            }
            case HTLaunchTaskConcurrentQueue: {
                [self.asyncQueue addOperation:obj];
                break;
            }
                
            default:
                break;
        }
        
        NSString *key = NSStringFromClass(obj.task.class);
        [self.task2Operations removeObjectForKey:key];
    }];
    
    self.mainQueue.suspended = NO;
    self.asyncQueue.suspended = NO;
}

// MARK: -

- (NSOperationQueue *)asyncQueue {
    if (!_asyncQueue) {
        _asyncQueue = [[NSOperationQueue alloc] init];
        _asyncQueue.name = @"com.app.launch.tasks";
        _asyncQueue.maxConcurrentOperationCount = 3;
        _asyncQueue.suspended = YES;
        
        dispatch_queue_t queue =
        dispatch_queue_create_with_target("com.app.launch.task_", DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        _asyncQueue.underlyingQueue = queue;
    }
    
    return _asyncQueue;
}

- (NSOperationQueue *)mainQueue {
    if (!_mainQueue) {
        _mainQueue = [NSOperationQueue mainQueue];
    }
    
    return _mainQueue;
}

- (NSMutableSet<HTAsyncOperation *> *)prepareOperations {
    if (!_prepareOperations) {
        _prepareOperations = [NSMutableSet set];
    }
    
    return _prepareOperations;
}

- (NSMutableSet<HTAsyncOperation *> *)didFinishLaunchOperations {
    if (!_didFinishLaunchOperations) {
        _didFinishLaunchOperations = [NSMutableSet set];
    }
    
    return _didFinishLaunchOperations;
}

- (NSMutableSet<HTAsyncOperation *> *)afterFirstFrameOperations {
    if (!_afterFirstFrameOperations) {
        _afterFirstFrameOperations = [NSMutableSet set];
    }
    
    return _afterFirstFrameOperations;
}

- (NSMutableDictionary<NSString *,HTAsyncOperation *> *)task2Operations {
    if (!_task2Operations) {
        _task2Operations = [NSMutableDictionary dictionary];
    }
    
    return _task2Operations;
}

- (NSMapTable<NSString *,HTAsyncOperation *> *)task2OperationsMap {
    if (!_task2OperationsMap) {
        _task2OperationsMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    
    return _task2OperationsMap;
}

- (NSMapTable<NSString *,id<HTLaunchTaskProtocol>> *)cls2TaskMap {
    if (!_cls2TaskMap) {
        _cls2TaskMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    
    return _cls2TaskMap;
}

@end

// MARK: - HTLaunchManager

@interface HTLaunchManager () <HTLaunchTaskDispatcherDelegate>

@property (nonatomic, strong) UIApplication *application;
@property (nonatomic, strong) NSDictionary *launchOptions;

@property (nonatomic, strong) id<HTLaunchTaskDispatcherProtocol> dispatcher;

@property (nonatomic, assign) HTLaunchStage stage;

@end

@implementation HTLaunchManager

+ (instancetype)shared {
    static HTLaunchManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [self new];
        
        manager.dispatcher = [HTLaunchTaskDispatcher new];// di
        manager.dispatcher.delegate = manager;
    });
    
    return manager;
}

- (void)setTaskDispatcher:(id<HTLaunchTaskDispatcherProtocol>)dispatcher {
    self.dispatcher = dispatcher;
}

// MARK: -

- (void)registerTaskOfClass:(Class<HTLaunchTaskProtocol>)taskClass {
    [self.dispatcher registerTaskOfClass:taskClass];
}

- (void)registerTaskWithBlock:(HTLaunchTaskBlock)block forStage:(HTLaunchStage)stage queue:(HTLaunchTaskQueue)queue {
    [self.dispatcher registerTaskWithBlock:block forStage:stage queue:queue];
}

// MARK: -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.application = application;
    self.launchOptions = launchOptions;
    
    [self.class loadModuleService];
    
    // 注册block
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 13.0) {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopPerformBlock(mainRunloop,NSDefaultRunLoopMode,^(){
            [self onStageFirstFrameFinished];
        });
    } else {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopActivity activities = kCFRunLoopAllActivities;
        CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            if (activity == kCFRunLoopBeforeTimers) {
                [self onStageFirstFrameFinished];
                
                CFRunLoopRemoveObserver(mainRunloop, observer, kCFRunLoopCommonModes);
            }
        });
        CFRunLoopAddObserver(mainRunloop, observer, kCFRunLoopCommonModes);
    }
    
    [self onStagePrepare];
    [self onStageDidFinishLaunch];
    
    return YES;
}

- (void)onStagePrepare {
    self.stage = HTLaunchStagePrepare;
    [self.dispatcher onStagePrepare];
}

- (void)onStageDidFinishLaunch {
    self.stage = HTLaunchStageDidFinishLaunching;
    [self.dispatcher onStageDidFinishLaunch];
}

- (void)onStageFirstFrameFinished {
    self.stage = HTLaunchStageAfterFirstFrame;
    [self.dispatcher onStageFirstFrameFinished];
}

// MARK: -

#pragma mark - module register

inline static BOOL ht_isAppImage(uint32_t image_index) {
    const char *path = _dyld_get_image_name(image_index);
    if (path == NULL) {
        return NO;
    }
    
    NSString *imagePath = [[NSString alloc] initWithUTF8String:path];
    
    static NSString *appImagePath = nil;
    if (!appImagePath) {
        appImagePath = [[NSBundle mainBundle] bundlePath];
    }
    
    if (!appImagePath) {
        return NO;
    }
    
    return [imagePath hasPrefix:appImagePath];
}
    
+ (void)loadModuleService {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifdef __LP64__
        typedef struct mach_header_64 ht_mach_header;
#else
        typedef struct mach_header ht_mach_header;
#endif
        
        NSHashTable *appImageHeaders = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality capacity:0];
        
        uint32_t image_count = _dyld_image_count();
        for (uint32_t image_index = 0; image_index < image_count; image_index++) {
            const ht_mach_header *mach_header = (const ht_mach_header *)_dyld_get_image_header(image_index);
            if (ht_isAppImage(image_index)) {
                [appImageHeaders addObject:(__bridge id)(mach_header)];
            }
        }
        
        size_t dataLength = sizeof(HTModuleFuncEntry);
        for (id headerItem in appImageHeaders) {
                const ht_mach_header *mach_header = (__bridge const ht_mach_header *)(headerItem);
                unsigned long size = 0;
                void *dataPtr = getsectiondata(mach_header, SEG_DATA, HTEntrySectionName, &size);
                if (!dataPtr) {
                        continue;
                }
                size_t count = size / dataLength;
                for (size_t i = 0; i < count; ++i) {
                        void *data = &dataPtr[i * dataLength];
                        if (!data) {
                                continue;
                        }
                        
                        HTModuleFuncEntry *entry = data;
                        if (!entry->function) {
                                NSAssert(NO, @"loadModuleService className is nil!");
                                continue;
                        }
                        
                        module_function_type *function = entry->function;
                        function();
                }
        }
    });
}

@end
