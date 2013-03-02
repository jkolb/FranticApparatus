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



@protocol FATask;



/*!
 @enum FATaskEvent
 @abstract Constants used to indicate specific events in the lifecycle of a task.
 @constant FATaskEventStarted An event generated right after a task is started but just before it begins execution.
 @constant FATaskEventProgressed An event that indicates the task is reporting some partial result during execution. This event may occur more than once.
 @constant FATaskEventSucceeded An event that indicates that a task has successfully executed and has optionally generated a result.
 @constant FATaskEventFailed An event that indicates that a task has failed to execute and has optionally generated an error.
 @constant FATaskEventCanceled An event that indicates that a task was canceled before fully executing.
 @constant FATaskEventFinished An event that indicates that the task has finished executing, no matter if due to success, failure, or cancellation.
 @discussion Events occur during the lifecycle of a task. An event will only occur at most once for a task unless it is FATaskEventProgressed. Callbacks can be associated with events so that the effects of a task's execution can affect the flow of an application.
 */
typedef NS_ENUM(NSInteger, FATaskEvent) {
    FATaskEventStarted    = 0,
    FATaskEventProgressed = 1,
    FATaskEventSucceeded  = 2,
    FATaskEventFailed     = 3,
    FATaskEventCanceled   = 4,
    FATaskEventFinished   = 5,
};

/*!
 @enum FATaskStatus
 @abstract Constants used to report the final status of a task.
 @constant FATaskStatusPending Status used to indicate a task has not finished yet.
 @constant FATaskStatusSuccess Status when a task succeeds and optionally generates a result.
 @constant FATaskStatusFailure Status when a task fails and optionally generates an error.
 @constant FATaskStatusCanceled Status when a task is canceled before it completes execution.
 @description Before a task finishes its status will be FATaskStatusPending. Once a task is finished its status will be one of the following: FATaskStatusSuccess, FATaskStatusFailure, or FATaskStatusCanceled depending on the results of the task's execution.
 */
typedef NS_ENUM(NSInteger, FATaskStatus) {
    FATaskStatusPending  = 0,
    FATaskStatusSuccess  = 1,
    FATaskStatusFailure  = 2,
    FATaskStatusCanceled = 3,
};



/*!
 @typedef FATaskCallback
 @abstract A block used to perform an action when an important event in a task's lifecyle is triggered.
 */
typedef void (^FATaskCallback)(id object);



/*!
 @protocol FATask
 @abstract A protocol that provides a common interface for dealing with synchronous or asynchronous tasks.
 @discussion A task is a unit of work that optionally returns a result. Generally tasks have the following lifecycle: start, execute, finish. FATask provides a common interface for describing a task and being notified when important events in its lifecycle occur. You can register an event handler for when a task starts, progresses, succeeds, fails, is canceled, and when it finishes. Multiple callbacks can be triggered for each event in a task's lifecycle. Tasks can be parameterized, either during initialization or when being started. Any parameter provided during intialization overrides any parameter provided when starting. Tasks can be canceled at any time during their execution and you can check for early cancellation during your task's computations. Most importantly tasks are designed to be composable, this allows them to be wrapped to extend their functionality or executed in batches while still appearing as a single unit of work.
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
 @discussion A way to execute a block when a lifecycle event occurs. Multiple callbacks can be associated with a single event. A callback will not be executed if the task no longer exists in memory or if the task has been canceled.
 */
- (void)taskEvent:(FATaskEvent)event addCallback:(FATaskCallback)callback;

/*!
 @method addTarget:action:forTaskEvent:
 @abstract Registers an selector to be executed when a task event occurs.
 @param target
    The selector's message target.
 @param action
    The selector to execute.
 @param event
    The event that will trigger the action.
 @discussion A way to execute a specific method when a lifecycle event occurs. Multiple actions can be associated with a single event. An action will not be executed if the task no longer exists in memory or if the task has been canceled.
 */
- (void)addTarget:(id)target action:(SEL)action forTaskEvent:(FATaskEvent)event;

/*!
 @method hasCallbackForTaskEvent:
 @abstract Determine if any callback or action has been registered for an event.
 @param event
    The event to check.
 @return YES if an action or callback has been registered, NO if not.
 */
- (BOOL)hasCallbackForTaskEvent:(FATaskEvent)event;

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
 @discussion If the task was initialized with a parameter this parameter will be ignored. Pass in nil or just call start to execute the task without a parameter.
 */
- (void)startWithParameter:(id)parameter;

- (FATaskStatus)status;

- (BOOL)isCancelled;
- (void)cancel;

@end
