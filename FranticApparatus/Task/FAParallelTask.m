//
// FAParallelTask.m
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



#import "FAParallelTask.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskFinishEvent.h"
#import "FATaskFactory.h"
#import "FAEventHandler.h"



@interface FAParallelTask ()

@property (copy) NSDictionary *factories;
@property (nonatomic, strong, readonly) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *results;
@property (nonatomic, strong) NSError *error;

@end



@implementation FAParallelTask

- (id)init {
    return [self initWithFactories:@{}];
}

- (id)initWithFactories:(NSDictionary *)factories {
    self = [super init];
    if (self == nil) return nil;
    _factories = [factories copy];
    if (_factories == nil) return nil;
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:[factories count]];
    if (_tasks == nil) return nil;
    
    for (id key in factories) {
        id object = factories[key];
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
        FATaskFactory *factory = object;
        id <FATask> task = [factory taskWithLastResult:nil];
        
        if (task == nil) return nil;
        
        [self onResultEventFromTask:task execute:^(FATypeOfSelf blockTask, FATaskResultEvent *event) {
            blockTask.results[key] = event.result;
        }];
        [self onErrorEventFromTask:task execute:^(FATypeOfSelf blockTask, FATaskErrorEvent *event) {
            blockTask.error = event.error;
        }];
        [self onFinishEventFromTask:task execute:^(FATypeOfSelf blockTask, FATaskFinishEvent *event) {
            [blockTask.tasks removeObjectForKey:key];
            if ([blockTask.tasks count] == 0 || blockTask.error != nil) {
                [blockTask finish];
            }
        }];

        [_tasks setObject:task forKey:key];
    }
    _results = [[NSMutableDictionary alloc] initWithCapacity:[_tasks count]];
    if (_results == nil) return nil;
    return self;
}

- (void)willStart {
    for (id key in self.factories) {
        FATaskFactory *factory = self.factories[key];
        id <FATask> task = [factory taskWithLastResult:nil];
        
        [self onResultEventFromTask:task execute:^(FATypeOfSelf blockTask, FATaskResultEvent *event) {
            blockTask.results[key] = event.result;
        }];
        [self onErrorEventFromTask:task execute:^(FATypeOfSelf blockTask, FATaskErrorEvent *event) {
            blockTask.error = event.error;
        }];
        [self onFinishEventFromTask:task execute:^(FATypeOfSelf blockTask, FATaskFinishEvent *event) {
            [blockTask.tasks removeObjectForKey:key];
            if ([blockTask.tasks count] == 0 || blockTask.error != nil) {
                [blockTask finish];
            }
        }];
        
        self.tasks[key] = task;
    }
}

- (void)didStart {
    if ([self.tasks count] == 0) [self finish];
    for (id <FATask> task in [self.tasks allValues]) [task start];
}

- (void)willCancel {
    [self cancelOutstandingTasks];
}

- (void)cancelOutstandingTasks {
    for (id <FATask> task in [self.tasks allValues]) [task cancel];
}

- (void)willFinish {
    [self cancelOutstandingTasks];
    [self willFinishWithResult:self.results error:self.error];
}

- (BOOL)shouldFailOnError:(NSError *)error forKey:(id)key {
    return YES;
}

@end
