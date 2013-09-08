//
// FABatchTask.m
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



#import "FABatchTask.h"
#import "FATaskStartEvent.h"
#import "FATaskProgressEvent.h"
#import "FATaskFinishEvent.h"



@implementation FABatchTask

- (void)onStartSubtask:(id <FATask>)subtask synchronizeWithBlock:(FATaskStartSynchronizeBlock)block {
    [subtask addHandler:[FATaskStartEvent handlerWithContext:self block:^(FATypeOfSelf blockContext, FATaskStartEvent *event) {
        [blockContext synchronizeWithBlock:^(FABatchTask *blockTask) {
            if (block) block(blockTask, event);
        }];
    }]];
}

- (void)onFinishSubtask:(id <FATask>)subtask synchronizeWithBlock:(FATaskFinishSynchronizeBlock)block {
    [subtask addHandler:[FATaskFinishEvent handlerWithContext:self block:^(FATypeOfSelf blockContext, FATaskFinishEvent *event) {
        [blockContext synchronizeWithBlock:^(FABatchTask *blockTask) {
            if (block) block(blockTask, event);
        }];
    }]];
}

- (void)passThroughProgressEventsFromSubtask:(id <FATask>)subtask {
    [subtask addHandler:[FATaskProgressEvent handlerWithContext:self block:^(FATypeOfSelf blockContext, FATaskProgressEvent *event) {
        [blockContext synchronizeWithBlock:^(id <FATask> blockTask) {
            [blockTask dispatchEvent:[event passThroughToSource:blockTask]];
        }];
    }]];
}

@end
