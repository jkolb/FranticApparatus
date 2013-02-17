//
// FAGenericTask.m
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



#import "FAGenericTask.h"



@implementation FAGenericTask

- (void)start {
    dispatch_queue_t queue = self.queue;
    
    if (queue == nil) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    typeof(self) __weak weakSelf = self;
    dispatch_async(queue, ^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf run];
    });
}

- (void)run {
    NSError *error = nil;
    id result = [self generateResultWithError:&error];
    if ([self isCancelled]) return;
    if (self.completionHandler == nil) return;
    self.completionHandler(result, error);
}

- (id)generateResultWithError:(NSError **)error {
    return [NSNull null];
}

@end
