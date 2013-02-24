//
// FAChainedBatchTask.m
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



#import "FAChainedBatchTask.h"



@interface FAChainedBatchTask ()

@property (nonatomic, strong) NSMutableArray *taskFactories;
@property (nonatomic, strong) id <FATask> currentTask;

@end



@implementation FAChainedBatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _taskFactories = [[NSMutableArray alloc] initWithCapacity:2];
    if (_taskFactories == nil) return nil;
    
    return self;
}

- (void)addTaskFactory:(id <FATask> (^)(id lastResult))taskFactory {
    [self.taskFactories addObject:[taskFactory copy]];
}

- (void)start {
    [super start];
    [self startTaskAtIndex:0 withParameter:nil];
}

- (void)startTaskAtIndex:(NSUInteger)index withParameter:(id)parameter {
    BOOL allTasksComplete = index >= [self.taskFactories count];
    
    if (allTasksComplete) {
        if (self.onResult) self.onResult(parameter);
        if (self.onFinish) self.onFinish();
        return;
    }
    
    self.currentTask = [self taskAtIndex:index withParameter:parameter];
    if (self.currentTask == nil) return; // Cancelled
    
    [self.currentTask start];
}

- (id <FATask>)taskAtIndex:(NSUInteger)index withParameter:(id)parameter {
    NSUInteger nextIndex = index + 1;
    id <FATask> (^taskFactory)(id parameter) = [self.taskFactories objectAtIndex:index];
    id <FATask> nextTask = taskFactory(parameter);
    typeof(self) __weak weakSelf = self;
    [nextTask setOnResult:^(id result) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf startTaskAtIndex:nextIndex withParameter:result];
    }];
    [nextTask setOnError:^(NSError *error) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        if (blockSelf.onError) blockSelf.onError(error);
        if (blockSelf.onFinish) blockSelf.onFinish();
    }];
    return nextTask;
}

- (void)cancel {
    [super cancel];
    [self.currentTask cancel];
}

@end
