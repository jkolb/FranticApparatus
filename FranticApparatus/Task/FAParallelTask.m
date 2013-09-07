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

@property (nonatomic, strong) NSMutableDictionary *factories;
@property (nonatomic, strong) NSLock *startLock;
@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *results;

@end



@implementation FAParallelTask

- (id)init {
    return [self initWithFactories:@{}];
}

- (id)initWithFactories:(NSDictionary *)factories {
    self = [super init];
    if (self == nil) return nil;
    _factories = [[NSMutableDictionary alloc] initWithDictionary:factories];
    if (_factories == nil) return nil;
    for (id key in _factories) {
        id object = _factories[key];
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
    }
    _startLock = [[NSLock alloc] init];
    if (_startLock == nil) return nil;
    return self;
}

- (void)setKey:(id<NSCopying>)key forTaskBlock:(FATaskFactoryBlock)block {
    [self.startLock lock];
    NSAssert(self.factories != nil, @"Already started");
    self.factories[key] = [FATaskFactory factoryWithBlock:block];
    [self.startLock unlock];
}

- (void)setKey:(id <NSCopying>)key forContext:(id)context taskBlock:(FATaskFactoryContextBlock)block {
    [self.startLock lock];
    NSAssert(self.factories != nil, @"Already started");
    self.factories[key] = [FATaskFactory factoryWithContext:context block:block];
    [self.startLock unlock];
}

- (void)setKey:(id <NSCopying>)key forTaskTarget:(id)target action:(SEL)action {
    [self.startLock lock];
    NSAssert(self.factories != nil, @"Already started");
    self.factories[key] = [FATaskFactory factoryWithTarget:target action:action];
    [self.startLock unlock];
}

- (void)willStart {
    [self.startLock lock];
    NSAssert(self.factories != nil, @"Already started");
    self.tasks = [[NSMutableDictionary alloc] initWithCapacity:[self.factories count]];
    self.results = [[NSMutableDictionary alloc] initWithCapacity:[self.factories count]];
    
    for (id key in self.factories) {
        FATaskFactory *factory = self.factories[key];
        id <FATask> task = [factory taskWithLastResult:nil];
        
        [self onCompleteTask:task synchronizeWithBlock:^(FATypeOfSelf blockTask, FATaskCompleteEvent *event) {
            if (event.error) {
                if (blockTask.allowPartialFailure) {
                    [blockTask taskForKey:key completedWithResult:event.error];
                } else {
                    [blockTask completeWithResult:nil error:event.error];
                }
            } else {
                [blockTask taskForKey:key completedWithResult:event.result];
            }
        }];
        
        self.tasks[key] = task;
    }
    
    self.factories = nil;
    [self.startLock unlock];
}

- (void)taskForKey:(id)key completedWithResult:(id)result {
    self.results[key] = result;
    [self.tasks removeObjectForKey:key];
    
    if ([self.tasks count] == 0) {
        [self completeWithResult:self.results error:nil];
    }
}

- (void)didStart {
    if ([self.tasks count] > 0) {
        for (id <FATask> task in [self.tasks allValues]) [task start];
    } else {
        [self completeWithResult:[NSNull null] error:nil];
    }
}

- (void)willCancel {
    [self cancelOutstandingTasks];
}

- (void)willComplete {
    // If a task fails need to cancel any tasks that are still executing.
    [self cancelOutstandingTasks];
}

- (void)cancelOutstandingTasks {
    for (id <FATask> task in [self.tasks allValues]) [task cancel];
}

@end
