//
// FASequentialBatchTask.m
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



#import "FASequentialBatchTask.h"



@interface FASequentialBatchTask ()

@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) id <FATask> currentTask;
@property (nonatomic, strong) NSMutableArray *results;

@end



@implementation FASequentialBatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _tasks = [[NSMutableArray alloc] initWithCapacity:2];
    if (_tasks == nil) return nil;
    
    _results = [[NSMutableArray alloc] initWithCapacity:2];
    if (_results == nil) return nil;
    
    return self;
}

- (void)addTask:(id <FATask>)task {
    [self.tasks addObject:task];
}

- (void)start {
    [self startTaskAtIndex:0];
}

- (void)startTaskAtIndex:(NSUInteger)index {
    if (index >= [self.tasks count]) {
        if (self.completionHandler == nil) return;
        self.completionHandler([self.results copy], nil);
        return;
    }
    
    self.currentTask = [self taskAtIndex:index];
    [self.currentTask start];
}

- (id <FATask>)taskAtIndex:(NSUInteger)index {
    NSUInteger nextIndex = ++index;
    id <FATask> nextTask = [self.tasks objectAtIndex:index];
    typeof(self) __weak weakSelf = self;
    [nextTask setCompletionHandler:^(id result, NSError *error) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        if (result) {
            [blockSelf.results addObject:result];
        } else {
            [blockSelf.results addObject:error];
        }
        [blockSelf startTaskAtIndex:nextIndex];
    }];
    return nextTask;
}

- (void)cancel {
    [super cancel];
    [self.currentTask cancel];
}

@end
