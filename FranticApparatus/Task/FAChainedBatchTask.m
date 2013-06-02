//
// FAChainedBatchTask.m
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



#import "FAChainedBatchTask.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskFactory.h"



@interface FAChainedBatchTask ()

@property (nonatomic, copy, readonly) NSArray *taskFactories;

@end



@implementation FAChainedBatchTask

- (void)start {
    [super start];
    [self startTaskAtIndex:0 withLastResult:nil];
}

- (void)startTaskAtIndex:(NSUInteger)index withLastResult:(id)lastResult {
    FATaskFactory *taskFactory = [self.taskFactories objectAtIndex:index];
    id <FATask> task = [taskFactory taskWithLastResult:lastResult];
    [task start];
}

- (void)handleTaskResultEvent:(FATaskResultEvent *)event forIndex:(NSUInteger)index {
    NSUInteger nextIndex = index + 1;
    
    if (nextIndex < [self.taskFactories count]) {
        [self startTaskAtIndex:nextIndex withLastResult:event.result];
    } else {
        [self finish];
    }
}

- (void)handleTaskErrorEvent:(FATaskErrorEvent *)event forIndex:(NSUInteger)index {
    [self forwardEvent:event];
    [self finish];
}

@end
