//
// FABackgroundTask.m
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



#import "FABackgroundTask.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"



@interface FABackgroundTask ()

@property (nonatomic, copy) FABackgroundTaskBlock block;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

@end



@implementation FABackgroundTask

- (id)init {
    return [self initWithBlock:^id(id<FATask> blockTask, NSError **error) {
        return [NSNull null];
    }];
}

- (id)initWithBlock:(FABackgroundTaskBlock)block {
    self = [super init];
    if (self == nil) return nil;
    _block = block;
    if (_block == nil) return nil;
    return self;
}

- (dispatch_queue_t)backgroundQueue {
    switch (self.priority) {
        case FABackgroundTaskPriorityHigh:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            
        case FABackgroundTaskPriorityLow:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            
        case FABackgroundTaskPriorityLowest:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            
        case FABackgroundTaskPriorityDefault:
        case FABackgroundTaskPriorityMedium:
        default:
            return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
}

- (void)didStart {
    __typeof__(self) __weak weakSelf = self;
    dispatch_async([self backgroundQueue], ^{
        __typeof__(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        [blockSelf executeInBackground];
    });
}

- (void)executeInBackground {
    NSError *error = nil;
    self.result = self.block(self, &error);
    self.error = error;
    [self finish];
}

- (void)willFinish {
    if (self.result == nil) {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:self.error]];
    } else {
        [self dispatchEvent:[FATaskResultEvent eventWithSource:self result:self.result]];
    }
}

@end
