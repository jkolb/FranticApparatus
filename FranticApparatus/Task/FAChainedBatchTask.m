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
@property (nonatomic, strong) id lastResult;
@property (nonatomic, strong) NSError *lastError;

@end



@implementation FAChainedBatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _taskFactories = [[NSMutableArray alloc] initWithCapacity:2];
    if (_taskFactories == nil) return nil;
    
    return self;
}

- (void)addTaskFactory:(id <FATask> (^)(id lastResult, NSError *lastError))taskFactory {
    [self.taskFactories addObject:[taskFactory copy]];
}

- (void)start {
    [self startTaskAtIndex:0];
}

- (void)startTaskAtIndex:(NSUInteger)index {
    BOOL allTasksComplete = index >= [self.taskFactories count];
    BOOL lastTaskFailed = self.lastResult == nil && self.lastError != nil;
    
    if (allTasksComplete || lastTaskFailed) {
        if (self.completionHandler == nil) return;
        self.completionHandler(self.lastResult, self.lastError);
        return;
    }
    
    self.currentTask = [self taskAtIndex:index];
    if (self.currentTask == nil) return; // Cancelled
    
    [self.currentTask start];
}

- (id <FATask>)taskAtIndex:(NSUInteger)index {
    NSUInteger nextIndex = index + 1;
    id <FATask> (^taskFactory)(id lastResult, NSError *lastError) = [self.taskFactories objectAtIndex:index];
    id <FATask> nextTask = taskFactory(self.lastResult, self.lastError);
    typeof(self) __weak weakSelf = self;
    [nextTask setCompletionHandler:^(id result, NSError *error) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        blockSelf.lastResult = result;
        blockSelf.lastError = [blockSelf handleError:error];
        [blockSelf startTaskAtIndex:nextIndex];
    }];
    return nextTask;
}

- (void)cancel {
    [super cancel];
    [self.currentTask cancel];
}

@end
