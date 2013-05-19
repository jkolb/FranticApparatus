//
// FAEventHandler.m
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



#import "FAEventHandler.h"
#import "FAEventDispatcher.h"
#import "FAEvent.h"



@interface FAEventHandler ()

@property (nonatomic, strong) Class eventClass;
@property (nonatomic, copy) void (^block)(id event);

@end



@implementation FAEventHandler

+ (id)eventHandlerWithEventClass:(Class)eventClass block:(void (^)(id event))block {
    return [[self alloc] initWithEventClass:eventClass block:block];
}

+ (id)eventHandlerWithEventClass:(Class)eventClass context:(id)context block:(void (^)(id context, id event))block {
    return [[self alloc] initWithEventClass:eventClass block:[self blockForContext:context block:block]];
}

+ (id)eventHandlerWithEventClass:(Class)eventClass target:(id)target action:(SEL)action {
    return [[self alloc] initWithEventClass:eventClass block:[self blockForContext:target block:^(id context, id event) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [context performSelector:action withObject:event];
#pragma clang diagnostic pop
    }]];
}

+ (id)eventHandlerWithEventClass:(Class)eventClass dispatcher:(id <FAEventDispatcher>)dispatcher {
    return [[self alloc] initWithEventClass:eventClass block:[self blockForContext:dispatcher block:^(id <FAEventDispatcher> blockDispatcher, id event) {
        [blockDispatcher forwardEvent:event];
    }]];
}

- (id)init {
    return [self initWithEventClass:nil block:nil];
}

- (id)initWithEventClass:(Class)eventClass block:(void (^)(id event))block {
    self = [super init];
    if (self == nil) return nil;
    _eventClass = eventClass;
    if (_eventClass == nil) return nil;
    _block = block;
    if (_block == nil) return nil;
    return self;
}

- (BOOL)canHandleEvent:(FAEvent *)event {
    return [[event class] isSubclassOfClass:self.eventClass];
}

- (void)handleEvent:(FAEvent *)event {
    NSAssert([self canHandleEvent:event], @"Unable to handle %@ with %@ handler", [event class], self.eventClass);
    self.block(event);
}

+ (void (^)(id))blockForContext:(id)context block:(void (^)(id context, id event))block {
    id __weak weakContext = context;
    return ^(id event) {
        id blockContext = weakContext;
        if (blockContext == nil) return;
        if ([blockContext respondsToSelector:@selector(isCancelled)] && [blockContext isCancelled]) return;
        block(blockContext, event);
    };
}

@end
