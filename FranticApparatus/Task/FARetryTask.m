//
// FARetryTask.m
//
// Copyright (c) 2013 Justin Kolb - http://franticapparatus.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//



#import "FARetryTask.h"
#import "FATaskFactory.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskRestartEvent.h"
#import "FATaskDelayEvent.h"
#import "FATaskCancelEvent.h"
#import "FATaskFinishEvent.h"



@interface FARetryTask ()

@property (nonatomic, copy, readonly) FATaskFactory *taskFactory;
@property (nonatomic, readonly) NSUInteger maximumRetryCount;
@property (nonatomic) NSUInteger retryCount;
@property (nonatomic, strong) id <FATask> task;
@property (nonatomic, strong) dispatch_source_t delayTimer;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

@end



@implementation FARetryTask

- (id)init {
    return [self initWithTaskFactory:[[FATaskFactory alloc] init] maximumRetryCount:0];
}

- (id)initWithTaskFactory:(FATaskFactory *)taskFactory maximumRetryCount:(NSUInteger)maximumRetryCount {
    self = [super init];
    if (self == nil) return nil;
    _taskFactory = taskFactory;
    if (_taskFactory == nil) return nil;
    _maximumRetryCount = maximumRetryCount;
    return self;
}

- (void)dealloc {
    if (_delayTimer != nil) dispatch_source_cancel(_delayTimer);
}

- (void)didStart {
    [self try];
}

- (void)try {
    id <FATask> task = [self.taskFactory taskWithLastResult:nil];
    [task addHandler:[FATaskResultEvent
                      handlerWithTask:self
                      block:^(__typeof__(self) blockTask, FATaskResultEvent *event) {
                          [blockTask handleTaskResultEvent:event];
                      }]];
    [task addHandler:[FATaskErrorEvent
                      handlerWithTask:self
                      block:^(__typeof__(self) blockTask, FATaskErrorEvent *event) {
                          [blockTask handleTaskErrorEvent:event];
                      }]];
    [task addHandler:[FATaskCancelEvent
                      handlerWithTask:self
                      block:^(__typeof__(self) blockTask, FATaskCancelEvent *event) {
                          [blockTask handleTaskCancelEvent:event];
                      }]];
    [task addHandler:[FATaskFinishEvent
                      handlerWithTask:self
                      block:^(__typeof__(self) blockTask, FATaskFinishEvent *event) {
                          [blockTask handleTaskFinishEvent:event];
                      }]];
    self.task = task;
    [self.task start];
}

- (void)tryFailed {
    BOOL exceededMaximumRetryCount = self.retryCount == NSUIntegerMax || (self.retryCount == self.maximumRetryCount && self.maximumRetryCount > 0);
    BOOL shouldNotRetry = [self shouldRetryAfterError:self.error] == NO;
    
    if (exceededMaximumRetryCount || shouldNotRetry) {
        [self finish];
    } else {
        [self delayBeforeRetry];
    }
}

- (void)retry {
    ++self.retryCount;
    [self dispatchEvent:[FATaskRestartEvent eventWithSource:self]];
    [self try];
}

- (void)delayBeforeRetry {
    NSTimeInterval delayInterval = [self nextDelayInterval];
    
    if (delayInterval <= 0) {
        [self retry];
    } else {
        [self dispatchEvent:[FATaskDelayEvent eventWithSource:self]];
        [self retryAfterDelayInterval:delayInterval];
    }
}

- (void)retryAfterDelayInterval:(NSTimeInterval)delayInterval {
    [self cancelTimer];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.delayTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.delayTimer, dispatch_time(DISPATCH_TIME_NOW, delayInterval * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    __typeof__(self) __weak weakSelf = self;
    dispatch_source_set_event_handler(self.delayTimer, ^{
        __typeof__(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        [blockSelf cancelTimer];
        [blockSelf retry];
    });
    dispatch_resume(self.delayTimer);
}

- (BOOL)shouldRetryAfterError:(NSError *)error {
    if ([[error domain] isEqualToString:@"FARetryTaskErrorDomain"] && [error code] == -1) return NO;
    if (self.shouldRetry == nil) return YES;
    return self.shouldRetry(error);
}

- (NSTimeInterval)nextDelayInterval {
    if (self.delayInterval > 0) return self.delayInterval;
    if (self.calculateDelayInterval == nil) return 5.0;
    return self.calculateDelayInterval(self.retryCount);
}

- (void)cancelTimer {
    if (self.delayTimer == nil) return;
    dispatch_source_cancel(self.delayTimer);
    self.delayTimer = nil;
}

- (void)willCancel {
    [self cancelTimer];
    [self.task cancel];
}

- (void)handleTaskResultEvent:(FATaskResultEvent *)event {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        blockTask.result = event.result;
    }];
}

- (void)handleTaskErrorEvent:(FATaskErrorEvent *)event {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        blockTask.error = event.error;
    }];
}

- (void)handleTaskCancelEvent:(FATaskCancelEvent *)event {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        blockTask.error = [NSError errorWithDomain:@"FARetryTaskErrorDomain" code:-1 userInfo:nil];
        [blockTask tryFailed];
    }];
}

- (void)handleTaskFinishEvent:(FATaskFinishEvent *)event {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        if (blockTask.error == nil) {
            [blockTask finish];
        } else {
            [blockTask tryFailed];
        }
    }];
}

- (void)willFinish {
    if (self.result == nil) {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:self.error]];
    } else {
        [self dispatchEvent:[FATaskResultEvent eventWithSource:self result:self.result]];
    }
}

@end
