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



@implementation FAChainedBatchTask

- (void)configureTask:(id<FATask>)task withKey:(id)key {
    [task eventType:FATaskEventTypeResult addSafeHandler:^(__typeof__(self) blockSelf, FATaskEvent *event) {
        [blockSelf advanceToNextKey];
        
        if ([blockSelf isFinished]) {
            [blockSelf triggerEventWithType:FATaskEventTypeResult payload:event.payload];
            [blockSelf triggerEventWithType:FATaskEventTypeFinish payload:nil];
        } else {
            [blockSelf startTaskForKey:[blockSelf currentKey] withParameter:event.payload];
        }
    }];
    
    [task eventType:FATaskEventTypeError addSafeHandler:^(__typeof__(self) blockSelf, FATaskEvent *event) {
        [blockSelf triggerEventWithType:FATaskEventTypeError payload:event.payload];
        [blockSelf triggerEventWithType:FATaskEventTypeFinish payload:nil];
    }];
}

@end
