//
//  WBAsync2Sync.m
//  Weibo
//
//  Created by Wade Cheng on 8/26/14.
//  Copyright (c) 2014 Sina. All rights reserved.
//

#import "WBAsync2Sync.h"

@interface WBAsync2SyncObserver : NSObject
{
    wb_async_task_interrupt_handler deallocBlock;
}

- (instancetype)initWithDeallocBlock:(wb_async_task_interrupt_handler)deallocBlock;

@end

@implementation WBAsync2SyncObserver

- (instancetype)initWithDeallocBlock:(void (^)(void))aDeallocBlock;
{
    if (self = [super init])
    {
        deallocBlock = [aDeallocBlock copy];
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    if (deallocBlock)
    {
        deallocBlock();
        deallocBlock = nil;
    }
}

@end

void _wb_async_2_sync_wait_until_interrupt(wb_async_task_interruptable task, wb_async_task_callback callback, wb_async_task_interrupt_handler interrupt_handler, void (^wait_until_interrupt)(void))
{
    @autoreleasepool {
        id observer = [[WBAsync2SyncObserver alloc] initWithDeallocBlock:interrupt_handler];
        
        task(observer, interrupt_handler, callback);
        
    }
    
    wait_until_interrupt();
}


void wb_async_2_sync(wb_async_task task, wb_async_task_callback callback)
{
    wb_async_task_interruptable interruptable_task = ^ (id obj, wb_async_task_interrupt_handler interrupt_handler, wb_async_task_callback callback) {
        task(obj, callback);
    };
    
    wb_async_2_sync_interruptable(interruptable_task, callback);
}

void wb_async_2_sync_interruptable(wb_async_task_interruptable task, wb_async_task_callback callback)
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    wb_async_task_interrupt_handler interrupt_handler = ^ () {
        dispatch_semaphore_signal(semaphore);
    };
    
    _wb_async_2_sync_wait_until_interrupt(task, callback, interrupt_handler, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        //dispatch_release(semaphore);
    });
}

void wb_async_2_sync_nonblocking(wb_async_task task, wb_async_task_callback callback)
{
    wb_async_task_interruptable interruptable_task = ^ (id obj, wb_async_task_interrupt_handler interrupt_handler, wb_async_task_callback callback) {
        task(obj, callback);
    };
    
    wb_async_2_sync_nonblocking_interruptable(interruptable_task, callback);
}

void wb_async_2_sync_nonblocking_interruptable(wb_async_task_interruptable task, wb_async_task_callback callback)
{
    __block BOOL finished = NO;
    
    
    CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
    
    CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    
    CFRunLoopAddSource(runloop, source, kCFRunLoopDefaultMode);
    
    wb_async_task_interrupt_handler interrupt_handler = ^ () {
        finished = YES;
        
        CFRunLoopSourceSignal(source);
        CFRunLoopWakeUp(runloop);
    };

    _wb_async_2_sync_wait_until_interrupt(task, callback, interrupt_handler, ^{
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!finished);
    });
    
    CFRunLoopRemoveSource(runloop, source, kCFRunLoopDefaultMode);
    CFRelease(source);
}

wb_async_task_callback wb_async_task_callback_null()
{
    return ^ (id obj) {};
}

void wb_async_2_sync_samples() {
    
    // 定义一个异步task的回调
    // 注意看 wb_async_task_callback 的定义，block参数为空，表示可以是任意参数（但是不允许小于等于16bit的参数类型）
    // 定义callback的参数时需要注意：
    //  1、必须至少有一个参数
    //  2、第一个参数必须是 id obj（这个参数仅用于实现异步回调，与具体业务没有关系）
    //  3、其他参数按照具体的业务可以自行定义
    wb_async_task_callback async_task_callback = ^(id obj/*, id obj1, id obj2, id obj3*/) {
    };
    
    // 定义一个异步的task
    // 注意task执行完成之后，需要调用callback
    //  1、调用callback时输入的第一个参数，就是这个task的输入参数obj
    //  2、调用callback时输入的其他参数按照具体业务自定定义（需要与上面的callback的实现匹配）
    //  3、必须在最后一行调用callback
    wb_async_task async_task = ^ (id obj, wb_async_task_callback callback) {
        // 执行异步动作
        
        // 注意callback的第一个参数必须有
        callback(obj/*, obj1, obj2, obj3*/);
    };
    
    // 一个异步task的打断器（调用这个block之后，task应该很快停止）
    // 当我们定义一个可被打断的task时，就会产生一个该task的打断器
    // 当我们想要打断一个异步的task时，调用该task的打断器，异步转同步的方法就会立即返回（注意不是task去callback，而是wb_async_2_sync方法结束）
    __block wb_async_task_interrupt_handler async_task_interrupt_handler;
    
    // 定义一个可以被打断的异步task
    wb_async_task_interruptable interruptable_async_task = ^(id obj, wb_async_task_interrupt_handler interrupt_handler, wb_async_task_callback callback) {
        
        // 保存interrupt_handler以便外部能够打断task
        async_task_interrupt_handler = [interrupt_handler copy];
        
        // 执行异步动作
        
        // 注意callback的第一个参数必须有
        callback(obj/*, obj1, obj2, obj3*/);
    };
    
    
    // 使用GCD，阻断当前线程等待
    wb_async_2_sync(async_task, async_task_callback);
    wb_async_2_sync_interruptable(interruptable_async_task, async_task_callback);
    
    // 使用runloop，使用runloop不阻断当前线程
    wb_async_2_sync_nonblocking(async_task, async_task_callback);
    wb_async_2_sync_nonblocking_interruptable(interruptable_async_task, async_task_callback);
}
