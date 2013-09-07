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
#import "FATaskRestartEvent.h"
#import "FATaskDelayEvent.h"
#import "FATaskCompleteEvent.h"



@interface FARetryTask ()

@property (nonatomic, strong) FATaskFactory *preStartTaskFactory;
@property (nonatomic, strong) NSLock *startLock;
@property (nonatomic, strong) FATaskFactory *taskFactory;
@property (nonatomic) NSUInteger retryCount;
@property (nonatomic, strong) id <FATask> task;
@property (nonatomic, strong) dispatch_source_t delayTimer;
@property (nonatomic, strong) NSError *error;

@end



@implementation FARetryTask

- (id)init {
    return [self initWithTaskFactory:[[FATaskFactory alloc] init]];
}

- (id)initWithTaskBlock:(FATaskFactoryBlock)block {
    return [self initWithTaskFactory:[FATaskFactory factoryWithBlock:block]];
}

- (id)initWithContext:(id)context taskBlock:(FATaskFactoryContextBlock)block {
    return [self initWithTaskFactory:[FATaskFactory factoryWithContext:context block:block]];
}

- (id)initWithTaskTarget:(id)target action:(SEL)action {
    return [self initWithTaskFactory:[FATaskFactory factoryWithTarget:target action:action]];
}

- (id)initWithTaskFactory:(FATaskFactory *)taskFactory {
    self = [super init];
    if (self == nil) return nil;
    _preStartTaskFactory = taskFactory;
    _startLock = [[NSLock alloc] init];
    if (_startLock == nil) return nil;
    return self;
}

- (void)dealloc {
    if (_delayTimer != nil) dispatch_source_cancel(_delayTimer);
}

- (void)setTaskBlock:(FATaskFactoryBlock)block {
    [self.startLock lock];
    NSAssert(self.preStartTaskFactory != nil, @"Already started");
    self.preStartTaskFactory = [FATaskFactory factoryWithBlock:block];
    [self.startLock unlock];
}

- (void)setContext:(id)context taskBlock:(FATaskFactoryContextBlock)block {
    [self.startLock lock];
    NSAssert(self.preStartTaskFactory != nil, @"Already started");
    self.preStartTaskFactory = [FATaskFactory factoryWithContext:context block:block];
    [self.startLock unlock];
}

- (void)setTaskTarget:(id)target action:(SEL)action {
    [self.startLock lock];
    NSAssert(self.preStartTaskFactory != nil, @"Already started");
    self.preStartTaskFactory = [FATaskFactory factoryWithTarget:target action:action];
    [self.startLock unlock];
}

- (void)willStart {
    [self.startLock lock];
    NSAssert(self.preStartTaskFactory != nil, @"Already started");
    self.taskFactory = self.preStartTaskFactory;
    self.preStartTaskFactory = nil;
    [self.startLock unlock];
}

- (void)didStart {
    if (self.taskFactory == nil) {
        [self completeWithResult:[NSNull null] error:nil];
    } else {
        [self try];
    }
}

- (void)try {
    id <FATask> task = [self.taskFactory taskWithLastResult:nil];
    
    [self onCompleteTask:task synchronizeWithBlock:^(FATypeOfSelf blockTask, FATaskCompleteEvent *event) {
        if (event.error) {
            blockTask.error = event.error;
            [blockTask tryFailed];
        } else {
            [blockTask completeWithResult:event.result error:nil];
        }
    }];

    self.task = task;
    [self.task start];
}

- (void)tryFailed {
    NSUInteger maximumRetryCount = [self.configuration maximumRetryCount];
    if (maximumRetryCount == 0) maximumRetryCount = NSUIntegerMax;
    BOOL exceededMaximumRetryCount = self.retryCount >= maximumRetryCount;
    BOOL shouldNotRetry = ![self shouldRetryAfterError:self.error];
    
    if (exceededMaximumRetryCount || shouldNotRetry) {
        [self completeWithResult:nil error:self.error];
    } else {
        [self delayBeforeRetry];
    }
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
    self.delayTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.synchronizationQueue);
    dispatch_source_set_timer(self.delayTimer, dispatch_time(DISPATCH_TIME_NOW, delayInterval * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, 0);
    FATypeOfSelf __weak weakSelf = self;
    dispatch_source_set_event_handler(self.delayTimer, ^{
        FATypeOfSelf blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        [blockSelf cancelTimer];
        [blockSelf retry];
    });
    dispatch_resume(self.delayTimer);
}

- (void)retry {
    ++self.retryCount;
    [self dispatchEvent:[FATaskRestartEvent eventWithSource:self]];
    [self try];
}

- (BOOL)shouldRetryAfterError:(NSError *)error {
    return [self.configuration shouldRetryAfterError:error];
}

- (NSTimeInterval)nextDelayInterval {
    return [self.configuration delayIntervalForRetryCount:self.retryCount];
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

@end
