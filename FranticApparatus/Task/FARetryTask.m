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



NSString * const FARetryTaskEventRestarted = @"FARetryTaskEventRestarted";
NSString * const FARetryTaskEventDelayed = @"FARetryTaskEventDelayed";



@interface FARetryTask ()

@property (nonatomic, strong) id <FATask> task;
@property (nonatomic) NSUInteger tryCount;
@property (strong) dispatch_source_t delayTimer;

@end



@implementation FARetryTask

- (void)dealloc {
    if (_delayTimer != nil) dispatch_source_cancel(_delayTimer);
}

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    [self try];
}

- (void)try {
    ++self.tryCount;
    
    if (self.tryCount > 1) [self triggerEvent:FARetryTaskEventRestarted withObject:self];
    
    id parameter = [self parameter];
    self.task = self.factory(parameter);
    [self.task addTarget:self action:@selector(tryFailedWithError:) forTaskEvent:FATaskEventFailed];
    [self.task setParentTask:self];
    [self.task setExcludeParentEvents:[NSSet setWithObjects:FATaskEventStarted, FATaskEventCancelled, FATaskEventFailed, nil]];
    [self.task startWithParameter:parameter];
}

- (void)tryFailedWithError:(id)error {
    BOOL exceededMaximumAttempts = self.tryCount == NSUIntegerMax || (self.tryCount == self.maximumAttempts && self.maximumAttempts > 0);
    BOOL shouldNotRetry = [self shouldRetryAfterError:error] == NO;
    
    if (exceededMaximumAttempts || shouldNotRetry) {
        [self failWithError:error];
    } else {
        [self delayBeforeRetry];
    }
}

- (void)delayBeforeRetry {
    NSTimeInterval delayInterval = [self nextDelayInterval];
    
    if (delayInterval == 0) {
        [self try];
    } else {
        [self triggerEvent:FARetryTaskEventDelayed withObject:self];
        [self retryAfterDelayInterval:delayInterval];
    }
}

- (void)retryAfterDelayInterval:(NSTimeInterval)delayInterval {
    [self cancelTimer];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.delayTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    __typeof__(self) __weak weakSelf = self;
    dispatch_source_set_event_handler(self.delayTimer, ^{
        __typeof__(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        [blockSelf cancelTimer];
        [blockSelf try];
    });
    dispatch_resume(self.delayTimer);
}

- (BOOL)shouldRetryAfterError:(id)error {
    if (self.shouldRetry == nil) return YES;
    return self.shouldRetry(error);
}

- (NSTimeInterval)nextDelayInterval {
    if (self.delayInterval > 0) return self.delayInterval;
    if (self.calculateDelayInterval == nil) return 5.0;
    return self.calculateDelayInterval();
}

- (void)cancelTimer {
    if (self.delayTimer != nil) {
        dispatch_source_cancel(self.delayTimer);
        self.delayTimer = nil;
    }
}

- (void)cancel {
    [self cancelTimer];
    [self cancel];
}

@end
