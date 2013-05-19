//
// FATask.h
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

#import "FAEventDispatcher.h"



/*!
 @protocol FATask
 @abstract A protocol that provides a common interface for dealing with synchronous or asynchronous tasks.
 @discussion A task is a unit of work that optionally returns a result. Generally tasks have the following lifecycle: start, execute, finish. FATask provides a common interface for describing a task and being notified when important events in its lifecycle occur. You can register an event handler for when a task starts, progresses, succeeds, fails, is cancelled, and when it finishes. Multiple callbacks can be triggered for each event in a task's lifecycle. Tasks can be parameterized, either during initialization or when being started. Any parameter provided during intialization overrides any parameter provided when starting. Tasks can be cancelled at any time during their execution and you can check for early cancellation during your task's computations. Most importantly tasks are designed to be composable, this allows them to be wrapped to extend their functionality or executed in batches while still appearing as a single unit of work.
 */
@protocol FATask <FAEventDispatcher>

/*!
 @method start
 @abstract Starts the task
 @discussion This method starts the task either with the parameter set during initialization or nil.
 */
- (void)start;

/*!
 @method startWithParameter:
 @abstract Starts the task with a specific parameter.
 @param parameter
    The parameter to use during the tasks computations, or nil.
 @discussion If the task was initialized with a parameter this parameter will be ignored. Pass in nil to execute the task without a parameter (as long as one hasn't been set during initialization).
 */
- (void)startWithParameter:(id)parameter;

/*!
 @method isCancelled
 @return Returns YES if the tasks has finished due to early cancellation, otherwise returns NO.
 @discussion This method can be periodically checked during execution of a task to exit long running computations when the task has been cancelled early.
 */
- (BOOL)isCancelled;

/*!
 @method cancel
 @abstract Cancel execution of the task.
 @discussion This method triggers events FATaskEventCancelled and then FATaskEventFinished. Execution of the task will still proceed until detection of the cancellation occurs which should eliminate any extra work from being done. Long running tasks should periodically check the value from isCancelled and stop processing when it returns YES.
 */
- (void)cancel;

- (void)finish;

@end
