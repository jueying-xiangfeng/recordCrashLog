//
//  WBAsync2Sync.h
//  Weibo
//
//  Created by Wade Cheng on 8/26/14.
//  Copyright (c) 2014 Sina. All rights reserved.
//

#import <Foundation/Foundation.h>

//void wb_async_2_sync(void (^async_task)(void (^async_task_callback)()), void (^async_task_callback)());


typedef void (^wb_async_task_callback)(id);
typedef void (^wb_async_task)(id obj, wb_async_task_callback callback);

typedef void (^wb_async_task_interrupt_handler)(void);
typedef void (^wb_async_task_interruptable)(id obj, wb_async_task_interrupt_handler interrupt_handler, wb_async_task_callback callback);

void wb_async_2_sync(wb_async_task task, wb_async_task_callback callback);
void wb_async_2_sync_interruptable(wb_async_task_interruptable task, wb_async_task_callback callback);

void wb_async_2_sync_nonblocking(wb_async_task task, wb_async_task_callback callback);
void wb_async_2_sync_nonblocking_interruptable(wb_async_task_interruptable task, wb_async_task_callback callback);

wb_async_task_callback wb_async_task_callback_null(id);
