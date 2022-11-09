//
//  HTLaunchTaskDefines.h
//  Pods
//
//  Created by Jason on 2022/09/24.
//

#ifndef HTLaunchTaskDefines_h
#define HTLaunchTaskDefines_h

// MARK: -

/// 任务队列类型
typedef NS_ENUM(NSInteger, HTLaunchTaskQueue) {
    HTLaunchTaskMainQueue,
    HTLaunchTaskConcurrentQueue
};

/// 启动阶段
typedef NS_ENUM(NSInteger, HTLaunchStage) {
    HTLaunchStageNothing,           // 啥都不干
    HTLaunchStagePrepare,           // 在准备期
    HTLaunchStageDidFinishLaunching,// 在根视图配置后（didFinishLaunching结束之前）
    HTLaunchStageAfterFirstFrame    // 在首帧渲染完成后
};

typedef NSInteger HTLaunchTaskPriority;

extern NSInteger const HTLaunchTaskPriorityLow;
extern NSInteger const HTLaunchTaskPriorityDefault;
extern NSInteger const HTLaunchTaskPriorityHigh;

// MARK: -

typedef struct _HTModuleFuncEntry {
    const void *function;
    const char *fileName;
    const int line;
} HTModuleFuncEntry;

typedef void *module_function_type(void);

#ifndef HTRegisterStartUpTaskFunction

#define HTEntrySectionName "__HT__SECTION"
#define HT_MODULE_DATA_SECT(sectname) __attribute__((used, section("__DATA," sectname) ))

#define CONCAT_( x, y ) x##y
#define CONCAT( x, y ) CONCAT_( x, y )

#define HT_FUNC_ID(COUNTER) CONCAT( __HT_FUNC_ID__, COUNTER )
#define HT_ENTRY_ID(COUNTER) CONCAT( __HT_ENTRY_ID__, COUNTER )

#define HTRegisterStartUpTaskFunction() HTRegisterStartUpTaskFunction_(__COUNTER__)
#define HTRegisterStartUpTaskFunction_(COUNTER) HTRegisterStartUpTaskFunction_IMPL(HT_FUNC_ID(COUNTER), HT_ENTRY_ID(COUNTER))

#define HTRegisterStartUpTaskFunction_IMPL(FUNC_ID, ENTRY_ID) \
__attribute__((used, no_sanitize_address)) static void FUNC_ID();\
HT_MODULE_DATA_SECT(HTEntrySectionName) static const HTModuleFuncEntry ENTRY_ID = (HTModuleFuncEntry){(void *)FUNC_ID, __FILE_NAME__, __LINE__};\
__attribute__((used, no_sanitize_address)) static void FUNC_ID()

#endif

#endif
