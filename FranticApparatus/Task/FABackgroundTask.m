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



const FABackgroundTaskPriority FABackgroundTaskPriorityDefault = DISPATCH_QUEUE_PRIORITY_DEFAULT;
const FABackgroundTaskPriority FABackgroundTaskPriorityLowest = DISPATCH_QUEUE_PRIORITY_BACKGROUND;
const FABackgroundTaskPriority FABackgroundTaskPriorityLow = DISPATCH_QUEUE_PRIORITY_LOW;
const FABackgroundTaskPriority FABackgroundTaskPriorityMedium = DISPATCH_QUEUE_PRIORITY_DEFAULT;
const FABackgroundTaskPriority FABackgroundTaskPriorityHigh = DISPATCH_QUEUE_PRIORITY_HIGH;



@interface FABackgroundTask ()

@property FABackgroundTaskPriority priority;
@property (copy) FABackgroundTaskBlock block;

@end



@implementation FABackgroundTask

- (id)init {
    return [self initWithBlock:^id(id <FATask> blockTask, NSError **error) {
        return [NSNull null];
    }];
}

- (id)initWithBlock:(FABackgroundTaskBlock)block {
    return [self initWithPriority:FABackgroundTaskPriorityDefault block:block];
}

- (id)initWithPriority:(FABackgroundTaskPriority)priority block:(FABackgroundTaskBlock)block {
    self = [super init];
    if (self == nil) return nil;
    _priority = priority;
    _block = [block copy];
    if (_block == nil) return nil;
    return self;
}

- (void)didStart {
    FATypeOfSelf __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(self.priority, 0), ^{
        FATypeOfSelf blockSelf = weakSelf;
        if (blockSelf == nil) return;
        [blockSelf executeInBackground];
    });
}

- (void)executeInBackground {
    NSError *error = nil;
    id result = self.block(self, &error);
    [self completeWithResult:result error:error];
}

@end
