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
    [self triggerEventWithType:FATaskEventTypeStart payload:nil];
}

- (BOOL)isCancelled {
    return self.cancelled;
}

- (void)eventType:(NSString *)type addHandler:(void (^)(FATaskEvent *event))callback {
    NSMutableArray *callbacks = [self.callbacks objectForKey:type];
    
    if (callbacks == nil) {
        callbacks = [[NSMutableArray alloc] initWithCapacity:1];
        [self.callbacks setObject:callbacks forKey:type];
    }
    
    [callbacks addObject:[self callbackOnMainThread:callback]];
}

- (void)eventType:(NSString *)type addSafeHandler:(void (^)(id blockSelf, FATaskEvent *event))handler {
    __typeof__(self) __weak weakSelf = self;
    [self eventType:type addHandler:^(FATaskEvent *event) {
        __typeof__(self) blockSelf = weakSelf;
        if (blockSelf == nil || [blockSelf isCancelled]) return;
        handler(blockSelf, event);
    }];
}

- (void)addTarget:(id)target action:(SEL)action forEventType:(NSString *)type {
    __typeof__(target) weakTarget = target;
    [self eventType:type addSafeHandler:^(id blockSelf, FATaskEvent *event) {
        __typeof__(target) blockTarget = weakTarget;
        if (blockTarget == nil) return;
        [blockSelf invokeTarget:blockTarget action:action withObject:event];
    }];
}

- (NSSet *)registeredEvents {
    return [NSSet setWithArray:[self.callbacks allKeys]];
}

- (void)triggerEventWithType:(NSString *)type payload:(id)payload {
    FATaskEvent *event = [[FATaskEvent alloc] initWithType:type source:self payload:payload];
    
    for (void (^callback)(FATaskEvent *) in [self callbacksForEventType:type]) {
        if ([self isCancelled]) break;
        callback(event);
    }
}

- (NSArray *)callbacksForEventType:(NSString *)type {
    return [self.callbacks objectForKey:type];
}

- (void)cancel {
    self.cancelled = YES;
    [self triggerEventWithType:FATaskEventTypeCancel payload:nil];
    [self triggerEventWithType:FATaskEventTypeFinish payload:nil];
}

- (void (^)(FATaskEvent *))callbackOnMainThread:(void (^)(FATaskEvent *))callback {
    return ^(FATaskEvent *event) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(event);
        });
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
