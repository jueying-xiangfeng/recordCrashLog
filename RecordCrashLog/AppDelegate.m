//
//  AppDelegate.m
//  RecordCrashLog
//
//  Created by Key on 2020/9/9.
//  Copyright © 2020 Key. All rights reserved.
//

#import "AppDelegate.h"
#import "RecordCrashLog.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[RecordCrashLog sharedInstance] registerHandler];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if ([[RecordCrashLog sharedInstance] hasContinuouslyCrash]) {
            
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"是否重置用户信息"
                                                                            message:@"数据异常？有连续的crash"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            UIAlertAction * sureAction = [UIAlertAction actionWithTitle:@"确定"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
                // 做一些还原本地数据的操作
                
                
            }];
            [alert addAction:cancelAction];
            [alert addAction:sureAction];
            
            
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
    
    return YES;
}

@end
