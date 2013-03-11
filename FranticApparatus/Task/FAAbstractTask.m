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
#import "FATaskEvent.h"



@interface FAAbstractTask ()

@property BOOL cancelled;
@property (nonatomic, strong) id parameter;
@property (nonatomic, strong) NSMutableDictionary *handlersByEventType;

@end



@implementation FAAbstractTask

- (id)init {
    return [self initWithParameter:nil];
}

- (id)initWithParameter:(id)parameter {
    self = [super init];
    if (self == nil) return nil;
    
    _handlersByEventType = [[NSMutableDictionary alloc] initWithCapacity:1];
    if (_handlersByEventType == nil) return nil;
    
    _parameter = parameter;
    
    return self;
}

- (void)start {
    [self startWithParameter:self.parameter];
}

- (void)startWithParameter:(id)parameter {
    if (self.parameter == nil) self.parameter = parameter;
    [self triggerEventWithType:FATaskEventTypeStart payload:nil];
}

- (BOOL)isCancelled {
    return self.cancelled;
}

- (void)eventType:(NSString *)type addHandler:(void (^)(FATaskEvent *event))handler {
    NSMutableArray *handlers = [self.handlersByEventType objectForKey:type];
    
    if (handlers == nil) {
        handlers = [[NSMutableArray alloc] initWithCapacity:1];
        [self.handlersByEventType setObject:handlers forKey:type];
    }
    
    [handlers addObject:handler];
}

- (void)eventType:(NSString *)type addTaskHandler:(void (^)(id blockTask, FATaskEvent *event))taskHandler {
    [self eventType:type addHandler:[[self class] handlerWithTask:self taskHandler:taskHandler]];
}

- (void)eventType:(NSString *)type task:(id <FATask>)task addTaskHandler:(void (^)(id blockTask, FATaskEvent *event))taskHandler {
    [self eventType:type addHandler:[[self class] handlerWithTask:task taskHandler:taskHandler]];
}

- (void)addTarget:(id)target action:(SEL)action forEventType:(NSString *)type {
    __typeof__(target) weakTarget = target;
    [self eventType:type addTaskHandler:^(id blockTask, FATaskEvent *event) {
        __typeof__(target) blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockTask invokeTarget:blockTarget action:action withObject:event];
    }];
}

+ (void (^)(FATaskEvent *))handlerWithTask:(id <FATask>)task taskHandler:(void (^)(id blockTask, FATaskEvent *event))taskHandler {
    __typeof__(task) __weak weakTask = task;
    return ^(FATaskEvent *event) {
        __typeof__(task) blockTask = weakTask;
        if (blockTask == nil || [blockTask isCancelled]) return;
        taskHandler(blockTask, event);
    };
}

- (NSSet *)registeredEvents {
    return [NSSet setWithArray:[self.handlersByEventType allKeys]];
}

- (void)triggerEventWithType:(NSString *)type payload:(id)payload {
    FATaskEvent *event = [[FATaskEvent alloc] initWithType:type source:self payload:payload];
    
    for (void (^callback)(FATaskEvent *) in [self callbacksForEventType:type]) {
        if ([self isCancelled]) break;
        callback(event);
    }
}

- (void)forwardEventType:(NSString *)type toTask:(id <FATask>)task {
    [self eventType:type addTaskHandler:^(id blockTask, FATaskEvent *event) {
        [blockTask triggerEventWithType:event.type payload:event.payload];
    }];
}

- (NSArray *)callbacksForEventType:(NSString *)type {
    return [self.handlersByEventType objectForKey:type];
}

- (void)cancel {
    self.cancelled = YES;
    [self triggerEventWithType:FATaskEventTypeCancel payload:nil];
    [self triggerEventWithType:FATaskEventTypeFinish payload:nil];
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
