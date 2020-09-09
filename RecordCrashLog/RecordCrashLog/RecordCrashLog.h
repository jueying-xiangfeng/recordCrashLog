//
//  RecordCrashLog.h
//  RecordCrashLog
//
//  Created by Key on 2020/9/9.
//  Copyright © 2020 Key. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordCrashLog : NSObject

+ (instancetype)sharedInstance;

- (void)registerHandler;
- (void)unregisterHandler;

/// 是否有连续的 crash
- (BOOL)hasContinuouslyCrash;

@end

NS_ASSUME_NONNULL_END
