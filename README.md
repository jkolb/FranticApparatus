# [FranticApparatus 1.0](https://github.com/jkolb/FranticApparatus)

#### FranticApparatus makes asynchronous Objective-C easy!

How to make an asynchronous network request:

	NSURL *URL = [[NSURL alloc] initWithString:@"http://www.reddit.com/r/all.json"];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	FAURLConnectionDataTask *task = [[FAURLConnectionDataTask alloc] initWithRequest:request];
	task.queue = queue;
	[task addFinishBlock:^(FATaskFinishEvent *event) {
		if ([event hasError]) {
			NSLog(@"Error: %@", event.error);
		} else {
			FAURLConnectionDataResult *dataResult = event.result;
			NSLog(@"Response: %@", dataResult.response);
			NSLog(@"Data: %@", dataResult.data);
		}
    }];
	[task start];

How to parse the JSON response data of an asynchronous network request on a background thread:

	NSURL *URL = [[NSURL alloc] initWithString:@"http://www.reddit.com/r/all.json"];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	FAChainedTask *chainedTask = [[FAChainedTask alloc] init];
	[chainedTask addTaskBlock:^id<FATask>(id lastResult) {
		FAURLConnectionDataTask *task = [[FAURLConnectionDataTask alloc] initWithRequest:request];
		task.queue = queue;
		return task;
    }];
	[chainedTask addTaskBlock:^id<FATask>(id lastResult) {
		FAURLConnectionDataResult *dataResult = lastResult;
	    return [[FABackgroundTask alloc] initWithBlock:^id(id<FATask> blockTask, NSError **error) {
    	    return [NSJSONSerialization JSONObjectWithData:dataResult.data options:0 error:error];
	    }];
    }];
	[chainedTask addFinishBlock:^(FATaskFinishEvent *event) {
		if ([event hasError]) {
			NSLog(@"Error: %@", event.error);
		} else {
			NSLog(@"Result: %@", event.result);
		}
    }];
	[chainedTask start];

How to retry a network request if it fails:

	NSURL *URL = [[NSURL alloc] initWithString:@"http://www.reddit.com/r/all.json"];
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    FARetryTask *retryTask = [[FARetryTask alloc] init];
    [retryTask setTaskBlock:^id<FATask>(id lastResult) {
        FAURLConnectionDataTask *task = [[FAURLConnectionDataTask alloc] initWithRequest:request];
        task.queue = queue;
        return task;
    }];
	[retryTask addFinishBlock:^(FATaskFinishEvent *event) {
		if ([event hasError]) {
			NSLog(@"Error: %@", event.error);
		} else {
			FAURLConnectionDataResult *dataResult = event.result;
			NSLog(@"Response: %@", dataResult.response);
			NSLog(@"Data: %@", dataResult.data);
		}
    }];
    [retryTask start];

How to make two network tasks in parallel and wait for both responses:

	NSURL *googleURL = [[NSURL alloc] initWithString:@"http://www.google.com/"];
	NSURL *redditURL = [[NSURL alloc] initWithString:@"http://www.reddit.com/"];
	NSURLRequest *googleRequest = [[NSURLRequest alloc] initWithURL:googleURL];
	NSURLRequest *redditRequest = [[NSURLRequest alloc] initWithURL:redditURL];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	FAParallelTask *parallelTask = [[FAParallelTask alloc] init];
	parallelTask.allowPartialFailue = YES;
    [parallelTask setKey:@"google" forTaskBlock:^id<FATask>(id lastResult) {
        FAURLConnectionDataTask *task = [[FAURLConnectionDataTask alloc] initWithRequest:googleRequest];
        task.queue = queue;
        return task;
    }];
    [parallelTask setKey:@"reddit" forTaskBlock:^id<FATask>(id lastResult) {
        FAURLConnectionDataTask *task = [[FAURLConnectionDataTask alloc] initWithRequest:redditRequest];
        task.queue = queue;
        return task;
    }];
	[parallelTask addFinishBlock:^(FATaskFinishEvent *event) {
		NSLog(@"Results: %@", event.result);
    }];
    [parallelTask start];
	
## Overview

FranticApparatus is a composable task framework for iOS. Composable tasks allow for a more natural way of writing chained or parallel asynchronous functionality. This is somewhat similar to what [Async.js](https://github.com/caolan/async) and other asynchronous control flow libraries and frameworks provide but with the benefit that objects are being composed and not just functions. Composable tasks can generate more than just error and return values, they generate events. For example a retry task generates events describing when the task has been delayed due to a failure and then when it is restarted again afterwards.

Here are a few of the things you can accomplish using composable tasks:

* ***Parallelized tasks*** - Batch a group of tasks to run concurrently and be notified when they all are complete.
* ***Chained tasks*** - Execute a group of tasks one after the other, the result of each task is passed into the next one for further processing.
* ***Retry tasks*** - Retry any task a specific number of times, or an unlimited amount. You can also provide custom configuration to control retry delay and which errors are allowed to trigger a retry.
* ***Network tasks*** - Use tasks to access remote APIs or download files to disk. Chain them with a response handling task, wrap them in a retry task, or both.
* ***Custom tasks*** - Any useful combination of composed tasks you can come up with. Some good candidates for a custom task include: reachability, image resizing, disk access, and SQLite queries.

## How To Get Started

Currently FranticApparatus can either be used by copying it's source files directly into your project, or by using it as a static library by dragging and dropping the FranticApparatus.xcodeproj file into your project or workspace. There is also a podspec file that can be used in a project's Podfile as a [local file reference](https://gist.github.com/radiospiel/2009100).

## Requirements

FranticApparatus 1.0 requires ARC and iOS 6.0+.

## Contact

[Justin Kolb](https://github.com/jkolb)  
[@nabobnick](https://twitter.com/nabobnick)

## License

FranticApparatus is available under the MIT license. See the LICENSE file for more info.
