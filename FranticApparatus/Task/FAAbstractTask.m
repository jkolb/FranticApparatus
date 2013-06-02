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
#import "FATaskCancelEvent.h"
#import "FATaskFinishEvent.h"
#import "FAEvent.h"



static const char * FATaskSynchronizationQueueLabel = "net.franticapparatus.task";



@interface FAAbstractTask ()

@property (nonatomic, strong) NSLock *synchronizationLock;
@property (nonatomic) BOOL started;
@property (nonatomic) BOOL cancelled;
@property (nonatomic) BOOL finished;

@end



@implementation FAAbstractTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    _synchronizationQueue = dispatch_queue_create(FATaskSynchronizationQueueLabel, DISPATCH_QUEUE_SERIAL);
    if (_synchronizationQueue == nil) return nil;
    _synchronizationLock = [[NSLock alloc] init];
    if (_synchronizationLock == nil) return nil;
    return self;
}

- (BOOL)isStarted {
    [self.synchronizationLock lock];
    BOOL isStarted = self.started;
    [self.synchronizationLock unlock];
    return isStarted;
}

- (void)start {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask willStart];
        blockTask.started = YES;
        [blockTask dispatchEvent:[FATaskStartEvent eventWithSource:self]];
        [blockTask didStart];
    }];
}

- (void)willStart {
    
}

- (void)didStart {
    
}

- (BOOL)isCancelled {
    [self.synchronizationLock lock];
    BOOL isCancelled = self.cancelled;
    [self.synchronizationLock unlock];
    return isCancelled;
}

- (void)cancel {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask willCancel];
        blockTask.cancelled = YES;
        [blockTask dispatchEvent:[FATaskCancelEvent eventWithSource:blockTask]];
        [blockTask didCancel];
    }];
}

- (void)willCancel {
    
}

- (void)didCancel {
    
}

- (BOOL)isFinished {
    [self.synchronizationLock lock];
    BOOL isFinished = self.finished;
    [self.synchronizationLock unlock];
    return isFinished;
}

- (void)finish {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask willFinish];
        blockTask.finished = YES;
        [blockTask dispatchEvent:[FATaskFinishEvent eventWithSource:self]];
        [blockTask didFinish];
    }];
}

- (void)willFinish {
    
}

- (void)didFinish {
    
}

- (void)synchronizeWithBlock:(void (^)(id blockTask))block {
    __typeof__(self) __weak weakSelf = self;
    dispatch_async(self.synchronizationQueue, ^{
        __typeof__(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        [blockSelf.synchronizationLock lock];
        if (blockSelf.cancelled) {
            [blockSelf.synchronizationLock unlock];
            return;
        }
        if (blockSelf.finished) {
            [blockSelf.synchronizationLock unlock];
            return;
        }
        block(blockSelf);
        [blockSelf.synchronizationLock unlock];
    });
}

@end
