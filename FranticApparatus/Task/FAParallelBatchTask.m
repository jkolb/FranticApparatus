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

@property (nonatomic, strong) NSMutableDictionary *progress;
@property (nonatomic, strong) NSMutableDictionary *results;

@end



@implementation FAParallelBatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _progress = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_progress == nil) return nil;
    
    _results = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_results == nil) return nil;
    
    return self;
}

- (void)start {
    [super start];
    
    for (id key in [self allKeys]) {
        id <FATask> subtask = [self subtaskWithKey:key parameter:nil];
        [subtask start];
    }
}

- (BOOL)finished {
    return [[self allKeys] count] == [self.results count];
}

- (void)subtaskWithKey:(id)key didReportProgress:(id)progress {
    [self.progress setObject:progress forKey:key];
    [self reportProgress:[self.progress copy]];
}

- (void)subtaskWithKey:(id)key didFinishWithResult:(id)result {
    [self.results setObject:result forKey:key];
    
    if ([self finished]) {
        [self returnResult:self.results];
        [self finish];
    }
}

- (void)subtaskWithKey:(id)key didFinishWithError:(NSError *)error {
    [self.results setObject:error forKey:key];
    
    if ([self finished]) {
        [self returnResult:self.results];
        [self finish];
    }
}

- (void)cancel {
    [super cancel];
    
    for (id key in [self allKeys]) {
        id <FATask> subtask = [self subtaskForKey:key];
        [subtask cancel];
    }
}

@end
