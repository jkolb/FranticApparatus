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



@interface FAParallelBatchTask ()

@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *results;

@end



@implementation FAParallelBatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_tasks == nil) return nil;
    
    _results = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_results == nil) return nil;
    
    return self;
}

- (void)setTask:(id <FATask>)task forKey:(id <NSCopying>)key {
    [self.tasks setObject:task forKey:key];
}

- (void)start {
    for (id key in self.tasks) {
        id <FATask> task = [self taskForKey:key];
        [task start];
    }
}

- (id <FATask>)taskForKey:(id)key {
    id <FATask> task = [self.tasks objectForKey:key];
    typeof(self) __weak weakSelf = self;
    [task setCompletionHandler:^(id result, NSError *error) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        
        if (result) {
            [blockSelf.results setObject:result forKey:key];
        } else {
            [blockSelf.results setObject:error forKey:key];
        }
        
        if ([blockSelf finished]) {
            [blockSelf complete];
        }
    }];
    return task;
}

- (BOOL)finished {
    return [self.tasks count] == [self.results count];
}

- (void)complete {
    if (self.completionHandler == nil) return;
    self.completionHandler(self.results, nil);
}

- (void)cancel {
    [super cancel];
    
    for (id key in self.tasks) {
        id <FATask> task = [self.tasks objectForKey:key];
        [task cancel];
    }
}

@end
