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
#import "FATaskCompleteEvent.h"
#import "FATaskFactory.h"
#import "FAEventHandler.h"



@interface FAParallelTask ()

@property (copy) NSDictionary *factories;
@property (nonatomic, strong, readonly) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *results;

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
    for (id key in factories) {
        id object = factories[key];
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
    }
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:[factories count]];
    if (_tasks == nil) return nil;
    _results = [[NSMutableDictionary alloc] initWithCapacity:[factories count]];
    if (_results == nil) return nil;
    return self;
}

- (void)willStart {
    for (id key in self.factories) {
        FATaskFactory *factory = self.factories[key];
        id <FATask> task = [factory taskWithLastResult:nil];
        
        [self onCompleteTask:task execute:^(FATypeOfSelf blockTask, FATaskCompleteEvent *event) {
            blockTask.results[key] = event.result;
            [blockTask.tasks removeObjectForKey:key];
            if ([blockTask.tasks count] == 0 || event.error != nil) {
                [blockTask completeWithResult:blockTask.results error:event.error];
            }
        }];
        
        self.tasks[key] = task;
    }
}

- (void)didStart {
    if ([self.tasks count] == 0) [self completeWithResult:nil error:nil];
    for (id <FATask> task in [self.tasks allValues]) [task start];
}

- (void)willCancel {
    [self cancelOutstandingTasks];
}

- (void)willComplete {
    [self cancelOutstandingTasks];
}

- (void)cancelOutstandingTasks {
    for (id <FATask> task in [self.tasks allValues]) [task cancel];
}

@end
