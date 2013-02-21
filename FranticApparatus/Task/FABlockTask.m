//
// FABlockTask.m
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



#import "FABlockTask.h"



@interface FABlockTask ()

@property (nonatomic, copy) id (^block)(NSError **error);

@end



@implementation FABlockTask

- (id)initWithQueue:(dispatch_queue_t)queue {
    return [self initWithQueue:queue block:^id(NSError *__autoreleasing *error) {
        return [NSNull null];
    }];
}

- (id)initWithMainQueueBlock:(id (^)(NSError **error))block {
    return [self initWithQueue:[[self class] mainQueue] block:block];
}

- (id)initWithHighPriorityQueueBlock:(id (^)(NSError **error))block {
    return [self initWithQueue:[[self class] highPriorityQueue] block:block];
}

- (id)initWithDefaultPriorityQueueBlock:(id (^)(NSError **error))block {
    return [self initWithQueue:[[self class] defaultPriorityQueue] block:block];
}

- (id)initWithLowPriorityQueueBlock:(id (^)(NSError **error))block {
    return [self initWithQueue:[[self class] lowPriorityQueue] block:block];
}

- (id)initWithBackgroundPriorityQueueBlock:(id (^)(NSError **error))block {
    return [self initWithQueue:[[self class] backgroundPriorityQueue] block:block];
}

- (id)initWithQueue:(dispatch_queue_t)queue block:(id (^)(NSError **error))block {
    self = [super initWithQueue:queue];
    if (self == nil) return nil;
    
    _block = block;
    if (_block == nil) return nil;
    
    return self;
}

- (void)main {
    NSError *error = nil;
    id result = self.block(&error);
    if ([self isCancelled]) return;
    if (self.completionHandler == nil) return;
    self.completionHandler(result, error);
}

@end
