//
//  ViewController.m
//  RecordCrashLog
//
//  Created by Key on 2020/9/9.
//  Copyright © 2020 Key. All rights reserved.
//

#import "ViewController.h"
#import "WBAsync2Sync.h"

typedef struct Test {
    int a;
    int b;
} Test;

@interface ViewController ()

@end

wb_async_task_interrupt_handler async_task_interrupt_handler;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        
        NSLog(@"viewDidLoad --- begin");
            
        
//            wb_async_task task = ^(id obj, wb_async_task_callback callback) {
//                
//                
//                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//                
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), queue, ^{
//                    NSLog(@"dispatch_after  ----");
//                     
//                    callback(obj);
//                });
//            };
            
//            wb_async_2_sync(task, ^(id obj) {
//
//                NSLog(@"wb_async_2_sync -----");
//            });
            
            
        
//            wb_async_2_sync_nonblocking(task, ^(id obj) {
//
//                NSLog(@"wb_async_2_sync_nonblocking -----");
//            });
        
        
        
        
        
        wb_async_task_callback async_task_callback = ^(id obj/*, id obj1, id obj2, id obj3*/) {
        };
        
        wb_async_task_interruptable interruptable_async_task = ^(id obj, wb_async_task_interrupt_handler interrupt_handler, wb_async_task_callback callback) {
            
            // 保存interrupt_handler以便外部能够打断task
            async_task_interrupt_handler = [interrupt_handler copy];
            
            // 执行异步动作
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), queue, ^{
                NSLog(@"dispatch_after  ----");
                 
                callback(obj);
            });
            
            // 注意callback的第一个参数必须有
//            callback(obj/*, obj1, obj2, obj3*/);
        };
        
        wb_async_2_sync_nonblocking_interruptable(interruptable_async_task, async_task_callback);
        
        NSLog(@"viewDidLoad --- end");
        
    });
    

    NSLog(@"viewDidLoad --- 111111");
    
    
//    __block NSArray * dbAdConfigList = nil;
//    fd_async_task task = ^(id obj, fd_async_task_callback callback) {
//        callback(obj);
//    };
//    fd_async_to_sync_nonblocking(task, ^(id obj) {});
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s", __func__);
    
    async_task_interrupt_handler();
}



- (IBAction)crashClickException:(id)sender {
    
    [self performSelector:@selector(func)];
}

- (IBAction)crashClickSignal_EGV:(id)sender {
    UIView * view = [[UIView alloc] init];
    [view performSelector:NSSelectorFromString(@"release")];//导致SIGSEGV的错误，一般会导致进程流产
    view.backgroundColor = [UIColor whiteColor];
}

- (IBAction)crashClickSignal_ABRT:(id)sender {
    Test * pTest = {1, 2};
    free(pTest);//导致SIGABRT的错误，因为内存中根本就没有这个空间，哪来的free，就在栈中的对象而已
    pTest->a = 5;
}

- (IBAction)crashClickSignal_BUS:(id)sender {
    //SIGBUS，内存地址未对齐
    //EXC_BAD_ACCESS(code=1,address=0x1000dba58)
    char *s = "hello world";
    *s = 'H';
}

@end
