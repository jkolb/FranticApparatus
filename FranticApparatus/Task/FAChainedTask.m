//
// FAChainedTask.m
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



#import "FAChainedTask.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskCancelEvent.h"
#import "FATaskFinishEvent.h"
#import "FATaskFactory.h"



@interface FAChainedTask ()

@property (nonatomic, copy, readonly) NSArray *taskFactories;
@property (nonatomic, strong) id <FATask> currentTask;
@property (nonatomic, strong) id lastResult;
@property (nonatomic, strong) NSError *lastError;

@end



@implementation FAChainedTask

- (id)init {
    return [self initWithArray:[[NSArray alloc] init]];
}

- (id)initWithArray:(NSArray *)array {
    self = [super init];
    if (self == nil) return nil;
    _taskFactories = array;
    if (_taskFactories == nil) return nil;
    for (id object in _taskFactories) {
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
    }
    return self;
}

- (void)didStart {
    [self startTaskAtIndex:0 withLastResult:nil];
}

- (void)startTaskAtIndex:(NSUInteger)index withLastResult:(id)lastResult {
    FATaskFactory *taskFactory = [self.taskFactories objectAtIndex:index];
    id <FATask> task = [taskFactory taskWithLastResult:lastResult];
    [task addHandler:[FATaskResultEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskResultEvent *event) {
        [blockTask handleTaskResultEvent:event forIndex:index];
    }]];
    [task addHandler:[FATaskErrorEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskErrorEvent *event) {
        [blockTask handleTaskErrorEvent:event forIndex:index];
    }]];
    [task addHandler:[FATaskCancelEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskCancelEvent *event) {
        [blockTask handleTaskCancelEvent:event forIndex:index];
    }]];
    [task addHandler:[FATaskFinishEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskFinishEvent *event) {
        [blockTask handleTaskFinishEvent:event forIndex:index];
    }]];
    self.currentTask = task;
    [task start];
}

- (void)willCancel {
    [self.currentTask cancel];
}

- (void)willFinish {
    if (self.lastError == nil) {
        [self dispatchEvent:[FATaskResultEvent eventWithSource:self result:self.lastResult]];
    } else {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:self.lastError]];
    }
}

- (void)handleTaskResultEvent:(FATaskResultEvent *)event forIndex:(NSUInteger)index {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        blockTask.lastResult = event.result;
    }];
}

- (void)handleTaskErrorEvent:(FATaskErrorEvent *)event forIndex:(NSUInteger)index {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        blockTask.lastError = event.error;
    }];
}

- (void)handleTaskCancelEvent:(FATaskCancelEvent *)event forIndex:(NSUInteger)index {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask cancel];
    }];
}

- (void)handleTaskFinishEvent:(FATaskFinishEvent *)event forIndex:(NSUInteger)index {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        if (blockTask.lastError == nil) {
            NSUInteger nextIndex = index + 1;
            
            if (nextIndex < [blockTask.taskFactories count]) {
                [blockTask startTaskAtIndex:nextIndex withLastResult:blockTask.lastResult];
            } else {
                [blockTask finish];
            }
        } else {
            [blockTask finish];
        }

    }];
}

@end
