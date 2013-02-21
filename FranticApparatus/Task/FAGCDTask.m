//
// FAGCDTask.m
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



#import "FAGCDTask.h"



@interface FAGCDTask ()

@property (nonatomic, strong) dispatch_queue_t queue;

@end



@implementation FAGCDTask

+ (dispatch_queue_t)mainQueue {
    return dispatch_get_main_queue();
}

+ (dispatch_queue_t)highPriorityQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

+ (dispatch_queue_t)defaultPriorityQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

+ (dispatch_queue_t)lowPriorityQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

+ (dispatch_queue_t)backgroundPriorityQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

- (id)init {
    return [self initWithDefaultPriorityQueue];
}

- (id)initWithMainQueue {
    return [self initWithQueue:[[self class] mainQueue]];
}

- (id)initWithHighPriorityQueue {
    return [self initWithQueue:[[self class] highPriorityQueue]];
}

- (id)initWithDefaultPriorityQueue {
    return [self initWithQueue:[[self class] defaultPriorityQueue]];
}

- (id)initWithLowPriorityQueue {
    return [self initWithQueue:[[self class] lowPriorityQueue]];
}

- (id)initWithBackgroundPriorityQueue {
    return [self initWithQueue:[[self class] backgroundPriorityQueue]];
}

- (id)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self == nil) return nil;
    
    _queue = queue;
    if (_queue == nil) return nil;
    
    return self;
}

- (void)start {
    typeof(self) __weak weakSelf = self;
    dispatch_async(self.queue, ^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf main];
    });
}

- (void)main {
}

@end
