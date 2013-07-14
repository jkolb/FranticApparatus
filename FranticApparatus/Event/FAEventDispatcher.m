//
// FAEventDispatcher.m
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



#import "FAEventDispatcher.h"
#import "FAEventHandler.h"
#import "FAEvent.h"



@interface FAEventDispatcher ()

@property (nonatomic, strong) NSMutableArray *handlers;
@property (strong) NSLock *handlerLock;

@end



@implementation FAEventDispatcher

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    _handlers = [[NSMutableArray alloc] initWithCapacity:4];
    if (_handlers == nil) return nil;
    _handlerLock = [[NSLock alloc] init];
    if (_handlerLock == nil) return nil;
    return self;
}

- (void)addHandler:(FAEventHandler *)handler {
    [self.handlerLock lock];
    [self.handlers addObject:handler];
    [self.handlerLock unlock];
}

- (void)removeHandler:(FAEventHandler *)handler {
    [self.handlerLock lock];
    [self.handlers removeObjectIdenticalTo:handler];
    [self.handlerLock unlock];
}

- (void)removeAllHandlers {
    [self.handlerLock lock];
    [self.handlers removeAllObjects];
    [self.handlerLock unlock];
}

- (void)dispatchEvent:(FAEvent *)event {
    [self.handlerLock lock];
    for (FAEventHandler *handler in self.handlers) {
        if (![handler canHandleEvent:event]) continue;
        [handler handleEvent:event];
    }
    [self.handlerLock unlock];
}

@end
