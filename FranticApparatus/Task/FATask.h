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

#import "FATaskEvent.h"



@protocol FATask;



/*!
 @enum FATaskEvent
 @abstract Constants used to indicate specific events in the lifecycle of a task.
 @constant FATaskEventStarted An event generated right after a task is started but just before it begins execution.
 @constant FATaskEventProgressed An event that indicates the task is reporting some partial result during execution. This event may occur more than once.
 @constant FATaskEventSucceeded An event that indicates that a task has successfully executed and has optionally generated a result.
 @constant FATaskEventFailed An event that indicates that a task has failed to execute and has optionally generated an error.
 @constant FATaskEventCancelled An event that indicates that a task was cancelled before fully executing.
 @constant FATaskEventFinished An event that indicates that the task has finished executing, no matter if due to success, failure, or cancellation.
 @discussion Events occur during the lifecycle of a task. An event will only occur at most once for a task unless it is FATaskEventProgressed. Callbacks can be associated with events so that the effects of a task's execution can affect the flow of an application.
 */
extern NSString * const FATaskEventTypeStart;
extern NSString * const FATaskEventTypeProgress;
extern NSString * const FATaskEventTypeResult;
extern NSString * const FATaskEventTypeError;
extern NSString * const FATaskEventTypeCancel;
extern NSString * const FATaskEventTypeFinish;



/*!
 @protocol FATask
 @abstract A protocol that provides a common interface for dealing with synchronous or asynchronous tasks.
 @discussion A task is a unit of work that optionally returns a result. Generally tasks have the following lifecycle: start, execute, finish. FATask provides a common interface for describing a task and being notified when important events in its lifecycle occur. You can register an event handler for when a task starts, progresses, succeeds, fails, is cancelled, and when it finishes. Multiple callbacks can be triggered for each event in a task's lifecycle. Tasks can be parameterized, either during initialization or when being started. Any parameter provided during intialization overrides any parameter provided when starting. Tasks can be cancelled at any time during their execution and you can check for early cancellation during your task's computations. Most importantly tasks are designed to be composable, this allows them to be wrapped to extend their functionality or executed in batches while still appearing as a single unit of work.
 */
@protocol FATask <NSObject>

/*!
 @method initWithParameter:
 @abstract The designated initializer.
 @param parameter
    A value used during the execution of the task to drive the results of its computations.
 @return Returns a task initialized with the provide parameter.
 @discussion Any parameter provided prevents any parameter passed into startWithParameter: from being used. Pass in nil, or use init instead, to not use a parameter or to be able to provide a parameter when starting.
 */
- (id)initWithParameter:(id)parameter;

/*!
 @method taskEvent:addCallback:
 @abstract Registers a callback block to be executed when a task event occurs.
 @param event
    The event that will trigger the callback.
 @param callback
    The block to execute.
 @discussion A way to execute a block when a lifecycle event occurs. Multiple callbacks and actions can be associated with a single event.
 */
- (void)eventType:(NSString *)type addHandler:(void (^)(FATaskEvent *event))handler;
- (void)eventType:(NSString *)type addTaskHandler:(void (^)(id blockTask, FATaskEvent *event))taskHandler;
- (void)eventType:(NSString *)type task:(id <FATask>)task addTaskHandler:(void (^)(id blockTask, FATaskEvent *event))taskHandler;

/*!
 @method addTarget:action:forTaskEvent:
 @abstract Registers an selector to be executed when a task event occurs.
 @param target
    The selector's message target.
 @param action
    The selector to execute.
 @param event
    The event that will trigger the action.
 @discussion A way to execute a specific method when a lifecycle event occurs. Multiple actions and callbacks can be associated with a single event.
 */
- (void)addTarget:(id)target action:(SEL)action forEventType:(NSString *)type;

- (NSSet *)registeredEvents;

- (void)triggerEventWithType:(NSString *)type payload:(id)payload;
- (void)forwardEventType:(NSString *)type toTask:(id <FATask>)task;

/*!
 @method parameter
 @return The parameter used during the execution of the task.
 @discussion If set during initialization this will return the parameter passed into initWithParameter:, otherwise it will be nil until after startWithParameter: is called when it will return the value passed into startWithParameter:.
 */
- (id)parameter;

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

@end
