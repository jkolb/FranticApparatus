//
// FAUITask.m
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



#import "FAUITask.h"
#import "FAAbstractTask.h"



@interface FAUITask ()

@property (nonatomic, strong) id backgroundParameter;

@end



@implementation FAUITask

- (id)init {
    return [self initWithParameter:nil];
}

- (id)initWithParameter:(id)parameter {
    self = [super init];
    if (self == nil) return nil;
    
    _backgroundParameter = parameter;
    
    return self;
}

- (void)start {
    [self startWithParameter:self.backgroundParameter];
}

- (void)startWithParameter:(id)parameter {
    [self.backgroundTask startWithParameter:parameter];
}

- (id)parameter {
    return [self.backgroundTask parameter];
}

- (void)eventType:(NSString *)type addHandler:(void (^)(FATaskEvent *))handler {
    [self.backgroundTask eventType:type addHandler:[self handlerOnMainThread:handler]];
}

- (void)eventType:(NSString *)type addTaskHandler:(void (^)(id, FATaskEvent *))taskHandler {
    [self.backgroundTask eventType:type addHandler:[self handlerOnMainThread:[FAAbstractTask handlerWithTask:self taskHandler:taskHandler]]];
}

- (void)eventType:(NSString *)type task:(id<FATask>)task addTaskHandler:(void (^)(id, FATaskEvent *))taskHandler {
    [self.backgroundTask eventType:type addHandler:[self handlerOnMainThread:[FAAbstractTask handlerWithTask:task taskHandler:taskHandler]]];
}

- (void)addTarget:(id)target action:(SEL)action forEventType:(NSString *)type {
    __typeof__(target) weakTarget = target;
    [self eventType:type addTaskHandler:^(id blockTask, FATaskEvent *event) {
        __typeof__(target) blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockTask invokeTarget:blockTarget action:action withObject:event];
    }];
}

- (void (^)(FATaskEvent *))handlerOnMainThread:(void (^)(FATaskEvent *))handler {
    return ^(FATaskEvent *event) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(event);
        });
    };
}

- (void)triggerEventWithType:(NSString *)type payload:(id)payload {
    [self.backgroundTask triggerEventWithType:type payload:payload];
}

- (void)forwardEventType:(NSString *)type toTask:(id <FATask>)task {
    [self.backgroundTask forwardEventType:type toTask:task];
}

- (NSSet *)registeredEventTypes {
    return [self.backgroundTask registeredEventTypes];
}

- (BOOL)isCancelled {
    return [self.backgroundTask isCancelled];
}

- (void)cancel {
    [self.backgroundTask cancel];
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
