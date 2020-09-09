//
//  RecordCrashLog.m
//  RecordCrashLog
//
//  Created by Key on 2020/9/9.
//  Copyright © 2020 Key. All rights reserved.
//

#import "RecordCrashLog.h"
#import <UIKit/UIKit.h>
#import <signal.h>
#import <execinfo.h>

@interface RecordCrashLog (Storage)
- (void)storageException:(NSException *)exception;
@end

@interface RecordCrashLog ()
@property (nonatomic, assign) BOOL interruptFinished;
@end

@implementation RecordCrashLog

static NSString * const kUncaughtExceptionStackTrackKey = @"kUncaughtExceptionStackTrackKey_";
static NSString * const kUncaughtExceptionSignalCodeKey = @"kUncaughtExceptionSignalCodeKey_";
static NSString * const kUncaughtExceptionSignalName = @"caught signal exception name";

static NSString * const kContinuouslyCrash = @"kContinuouslyCrash_";
static NSString * const kContinuouslyCrashNeedReset = @"kContinuouslyCrashNeedReset_";
static NSString * const kContinuouslyCrashLateTime = @"kContinuouslyCrashLateTime_";

#pragma mark- init

+ (instancetype)sharedInstance {
    static RecordCrashLog * crashLog = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashLog = [[RecordCrashLog alloc] init];
    });
    return crashLog;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _interruptFinished = NO;
    }
    return self;
}

- (void)registerHandler {
    [self _registerExceptionHandler];
    [self _registerSignalHandler];
}

- (void)unregisterHandler {
    [self _unregisterExceptionHandler];
    [self _unregisterSignalHandler];
}

- (BOOL)hasContinuouslyCrash {
    BOOL hasContinuouslyCrash = NO;
    NSDictionary * crashInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kContinuouslyCrash];
    if (crashInfo) {
        id value = [crashInfo objectForKey:kContinuouslyCrashNeedReset];
        if ([value respondsToSelector:@selector(boolValue)]) {
            hasContinuouslyCrash = [value boolValue];
        }
    }
    return hasContinuouslyCrash;
}

#pragma mark- Exception

static NSUncaughtExceptionHandler * originalUncaughtExceptionHandler;

- (void)_registerExceptionHandler {
    if (NSGetUncaughtExceptionHandler()) {
        originalUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    }
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

- (void)_unregisterExceptionHandler {
    NSSetUncaughtExceptionHandler(NULL);
}

void uncaughtExceptionHandler(NSException * exception) {
    
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
    NSArray * stackTrack = exception.callStackSymbols;
    if (stackTrack) {
        [userInfo setObject:stackTrack forKey:kUncaughtExceptionStackTrackKey];
    }
    NSException * handleException = [NSException exceptionWithName:exception.name
                                                            reason:exception.reason
                                                          userInfo:userInfo];
    [[RecordCrashLog sharedInstance] handleException:handleException];
    
    if (originalUncaughtExceptionHandler != NULL) {
        originalUncaughtExceptionHandler(exception);
    }
}

#pragma mark- Signal

- (void)_registerSignalHandler {
    // 由 abort 函数调用发生的终止信号
    signal(SIGABRT, signalHandler);
    // 由内存地址未对齐导致的终止信号
    signal(SIGBUS, signalHandler);
    // 由浮点数异常导致的终止信号
    signal(SIGFPE, signalHandler);
    // 由非法指令产生的终止信号
    signal(SIGILL, signalHandler);
    // 通过端口发送消息失败导致的终止信号
    signal(SIGPIPE, signalHandler);
    // 无效的内存导致的终止信号
    signal(SIGSEGV, signalHandler);
}

- (void)_unregisterSignalHandler {
    signal(SIGABRT, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
}

/// 获取 signal 错误对应的堆栈信息
NSArray * signalStackTrack() {
    void * callStack[128]; // 堆栈容器
    int numFrames = backtrace(callStack, 128); // 获取错误堆栈方法指针数组 & 返回数量
    char ** symbols = backtrace_symbols(callStack, numFrames); // 将从 backtrace 获取到的信息转化为一个字符串数组
    
    NSMutableArray * stackTrack = [NSMutableArray arrayWithCapacity:numFrames];
    for (int i = 0; i < numFrames; i ++) {
        [stackTrack addObject:[NSString stringWithUTF8String:symbols[i]]];
    }
    free(symbols);
    return stackTrack;
}

void signalHandler(int signalcode) {
    
    NSString * (^signalCodeString)(int) = ^NSString * (int code) {
        NSString * signalString = nil;
        switch (code) {
            case SIGABRT:
                signalString = @"SIGABRT";
                break;
            case SIGBUS:
                signalString = @"SIGBUS";
                break;
            case SIGFPE:
                signalString = @"SIGFPE";
                break;
            case SIGILL:
                signalString = @"SIGILL";
                break;
            case SIGPIPE:
                signalString = @"SIGPIPE";
                break;
            case SIGSEGV:
                signalString = @"SIGSEGV";
                break;
            default:
                break;
        }
        return signalString;
    };
    
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:@(signalcode) forKey:kUncaughtExceptionSignalCodeKey];
    [userInfo setObject:signalStackTrack() forKey:kUncaughtExceptionStackTrackKey];
    
    NSException * handleException = [NSException exceptionWithName:kUncaughtExceptionSignalName
                                                            reason:signalCodeString(signalcode)
                                                          userInfo:userInfo];
    [[RecordCrashLog sharedInstance] handleException:handleException];
}

#pragma mark- handle exception

- (void)handleException:(NSException *)exception {
    
    [[RecordCrashLog sharedInstance] unregisterHandler];
    [self storageException:exception];
    
    [self performSelector:@selector(_dealException:)
                 onThread:[NSThread mainThread]
               withObject:exception
            waitUntilDone:YES];
}

- (void)_dealException:(NSException *)exception {
    
#ifdef DEBUG
    NSString * stackTrack = [exception.userInfo objectForKey:kUncaughtExceptionStackTrackKey];
    NSMutableString * msg = [NSMutableString stringWithFormat:@"app 运行时发生了异常，点击屏幕，会自动将此crash信息复制到粘贴板，请第一时间将此信息发送给开发人员，谢谢！！！\n\n"];
    [msg appendFormat:@"异常名称:%@\n", exception.name];
    [msg appendFormat:@"异常原因:%@\n", exception.reason];
    [msg appendFormat:@"堆栈信息:%@\n", stackTrack];
    
    [self showToastWithCrashMsg:msg];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    
    while (self.interruptFinished == NO) {
        
        for (NSString * mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 1/120.f, false);
        }
    }
    CFRelease(allModes);
    
    NSLog(@"_dealException ----- end");
#endif
    
    // 抛异常
    if ([exception.name isEqualToString:kUncaughtExceptionSignalName]) {
        kill(getpid(), [[exception.userInfo objectForKey:kUncaughtExceptionSignalCodeKey] intValue]);
    } else {
        [exception raise];
    }
}

#pragma mark- test UI

- (void)showToastWithCrashMsg:(NSString *)msg {
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat toastLeft = 10;
    CGFloat toastTop = statusBarHeight;
    CGFloat toastWidth = screenSize.width - toastLeft*2;
    CGFloat toastHeight = screenSize.height - toastTop;
    
    UIView * view = [[UIView alloc] initWithFrame:(CGRect){{0, 0}, screenSize}];
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    
    UILabel * toast = [[UILabel alloc] initWithFrame:CGRectMake(toastLeft, toastTop, toastWidth, toastHeight)];
    toast.textColor = [UIColor redColor];
    toast.font = [UIFont systemFontOfSize:15];
    toast.text = msg;
    toast.numberOfLines = 0;
    toast.userInteractionEnabled = YES;
    [view addSubview:toast];
    
    [toast addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(crashToastTapAction:)]];
}

- (void)crashToastTapAction:(UIGestureRecognizer *)gesture {
    UILabel * toast = (UILabel *)gesture.view;
    [UIPasteboard generalPasteboard].string = toast.text;
    self.interruptFinished = YES;
}

@end



@implementation RecordCrashLog (Storage)

- (void)storageException:(NSException *)exception {
    [self _recordContinuouslyCrash];
}

- (void)_recordContinuouslyCrash {
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary * storageInfo = [userDefaults objectForKey:kContinuouslyCrash];
    NSMutableDictionary * crashInfo = [NSMutableDictionary dictionary];
    if (storageInfo) {
        [crashInfo addEntriesFromDictionary:storageInfo];
    }
    NSDate * lateCrashTime = [crashInfo objectForKey:kContinuouslyCrashLateTime];
    NSDate * nowTime = [NSDate date];
    
    // 如果 5 分钟内有连续的两次 crash，则需要进入 reset 状态
    if (lateCrashTime && (nowTime.timeIntervalSince1970 - lateCrashTime.timeIntervalSince1970 <= 5 * 60)) {
        [crashInfo setObject:@(YES) forKey:kContinuouslyCrashNeedReset];
    }
    
    [crashInfo setObject:nowTime forKey:kContinuouslyCrashLateTime];
    [userDefaults setObject:crashInfo forKey:kContinuouslyCrash];
    [userDefaults synchronize];
}

@end
