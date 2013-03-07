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

@property (nonatomic) FATaskStatus status;
@property (nonatomic, strong) id parameter;
@property (nonatomic, strong) NSMutableDictionary *callbacks;

@end



@implementation FAAbstractTask

- (id)init {
    return [self initWithParameter:nil];
}

- (id)initWithParameter:(id)parameter {
    self = [super init];
    if (self == nil) return nil;
    
    _callbacks = [[NSMutableDictionary alloc] initWithCapacity:1];
    if (_callbacks == nil) return nil;
    
    _parameter = parameter;
    
    return self;
}

- (void)start {
    [self startWithParameter:self.parameter];
}

- (void)startWithParameter:(id)parameter {
    if (self.parameter == nil) self.parameter = parameter;
    [self triggerEvent:FATaskEventStarted withObject:self];
}

- (BOOL)isCancelled {
    return self.status == FATaskStatusCancelled;
}

- (void)taskEvent:(NSString *)event addCallback:(FATaskCallback)callback {
    NSMutableArray *callbacks = [self.callbacks objectForKey:event];
    
    if (callbacks == nil) {
        callbacks = [[NSMutableArray alloc] initWithCapacity:1];
        [self.callbacks setObject:callbacks forKey:event];
    }
    
    [callbacks addObject:[callback copy]];
}

- (void)addTarget:(id)target action:(SEL)action forTaskEvent:(NSString *)event {
    [self taskEvent:event addCallback:[self callbackForTarget:target action:action]];
}

- (NSSet *)registeredEvents {
    return [NSSet setWithArray:[self.callbacks allKeys]];
}

- (void)triggerEvent:(NSString *)event withObject:(id)object {
    for (FATaskCallback callback in [self callbacksForTaskEvent:event]) {
        if ([self isCancelled]) break;
        callback(object);
    }
}

- (NSArray *)callbacksForTaskEvent:(NSString *)event {
    return [self.callbacks objectForKey:event];
}

- (void)cancel {
    [self triggerEvent:FATaskEventCancelled withObject:self];
    [self finishWithStatus:FATaskStatusCancelled];
}

- (void)reportProgress:(id)progress {
    [self triggerEvent:FATaskEventProgressed withObject:progress];
}

- (void)succeedWithResult:(id)result {
    [self triggerEvent:FATaskEventSucceeded withObject:result];
    [self finishWithStatus:FATaskStatusSuccess];
}

- (void)failWithError:(id)error {
    [self triggerEvent:FATaskEventFailed withObject:error];
    [self finishWithStatus:FATaskStatusFailure];
}

- (void)finishWithStatus:(FATaskStatus)status {
    self.status = status;
    [self triggerEvent:FATaskEventFinished withObject:self];
}

- (FATaskCallback)callbackForTarget:(id)target action:(SEL)action {
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
