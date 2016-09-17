# FranticApparatus 6.0.0 
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

#### A thread safe, type safe, and memory safe [Promises/A+](https://promisesaplus.com) implementation for Swift 3

Promises provide a way to make it easier to read and write chains of dependent asynchronous code. Here is a simple example of how much better asynchronous code looks using FranticApparatus:

    let url = NSURL(string: "http://example.com/image.png")!

    self.promise = PromiseMaker.makeUsing(context: self) { (makePromise) in
        makePromise { (context) in
            context.showActivityIndicator()
            return context.fetchImage(url: url)
        }.whenFulfilled { (context, image) in
            context.showImage(image)
        }.whenRejected { (context, reason) in
            context.showPlaceholderImage()
        }.whenComplete { (context) in
            context.hideActivityIndicator()
            context.promise = nil
        }
    }

See the Demo for examples of how to make promises to fetch a set of images over the network using promises and display them in a `UICollectionView`.

## Changes for 6.0.0

* Syntax updated for Swift 3.
* Initial Swift Package Manager support.
* Replaced `PromiseDispatchContext` with `PromiseMaker`.
* Renamed all of the promise helper methods. This was done partly to appease the Swift compiler and partly to make creating promises easier to read.
* Updated the demo to load multiple images into a collection view using promises.
* See documentation below for more details on the changes.

## Changes for 5.0.0

* Attempted to simplify and make the implementation as readable and consistent as possible.
* Introduced the `Dispatcher` protocol to break the dependence on GCD.
* Brought back the `Result` enum for returning values from promises as this better matches the spec and simplifies the `then` function and all the shortcut functions.
* Shortcut functions have been consolidated into three varieties `then` for success, `handle` for error, and `finally` for both success & error.
* Shortcut functions mostly eliminate the need to directly use the `Result` enum. The only case that needs to use it is when you can return a value or another promise conditionally so you must differentiate using the enum values `.Value` or `.Defer`.
* Simplified the unit tests, they no longer need asynchronous expectations due to using a mock `Dispatcher`.
* Moved shortcut methods into the `Thenable` protocol.
* Created `PromiseDispatchContext` as a way to share a common `Dispatcher` in a single promise chain.
* Added the FranticApparatusDemo workspace with an example of simple network loading and parsing of an image using promises.

## Changes for 4.0.2

* Fix dead lock when a promise returns a pending promise within `then`.
* Updated tests to trigger this dead lock to verify it was fixed.

## Changes for 4.0.1

* Attempting to fix problem with building usage Carthage.

## Changes for 4.0.0

* Major change in the API to take better advantage of Swift 2 features.
* Removed the `Result` enum, now you can return a value or throw an error directly from the `onFulfilled` or `onRejected` closures.
* Instead of using `.Deferred` to chain promises, now just return a promise directly.
* If you need to conditionally return either a value or a promise from `onFulfilled`, then return the promise normally but wrap the value like this: `return Promise(value)`
* Switched from using GCD to `NSLock` for thread safety.
* Removed the `Synchronizable` protocol as `NSLock` is used instead.
* Removed the `DispatchQueue` helper class as there is no longer as strong reliance on GCD.
* Removed `URLPromiseFactory` and associated code, to simplify the code base and concentrate on the core functionality.
* Methods that take a context parameter now have `WithContext` in their names. For example: `thenWithContext`

## Changes for 3.0.1

* Implemented Synchronizable as a protocol extension to make it read better.
* Added @noescape to the public Promise initializer since the block is always run inline.

## Changes for 3.0.0

* Updated to support Swift 2.
* Removed custom Error struct and replaced it with the Swift built-in ErrorType.
* NSErrorWrapperError has also been removed as NSError already conforms to ErrorType.
* Existing FranticApparatus Error subclasses have been converted to enums that derive from ErrorType.
* Removed Value struct since boxing enum associated values is not longer needed.
* You must update all places were you call `Result(value)`, `Result(error)`, and `Result(promise)` to now be `.Success(value)`, `.Failure(error)`, `.Deferred(promise)` since enum boxing is no longer needed.
* The `catch` method has been renamed to `handle` to not conflict with the new `catch` keyword.
* Tests have been rewritten to better show how to do memory management with promises.

## Changes for 2.2.3

* Attempting to add Carthage support.
* Turned on Whole Module Optimization to speed up compilation.

## Changes for 2.2.2

* Each promise should now use less memory as once it reaches its fulfilled state all pending state used while processing will be released.

## What is a promise?

A promise, at its most simple definition, is a proxy for a value that has not been calculated yet. This [blog](http://andyshora.com/promises-angularjs-explained-as-cartoon.html) provides a good high level overview of how they work. Unfortunately that does not give much insight into the usefulness they provide. The utility of promises arises because they are recursively composable, which makes for easily defining complex combinations of asynchronous functionality. Promises can be combined so they execute serially or in parallel*, but no matter which way you compose them they still effectively read like a serialized order of steps. Being able to write code that looks (as best it can) like it executes from top to bottom while actually wrapping multiple asynchronous calls is where the true power of promises lies.

**Parallel promises are more tricky in a strongly typed language, and I am still working out a good way to implement it.*

You may be thinking to yourself that this sounds like it could be done just as well with normal asynchronous callbacks, and you would not be wrong. While you can do something similar using everyday blocks they quickly become ugly nests of callbacks and make error handling more difficult. As a simple example imagine you would like to download some data from a remote web service, parse that data as JSON, and then map that JSON into a data model object (also imagine you can not use your favorite networking library). It might look like the following (thread safe memory management included, strong error handling not included):

	func fetch(url: NSURL, completion: (dataModel: DataModel?, error: NSError?) -> ()) {
		self.download(url) { [weak self] (data: NSData?, error: NSError?) in
			if let downloadSelf = self {
				if error != nil {
					completion(nil, error)
					return
				}
			
				downloadSelf.parseJSON(data!) { [weak downloadSelf] (json: NSDictionary?, error: NSError?) in
					if let parseSelf = downloadSelf {
						if error != nil {
							completion(nil, error)
							return
						}
						
						parseSelf.mapDataModel(json!) { (dataModel: DataModel?, error: NSError?) in
							if error == nil {
								completion(nil, error)
								return
							}
							
							completion(dataModel!, nil)
						}
					}
				}
			}
		}
	}
	

Then the usage would look something like this:

    self.showActivityIndicator()
	
	self.fetch(NSURL(string: "http://example.com/datamodel.json")) { [weak self] (dataModel: DataModel?, error: NSError?) in
		if let strongSelf = self {
			if error != nil {
				strongSelf.displayError(error!)
			} else {
				strongSelf.displayDataModel(dataModel!)
			}
			
			strongSelf.hideActivityIndicator()
		}
	}

Here is the same example assuming that there are three methods that return promises to download, parse, and map the data similar to the above methods that just take callbacks:

    func fetch(url: NSURL) -> Promise<DataModel> {
        return PromiseMaker.makeUsing(dispatcher: dispatcher, context: self) { (makePromise) in
            makePromise { (context) in
                return context.download(url)
            }.whenFulfilledThenPromise { (context, data) in
                return context.parseJSONData(data)
            }.whenFulfilledThenPromise { (context, json) in
                return context.mapDataModel(json)
            }
        }
    }

And again how it would be used:

    let url = NSURL(string: "http://example.com/datamodel.json")!

    self.promise = PromiseMaker.makeUsing(context: self) { (makePromise) in
        makePromise { (context) in
            context.showActivityIndicator()
            return context.fetch(url: url)
        }.whenFulfilled { (context, dataModel) in
            context.displayDataModel(dataModel)
        }.whenRejected { (context, reason) in
            context.displayError(reason)
        }.whenComplete { (context) in
            context.hideActivityIndicator()
            context.promise = nil
        }
    }

Note the missing rightward drift of the nested callbacks and also the small amount of error handling code. Also as a convenience to aid in thread safety `PromiseMaker` takes a context parameter, turns it into a weak reference, and then when the blocks are executed a strong reference is passed into them as the first paramter. If the context reference becomes nil the body of the closure will not execute preventing a common source of bugs. Additionally this saves you from writing extra boiler plate memory management code in all of your closures.

## What is going on here?

The `fetch` method is building a promise that represents a `DataModel` value that will be calculated and returned sometime in the future. To extract a value from a promise you must call its `then` method and provide an `onFulfilled` and an `onRejected` callback. This is very similar to the normal callback methods above, but this is where the similarity ends. If the fetch completes successfully it will execute the `onFulfilled` block and pass in the value that was generated. If later on you call `then` on the same promise you will get back the same value as before without having to recalculate. This is because once a promise is fulfilled it stays that way. Also if multiple objects call `then` on the same promise they can all wait for the promise to be fulfilled or rejected.

In the same vein, if there is a problem calculating the value, the promise will be rejected and the `onRejected` callback will be triggered instead. Once a promise is rejected it will stay that way and also multiple objects can receive the same rejection notice as long as each object calls `then` on the same promise instance*.

In the example above a shortcut `whenFulfilled` method is used in place of `then`. This version of the `then` method is a convenience that calls the normal `then` behind the scenes and allows you to just provide a callback for `onFulfilled`. It also creates an `onRejected` callback but its implementation effectively just forwards any errors on to the next promise in the chain of promises (if any). The `whenRejected` method does the opposite, as it allows you to provide an `onRejected` callback while forwarding on any fulfilled values to the next promise in the chain. Lastly the `whenComplete` method generates implementations of both `onFulfilled` and `onRejected` that foward on the values but also gives you a way to execute the same block no matter if the promise is rejected or fulfilled.

**There are some details of the memory management this entails that will be covered later*

## How does this work?

Each time you call `then` on a promise, you generate a new and distinct promise. Effectively you are building a linked list of promises which when complete will either give a final value or an error. You must keep a reference to the last promise returned by the last call to `then` to keep the promise chain alive, otherwise the promises will be deinitialized, which cancels any processing the promise may have started. In fact that is how cancellation is implemented in FranticApparatus. When you you need to cancel any promise just make sure it gets deinitailized. Behind the scenes any asynchronous processes will have a weak reference to the promise and will not be able to fulfill or reject it once its weak reference changes to nil. Note though that if multiple objects are making use of the same promise all of them would have to be deinitialized to fully cancel.

On that note, for multiple objects to call `then` on the same promise, they all must keep their separate references to the promise generated by `then` alive otherwise they will not get their `onFulfilled` and/or `onRejected` callbacks triggered. Additionally they could do separate processing of the same original promise ultimately generating distinct promises that share a common child promise under the hood. An example of this might be one promise that returns an image from a remote API call that is used in two places, one to generate a blurred version of the full size image, and another to generate a thumbnail of the same image. Both of the tasks can proceed in parallel once the first promise is fulfilled with the remote image.

## Is there more to it than this?

Not covered yet is how a chain of promises, that each return a specific data type, work together to generate a final different data type value. This can be seen in the `fetch` example above where the initial promise returns `Data`, which then becomes `Dictionary`, and then finally an instance of `DataModel`. The trick to this is the type of result that is returned from inside the `onFulfilled` or `onRejected` callback. No matter if a promise is fulfilled or rejected, three types of results can be generated (a value, a promise, or a thrown error) which are then passed on to the next promise in the chain. Having all three types available in both callbacks allows you to transform the result from one promise before it is passed to the next.

For example in an `onRejected` callback you could check the error that was thrown, and if it matches a certain type of error return a result that represents a valid default value, otherwise just rethrow the original error. The next promise will either fulfill if the default value is returned or reject if the original error is thrown. Another example is taking the original value passed into `onFulfilled` and then extracting one part of it or mapping it to another type of object and then returning that instead. Additionally you could determine that a certain range of values could be considered an error and throw instead which would cause any chained promises to reject with that error.

Lastly we come to the most powerful type of result, instead of returning a value or an throwing an error, returning a promise instead. When you return a promise in the `onFulfilled` or `onRejected` callbacks you are saying that the chain of promises will not be fulfilled until this new promise is fulfilled. Then when it does fulfill the result it generates (value, error, or proimse) will be used to continue the chain. This is exactly how the `fetch` method is implemented.


## How do I make my own promises?

#### A promise that parse JSON data on a background queue. 

    func parseJSONData(_ data: Data) -> Promise<NSDictionary> {
        return Promise<NSDictionary> { (fulfill, reject, isCancelled) in
            queue.async {
                do {
                    let object = try JSONSerialization.jsonObject(with: data, options: [])

                    if let dictionary = object as? NSDictionary {
                        fulfill(dictionary)
                    }
                    else {
                        reject(NetworkError.unexpectedData(data))
                    }
                }
                catch {
                    reject(error)
                }
            }
        }
    }

When you make a promise you pass in a closure to the initiailizer representing the work required to generate the promise's value. At the end of the promise initiaizer it will execute this closure and pass in three closures to it as parameters: `fulfill`, `reject`, and `isCancelled`. These parameters allow the closure doing the work to safely interact with the promise without worrying about memory management or keeping up with a separate reference to the promise instance. To be most useful any work required to calculate the result of the promise should be done on a separate thread.

When the work to calculate the value is complete the original promise can be fulfilled by calling `fulfill` and passing in the generated value. If there is an error whie generating the value you can call `reject` instead passing in an instance of an object that coforms to the Swift 2 protocol `ErrorType`. If the work required to do the calculation is long and has multiple sections of complex logic you can intersperse that logic with calls to `isCancelled()` so you can detect as early as you can if the promise associated with the work has been deinitialized and exit early if it makes sense to do so. If the promise has already been deinitialized it is still safe to call `fulfill`, `reject`, and `isCancelled` as they are written to be safe in this use case.

## PromiseMaker

#### Using `PromiseMaker` to simplify chaining promises together to form more powerful promises.

`PromiseMaker` was designed to make writing and reading promises easier. It helps simplify the calls to chain promises using the `then` method by keeping track of a common `Dispatcher` that will be used by the entire chain and by keeping a context variable around that can be safely used in each of the chained promises. There is also the `Thenable` protocol which provides some helper methods when not making use of `PromiseMaker`. So a chain of promises just using `then` would look like this:

    self.promise = promiseSomething().then(
        on: GCDDispatcher.main,
        onFulfilled: { [weak self] (value) in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }
            
            strongSelf.displayValue(value)
            return .value(value) // Manually continue the chain
        }
        onRejected: { [weak self] (reason) in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }
            
            strongSelf.displayError(reason)
            throw reason // Manually continue the chain
        }
    ).then(
        on: GCDDispatcher.main,
        onFulfilled: { [weak self] (value) in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }

            strongSelf.promise = nil
            return .value(value) // Manually continue the chain
        }
        onRejected: { [weak self] (reason) in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }

            strongSelf.promise = nil
            throw reason // Manually continue the chain
        }
    )

When using `Thenable` helpers would look like this:

        self.promise = promiseSomething().whenFulfilled(on: GCDDispatcher.main) { [weak self] (value) in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }

            strongSelf.displayValue(value)
        }.whenRejected(on: GCDDispatcher.main) { [weak self] (value) in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }

            strongSelf.displayError(reason)
        }.whenComplete(on: GCDDispatcher.main) { [weak self] in
            guard let strongSelf = self else { throw PromiseError.contextDeallocated }

            strongSelf.promise = nil
        }

When using `PromiseMaker` would look like this:

    self.promise = PromiseMaker.makeUsing(context: self) { (makePromise) in
        makeProimise { (context) in
            return context.promiseSomething()
        }.whenFullfilled { (context, value) in
            context.displayValue(value)
        }.whenRejected { (context, reason) in
            context.displayError(reason)
        }.whenComplete { (context) in
            context.promise = nil
        }
    }

`PromiseMaker.makeUsing` takes a `dispatcher` parameter as its first argument but defaults to `GCDDispatcher.main` when not specified.

The helpers in `Thenable` and `PromiseMaker` both follow the same naming scheme. The only real difference between them is that `Thenable` requires the `Dispatcher` to be specified and does not provide a `context`. The names also help the Swift compiler diferentiate between them, if they were named the same (as they were in the past) the return value would be the only distinguishing item and is usually not enough for the compiler to pick one which generates a compile error. The naming of the methods and what they are useful for is as follows:

`whenFulfilled` - Use this when you would like to perform an action when a promise succeeds. Any error thrown will cause the next promise in the chain to be rejected, otherwise the original value will be automatically passed along for you.

`whenFulfilledThenTransform` - Use this when you would like to transform the value of a successful promise before passing it onto the next part of the promise chain. Any error thrown will cause the next promise in the chain to be rejected.

`whenFulfilledThenPromise` - Use this when you would like to wait for a promise to complete and then use the value in creating another promise. Any error thrown will cause the next promise in the chain to be rejected.

`whenFulfilledThenMap` - Lastly use this to either transform the value into another value or to generate a promise from the value. To indicate you are returning a value use `return .value(transformedValue)` otherwise to indicate you are returning a promise use `return .promise(yourGeneratedPromise)`. Any error thrown will cause the next promise in the chain to be rejected.

`whenRejected` - Use this when you would like to perform an action when a promise fails. The error will be automatically passed on to the next promise in the chain.

`whenRejectedThenTransform` - Use this when you would like to transform the error of a failed promise into a value before passing onto the next part of the promise chain. You can also rethrow the original or a new error to continue the chain.

`whenRejectedThenPromise` - Use this when you would like to make a different promise when the promise fails. You can also rethrow the original or a new error to continue the chain.

`whenFulfilledThenMap` - Lastly use this to either transform the error into a value or to generate a promise to handle the error. To indicate you are returning a value use `return .value(transformedValue)` otherwise to indicate you are returning a promise use `return .promise(yourGeneratedPromise)`. You can also rethrow the original or a new error to continue the chain.

`whenComplete` - Use this when you don't care if the prevous promise succeeded or failed but you want to perform an action either way. The original value or error will be passed along to the next promise in the chain.

#### A note on the ordering of methods.

Generally you want `whenRejected` to always be after a call to `whenFulfilled`, this is because `whenFulfilled` can throw errors and they will be silently passed along the chain unless there is another `whenRejected` later on to catch it. Also it is preferable to not throw errors from `whenComplete` and to make it the last in the chain. It will perform an action on both success and failure but will not gain access to the reason for failure. The demo does use a `whenComplete` in the middle of a chain, but any errors it could generate will be caught by the `whenRejected` handler that comes later on in the `RootViewController`.

## Contact

[Justin Kolb](mailto:justin.kolb@franticapparatus.net)  
[@nabobnick](https://twitter.com/nabobnick)

## License

FranticApparatus is available under the MIT license. See the LICENSE file for more info.
