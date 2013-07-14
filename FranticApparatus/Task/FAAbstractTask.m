//
// FAAbstractTask.m
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



#import "FAAbstractTask.h"
#import "FATaskStartEvent.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskFinishEvent.h"
#import "FAEvent.h"



static const char * FATaskSynchronizationQueueLabel = "net.franticapparatus.task";



@interface FAAbstractTask ()

@property (strong, readonly) dispatch_queue_t synchronizationQueue;
@property BOOL cancelled;
@property BOOL finished;

@end



@implementation FAAbstractTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    _synchronizationQueue = dispatch_queue_create(FATaskSynchronizationQueueLabel, DISPATCH_QUEUE_SERIAL);
    if (_synchronizationQueue == nil) return nil;
    return self;
}

- (void)start {
    [self synchronizeWithBlock:^(FATypeOfSelf blockTask) {
        [blockTask willStart];
        [blockTask dispatchEvent:[FATaskStartEvent eventWithSource:blockTask]];
        [blockTask didStart];
    }];
}

- (void)willStart {
}

- (void)didStart {
}

- (BOOL)isCancelled {
    return self.cancelled;
}

- (void)cancel {
    [self synchronizeWithBlock:^(FATypeOfSelf blockTask) {
        [blockTask willCancel];
        blockTask.cancelled = YES;
    }];
}

- (void)willCancel {
}

- (void)finish {
    [self synchronizeWithBlock:^(FATypeOfSelf blockTask) {
        [blockTask willFinish];
        blockTask.finished = YES;
        [blockTask dispatchEvent:[FATaskFinishEvent eventWithSource:blockTask]];
    }];
}

- (void)willFinish {
}

- (NSString *)description {
    if ([self.taskDescription length] == 0) return [super description];
    return self.taskDescription;
}

- (void)synchronizeWithBlock:(void (^)(id <FATask> blockTask))block {
    FATypeOfSelf __weak weakSelf = self;
    dispatch_async(self.synchronizationQueue, ^{
        FATypeOfSelf blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if (blockSelf.cancelled) return;
        if (blockSelf.finished) return;
        block(blockSelf);
    });
}

- (void)willFinishWithResult:(id)result error:(NSError *)error {
    if (result == nil) {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:error]];
    } else {
        [self dispatchEvent:[FATaskResultEvent eventWithSource:self result:result]];
    }
}

- (void)onResultEventFromTask:(id <FATask>)task execute:(FATaskEventBlock)block {
    [self onEvent:[FATaskResultEvent class] fromTask:task execute:block];
}

- (void)onErrorEventFromTask:(id <FATask>)task execute:(FATaskEventBlock)block {
    [self onEvent:[FATaskErrorEvent class] fromTask:task execute:block];
}

- (void)onFinishEventFromTask:(id <FATask>)task execute:(FATaskEventBlock)block {
    [self onEvent:[FATaskFinishEvent class] fromTask:task execute:block];
}

- (void)onEvent:(Class)eventClass fromTask:(id <FATask>)task execute:(FATaskEventBlock)block {
    [task addHandler:[eventClass handlerWithTask:self block:^(FATypeOfSelf blockTask, id event) {
        [blockTask synchronizeWithBlock:^(FATypeOfSelf blockTask) {
            block(blockTask, event);
        }];
    }]];
}

@end
