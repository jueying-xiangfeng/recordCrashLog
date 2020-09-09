//
//  ViewController.m
//  RecordCrashLog
//
//  Created by Key on 2020/9/9.
//  Copyright © 2020 Key. All rights reserved.
//

#import "ViewController.h"

typedef struct Test {
    int a;
    int b;
} Test;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
