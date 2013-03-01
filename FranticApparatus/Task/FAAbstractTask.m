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

- (id)parameter {
    return nil;
}

- (void)start {
    [self startWithParameter:[self parameter]];
}

- (void)startWithParameter:(id)parameter {
    if (self.onStart) self.onStart(self);
}

- (BOOL)isCancelled {
    return self.cancelled;
}

- (void)cancel {
    self.cancelled = YES;
    if (self.onCancel) self.onCancel(self);
    [self finish];
}

- (void)reportProgress:(id)progress {
    if (self.onProgress) self.onProgress(progress);
}

- (void)succeedWithResult:(id)result {
    if (self.onResult) self.onResult(result);
}

- (void)failWithError:(id)error {
    if (self.onError) self.onError(error);
}

- (void)finish {
    if (self.onFinish) self.onFinish(self);
}

- (void)setTarget:(id)target action:(SEL)action forTaskEvent:(FATaskEvent)event {
    FACallback callback = [self callbackForTarget:target action:action];
    
    switch (event) {
        case FATaskEventStart:
            [self setOnStart:callback];
            break;
            
        case FATaskEventProgress:
            [self setOnProgress:callback];
            break;
            
        case FATaskEventResult:
            [self setOnResult:callback];
            break;
            
        case FATaskEventError:
            [self setOnError:callback];
            break;
            
        case FATaskEventCancel:
            [self setOnCancel:callback];
            break;
            
        case FATaskEventFinish:
            [self setOnFinish:callback];
            break;
            
        default:
            break;
    }
}

- (FACallback)callbackForTarget:(id)target action:(SEL)action {
    typeof(self) __weak weakSelf = self;
    id __weak weakTarget = target;
    return ^(id object) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        id blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action withObject:object];
    };
}

- (void)invokeTarget:(id)target action:(SEL)action withObject:(id)object {
    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:action];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = action;
    [invocation setArgument:&object atIndex:2];
    [invocation invoke];
}

@end
