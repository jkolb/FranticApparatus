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
#import "FATaskCompleteEvent.h"
#import "FAEvent.h"



static const char * FATaskSynchronizationQueueLabel = "net.franticapparatus.task";



@interface FAAbstractTask ()

@property (strong, readonly) dispatch_queue_t synchronizationQueue;
@property BOOL cancelled;
@property BOOL completed;

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

- (void)willComplete {
}

- (void)completeWithResult:(id)result error:(NSError *)error {
    [self synchronizeWithBlock:^(FATypeOfSelf blockTask) {
        [blockTask willComplete];
        blockTask.completed = YES;
        [blockTask dispatchEvent:[FATaskCompleteEvent eventWithSource:blockTask result:result error:error]];
    }];
}

- (void)onCompleteWithContext:(id)context executeOnMainQueue:(FATaskCompleteBlock)block {
    [self addHandler:[[FATaskCompleteEvent handlerWithContext:context block:^(id blockContext, id event) {
        block(blockContext, event);
    }] onMainQueue]];
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
        if (blockSelf.completed) return;
        block(blockSelf);
    });
}

- (void)onCompleteTask:(id <FATask>)task execute:(FATaskEventBlock)block {
    [task addHandler:[FATaskCompleteEvent handlerWithTask:self block:^(FATypeOfSelf blockTask, id event) {
        [blockTask synchronizeWithBlock:^(FATypeOfSelf blockTask) {
            block(blockTask, event);
        }];
    }]];
}

@end
