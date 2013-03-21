# [FranticApparatus 0.3](https://github.com/jkolb/FranticApparatus)

Asynchronous processing is the future, so it needs to be made as easy as possible to include in your applications. I posit that all iOS user interfaces should only make asynchronous calls into their logic layers, and only respond to events from the user or from the logic layer to make things happen. FranticApparatus is designed with that in mind.

## Overview

FranticApparatus is a composable task framework for iOS. Tasks are units of work that execute, optionally generate a result, and trigger events during important points during their life-cycle. Tasks are most useful when they are asynchronous but there is nothing stopping them from being synchronous. Tasks are built on top of a protocol, FATask, this aids in composability and allowing for almost anything to be modeled as a task. If you have existing asynchronous functionality there is a good chance you can hide it behind the FATask protocol and gain the benefits that come from composability.

Here are a few of the things you can accomplish using composable tasks:

* ***Parallelized tasks*** - Batch a group of tasks to run concurrently and receive an event when all are finished, optionally listen for the result of each one.
* ***Serialized tasks*** - Batch a group of tasks that run one after the other and receive an event when all are finished, optionally listen for the result of each one.
* ***Chained tasks*** - Execute a group of tasks one after the other, the result of each task is passed into the next one for further processing.
* ***Retry tasks*** - Retry any task a specific number of times, or an unlimited amount. You can also specify a custom block to determine a delay between each try.
* ***Conditional tasks*** - Conditionally execute a specific task from a selection of tasks based on the input parameter to the task.
* ***UI tasks*** - Wrap any task in a UI task to have all of that task's events forwarded to the main thread.
* ***Network tasks*** - Use tasks to access remote APIs, download files to disk, or upload large files to a server. Chain them with a response handling task, wrap them in a retry task, or both.
* ***Custom tasks*** - Any useful combination of composed tasks you can come up with. Some good candidates for a custom task include: reachability, image resizing, disk access, and SQLite queries.

## What about NSOperation

You may be thinking that FranticApparatus and NSOperation are similar so why would you choose one over the other? Here is a list of things that differentiates FranticApparatus tasks from NSOperations:

* All tasks are based off of the FATask protocol, this makes creating a task out of anything much easier than what can be done using NSOperation alone. This includes fake or stub tasks that can be used during testing.

* By default NSOperations aren't easily composable. Composing them can be done, just in an ad-hoc non-reusable way. While you could theoretically create a framework similar to FranticApparatus based around NSOperation, it would be a bit awkward as it would most likely only work with a special subclass of NSOperation designed for composability.

* NSOperations can be made into tasks by subclassing them and implementing the FATask protocol, but you might want to consider using FABackgroundTask instead.

* Tasks communicate between each other and with their client using events. There are a standard set of events but you can create extra events if your custom tasks calls for it. NSOperations have no built in way of communicating between themselves.

* A NSOperation can't easily wait inside its main for a sub-task to finish, which again makes composability harder. A task has no concept of main, it only defines events that are triggered at indeterminate times. This allows a task to easily wrap other tasks while they do their work and allow a batch of multiple tasks to appear as a single task to the client.

## Example

Unfortunately there are no one liners with Frantic Apparatus that make for good looking examples, but [FranticMVCNetworking](https://github.com/jkolb/FranticMVCNetworking.git) is an example project based off of [MVCNetworking](http://developer.apple.com/library/ios/#samplecode/MVCNetworking/Introduction/Intro.html) that illustrates replacing ad-hoc NSOperation composition with what is available in FranticApparatus.

## How To Get Started

Currently FranticApparatus can either be used by copying it's source files directly into your project, or by using it as a static library by dragging and dropping the FranticApparatus.xcodeproj file into your project or workspace. There is also a podspec file that can be used in a project's Podfile as a [local file reference](https://gist.github.com/radiospiel/2009100).

## Requirements

FranticApparatus 0.3 requires ARC and iOS 6.0+.

## Contact

[Justin Kolb](https://github.com/jkolb)  
[@nabobnick](https://twitter.com/nabobnick)

## License

FranticApparatus is available under the MIT license. See the LICENSE file for more info.
