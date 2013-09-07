//
// FAAbstractTask.h
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



#import <Foundation/Foundation.h>

#import "FATask.h"
#import "FATaskEvent.h"
#import "FAEventDispatcher.h"



#define FATypeOfSelf  __typeof__(self)



@class FATaskCompleteEvent;



typedef void (^FATaskSynchronizeBlock)(id <FATask> blockTask);
typedef void (^FATaskCompleteSynchronizeBlock)(id <FATask> blockTask, FATaskCompleteEvent *event);



@interface FAAbstractTask : FAEventDispatcher <FATask>

@property (copy) NSString *taskDescription;

- (void)willStart;
- (void)didStart;

- (void)willCancel;

- (void)completeWithResult:(id)result error:(NSError *)error;
- (void)willComplete;



#pragma mark - Task synchronization

@property (nonatomic, strong, readonly) dispatch_queue_t synchronizationQueue;

- (void)synchronizeWithBlock:(FATaskSynchronizeBlock)block;
- (void)onCompleteTask:(id <FATask>)task synchronizeWithBlock:(FATaskCompleteSynchronizeBlock)block;

@end
