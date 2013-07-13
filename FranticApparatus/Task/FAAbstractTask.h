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



@interface FAAbstractTask : FAEventDispatcher <FATask>

- (void)willStart;
- (void)didStart;

- (void)willCancel;
- (void)willFinish;

- (void)synchronizeWithBlock:(void (^)(id <FATask> blockTask))block;

- (void)willFinishWithResult:(id)result error:(NSError *)error;

- (void)onResultEventFromTask:(id <FATask>)task execute:(FATaskEventBlock)block;
- (void)onErrorEventFromTask:(id <FATask>)task execute:(FATaskEventBlock)block;
- (void)onFinishEventFromTask:(id <FATask>)task execute:(FATaskEventBlock)block;

- (void)onEvent:(Class)event fromTask:(id <FATask>)task execute:(FATaskEventBlock)block;

@property (copy) NSString *taskDescription;

@end
