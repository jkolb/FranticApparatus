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

@property (nonatomic, strong) id parameter;
@property (nonatomic, strong) id <FATask> currentTask;

@end



@implementation FAChainedBatchTask

- (id)init {
    return [self initWithParameter:nil];
}

- (id)initWithParameter:(id)parameter {
    self = [super init];
    if (self == nil) return nil;
    
    _parameter = parameter;
    
    return self;
}

- (id)addKey {
    return [NSNumber numberWithUnsignedInteger:[[self allKeys] count]];
}

- (void)addSubtask:(id <FATask>)subtask {
    [self setSubtask:subtask forKey:[self addKey]];
}

- (void)addSubtaskFactory:(id <FATask> (^)(id parameter))subtaskFactory {
    [self setSubtaskFactory:subtaskFactory forKey:[self addKey]];
}

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    [self startSubtaskForKey:[self startKey] withParameter:parameter];
}

- (void)startSubtaskForKey:(id)key withParameter:(id)parameter {
    self.currentTask = [self subtaskWithKey:key parameter:parameter];
    
    if (self.currentTask != nil) {
        if ([self.currentTask parameter] == nil) {
            [self.currentTask startWithParameter:parameter];
        } else {
            [self.currentTask start];
        }
    } else {
        [self returnResult:parameter];
        [self finish];
    }
}

- (id)startKey {
    return [NSNumber numberWithUnsignedInteger:0];
}

- (id)keyAfterKey:(id)key withResult:(id)result {
    NSUInteger subtaskIndex = [key unsignedIntegerValue];
    NSUInteger nextSubtaskIndex = subtaskIndex + 1;
    return [NSNumber numberWithUnsignedInteger:nextSubtaskIndex];
}

- (void)subtaskWithKey:(id)key didReportProgress:(id)progress {
    
}

- (void)subtaskWithKey:(id)key didFinishWithResult:(id)result {
    id nextKey = [self keyAfterKey:key withResult:result];
    [self startSubtaskForKey:nextKey withParameter:result];
}

- (void)subtaskWithKey:(id)key didFinishWithError:(NSError *)error {
    [self returnError:error];
    [self finish];
}

- (void)cancel {
    [super cancel];
    [self.currentTask cancel];
}

@end
