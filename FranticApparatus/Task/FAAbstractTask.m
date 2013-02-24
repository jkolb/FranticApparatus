//
// FAAbstractTask.m
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



#import "FAAbstractTask.h"



@interface FAAbstractTask ()

@property BOOL cancelled;

@end



@implementation FAAbstractTask

- (void)start {
    if (self.onStart) self.onStart();
}

- (BOOL)isCancelled {
    return self.cancelled;
}

- (void)cancel {
    self.cancelled = YES;
}

- (void)setStartTarget:(id)target action:(SEL)action {
    id __weak weakTarget = target;
    typeof(self) __weak weakSelf = self;
    [self setOnStart:^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        id blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action];
    }];
}

- (void)setProgressTarget:(id)target action:(SEL)action {
    id __weak weakTarget = target;
    typeof(self) __weak weakSelf = self;
    [self setOnProgress:^(id progress) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        id blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action withObject:progress];
    }];
}

- (void)setResultTarget:(id)target action:(SEL)action {
    id __weak weakTarget = target;
    typeof(self) __weak weakSelf = self;
    [self setOnResult:^(id result) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        id blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action withObject:result];
    }];
}

- (void)setErrorTarget:(id)target action:(SEL)action {
    id __weak weakTarget = target;
    typeof(self) __weak weakSelf = self;
    [self setOnError:^(NSError *error) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        id blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action withObject:error];
    }];
}

- (void)setFinishTarget:(id)target action:(SEL)action {
    id __weak weakTarget = target;
    typeof(self) __weak weakSelf = self;
    [self setOnFinish:^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        id blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action];
    }];
}

- (void)reportProgress:(id)progress {
    if (self.onProgress) self.onProgress(progress);
}

- (void)returnResult:(id)result {
    if (self.onResult) self.onResult(result);
}

- (void)returnError:(NSError *)error {
    if (self.onError) self.onError(error);
}

- (void)finish {
    if (self.onFinish) self.onFinish();
}

- (void)invokeTarget:(id)target action:(SEL)action {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[target class] instanceMethodSignatureForSelector:action]];
    invocation.target = target;
    invocation.selector = action;
    [invocation invoke];
}

- (void)invokeTarget:(id)target action:(SEL)action withObject:(id)object {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[target class] instanceMethodSignatureForSelector:action]];
    invocation.target = target;
    invocation.selector = action;
    [invocation setArgument:&object atIndex:2];
    [invocation invoke];
}

@end
