//
// FAParallelBatchTask.m
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



#import "FAParallelBatchTask.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskCancelEvent.h"
#import "FATaskFinishEvent.h"
#import "FATaskFactory.h"
#import "FAEventHandler.h"



@interface FAParallelBatchTask ()

@property (nonatomic, strong, readonly) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *results;
@property (nonatomic, strong) NSError *error;

@end



@implementation FAParallelBatchTask

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self == nil) return nil;
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:[dictionary count]];
    if (_tasks == nil) return nil;
    
    for (id key in dictionary) {
        id object = [dictionary objectForKey:key];
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
        FATaskFactory *taskFactory = object;
        id <FATask> task = [taskFactory task];
        [task addHandler:[FATaskResultEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskResultEvent *event) {
            [blockTask handleTaskResultEvent:event forKey:key];
        }]];
        [task addHandler:[FATaskErrorEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskErrorEvent *event) {
            [blockTask handleTaskErrorEvent:event forKey:key];
        }]];
        [task addHandler:[FATaskCancelEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskCancelEvent *event) {
            [blockTask handleTaskCancelEvent:event forKey:key];
        }]];
        [task addHandler:[FATaskFinishEvent handlerWithTask:self block:^(__typeof__(self) blockTask, FATaskFinishEvent *event) {
            [blockTask handleTaskFinishEvent:event forKey:key];
        }]];
        [_tasks setObject:task forKey:key];
    }
    _results = [[NSMutableDictionary alloc] initWithCapacity:[_tasks count]];
    if (_results == nil) return nil;
    return self;
}

- (void)didStart {
    for (id <FATask> task in [self.tasks allValues]) [task start];
    if ([self.tasks count] == 0) [self finish];
}

- (void)willCancel {
    [self cancelOutstandingTasks];
}

- (void)cancelOutstandingTasks {
    for (id <FATask> task in [self.tasks allValues]) [task cancel];
}

- (void)willFinish {
    [self cancelOutstandingTasks];
    
    if (self.error == nil) {
        [self dispatchEvent:[FATaskResultEvent eventWithSource:self result:self.results]];
    } else {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:self.error]];
    }
}

- (BOOL)shouldFailOnError:(NSError *)error forKey:(id)key {
    return YES;
}

- (void)handleTaskResultEvent:(FATaskResultEvent *)event forKey:(id)key {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask.results setObject:event.result forKey:key];
    }];
}

- (void)handleTaskErrorEvent:(FATaskErrorEvent *)event forKey:(id)key {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        if ([blockTask shouldFailOnError:event.error forKey:key]) {
            blockTask.error = event.error;
        }
    }];
}

- (void)handleTaskCancelEvent:(FATaskCancelEvent *)event forKey:(id)key {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask.tasks removeObjectForKey:key];
    }];
}

- (void)handleTaskFinishEvent:(FATaskFinishEvent *)event forKey:(id)key {
    [self synchronizeWithBlock:^(__typeof__(self) blockTask) {
        [blockTask.tasks removeObjectForKey:key];
        if ([blockTask.tasks count] == 0 || blockTask.error != nil) {
            [blockTask finish];
        }
    }];
}

@end
