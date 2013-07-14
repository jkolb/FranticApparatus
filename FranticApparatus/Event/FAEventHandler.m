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



NS_INLINE FAEventHandlerBlock FAEventHandlerContextBlockMake(id context, FAEventHandlerContextBlock contextBlock);
NS_INLINE FAEventHandlerBlock FAEventHandlerTargetActionBlockMake(id target, SEL action);



@interface FAEventHandler ()

@property (nonatomic, strong, readonly) Class eventClass;
@property (nonatomic, copy, readonly) void (^block)(id event);

@end



@implementation FAEventHandler

+ (instancetype)handlerWithEventClass:(Class)eventClass block:(FAEventHandlerBlock)block {
    return [[self alloc] initWithEventClass:eventClass
                                      block:block];
}

+ (instancetype)handlerWithEventClass:(Class)eventClass context:(id)context block:(FAEventHandlerContextBlock)block {
    return [[self alloc] initWithEventClass:eventClass
                                      block:FAEventHandlerContextBlockMake(context, block)];
}

+ (instancetype)handlerWithEventClass:(Class)eventClass target:(id)target action:(SEL)action {
    return [[self alloc] initWithEventClass:eventClass
                                      block:FAEventHandlerTargetActionBlockMake(target, action)];
}

- (id)init {
    return [self initWithEventClass:[FAEvent class] block:^(id event) {}];
}

- (id)initWithEventClass:(Class)eventClass block:(FAEventHandlerBlock)block {
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

- (instancetype)onMainQueue {
    return [self onDispatchQueue:dispatch_get_main_queue()];
}

- (instancetype)onDispatchQueue:(dispatch_queue_t)dispatchQueue {
    void (^blockBlock)(id event) = self.block;
    return [[[self class] alloc] initWithEventClass:self.eventClass block:^(id event) {
        dispatch_async(dispatchQueue, ^{
            blockBlock(event);
        });
    }];
}



#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end



NS_INLINE FAEventHandlerBlock FAEventHandlerContextBlockMake(id context, FAEventHandlerContextBlock contextBlock) {
    id __weak weakContext = context;
    return ^(id event) {
        id blockContext = weakContext;
        if (blockContext == nil) return;
        contextBlock(blockContext, event);
    };
}

NS_INLINE FAEventHandlerBlock FAEventHandlerTargetActionBlockMake(id target, SEL action) {
    return FAEventHandlerContextBlockMake(target, ^(id blockContext, id event) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [blockContext performSelector:action withObject:event];
#pragma clang diagnostic pop
    });
}
