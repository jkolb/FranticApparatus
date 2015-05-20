# [FranticApparatus 2.2.3](https://github.com/jkolb/FranticApparatus)

#### A [Promises/A+](https://promisesaplus.com) implementation for Swift 1.2

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Changes for 2.2.3

Attempting to add Carthage support.
Turned on Whole Module Optimization to speed up compilation.

## Changes for 2.2.2

Each promise should now use less memory as once it reaches its fulfilled state all pending state used while processing will be released.

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
        return self.download(url).then(self, { (strongSelf, data) -> Result<NSDictionary> in
            return Result(strongSelf.parseJSON(data))
        }).then(self, { (strongSelf, json) -> Result<[DataModel]> in
            return Result(strongSelf.mapDataModel(json))
        })
    }

And again how it would be used:

    self.showActivityIndicator()
        
    self.promise = self.fetch(NSURL(string: "http://example.com/datamodel.json")).then(self, { (strongSelf, dataModel) in
		strongSelf.displayDataModel(dataModel)
    }).catch(self, { (strongSelf, error) in
		strongSelf.displayError(error)
    }).finally(self, { (strongSelf) in
        strongSelf.hideActivityIndicator()
        strongSelf.promise = nil
    })

Note the missing rightward drift of the nested callbacks and also the small amount of error handling code. Also as a convenience to aid in thread safety most of the methods in FranticApparatus have a special form that turns the first parameter into a weak reference and then when the block is executed provides you with a strong reference inside the closure. If the reference becomes nil the body of the closure will not execute preventing a common source of bugs. Additionally this saves you from writing extra boiler plate memory management code in all of your closures.

## What is going on here?

The `fetch` method is building a promise that represents a `DataModel` value that will be calculated and returned sometime in the future. To extract a value from a promise you must call its `then` method and provide an `onFulfilled` and an `onRejected` callback. This is very similar to the normal callback methods above, but this is where the similarity ends. If the fetch completes successfully it will execute the `onFulfilled` block and pass in the value that was generated. If later on you call `then` on the same promise you will get back the same value as before without having to recalculate. This is because once a promise is fulfilled it stays that way. Also if multiple objects call `then` on the same promise they can all wait for the promise to be fulfilled or rejected.

In the same vein, if there is a problem calculating the value, the promise will be rejected and the `onRejected` callback will be triggered instead. Once a promise is rejected it will stay that way and also multiple objects can receive the same rejection notice as long as each object calls `then` on the same promise instance*.

In the example above a shortcut `then` method is used in place of `then`. This version of the `then` method is a convenience that calls the normal `then` behind the scenes and allows you to just provide a callback for `onFulfilled`. It also creates an `onRejected` callback but its implementation effectively just forwards any errors on to the next promise in the chain of promises (if any). The `catch` method does the opposite, as it allows you to provide an `onRejected` callback while forwarding on any fulfilled values to the next promise in the chain. Lastly the `finally` method generates implementations of both `onFulfilled` and `onRejected` that foward on the values but also gives you a way to execute the same block no matter if the promise is rejected or fulfilled.

**There are some details of the memory management this entails that will be covered later*

## How does this work?

Each time you call `then` on a promise, you generate a new and distinct promise. Effectively you are building a linked list of promises which when complete will either give a final value or an error. You must keep a reference to the last promise returned by the last call to `then` to keep the promise chain alive, otherwise the promises will be deinitialized, which cancels any processing the promise may have started. In fact that is how cancellation is implemented in FranticApparatus. When you you need to cancel any promise just make sure it gets deinitailized. Behind the scenes any asynchronous processes will have a weak reference to the promise and will not be able to fulfill or reject it once its weak reference changes to nil. Note though that if multiple objects are making use of the same promise all of them would have to be deinitialized to fully cancel.

On that note, for multiple objects to call `then` on the same promise, they all must keep their separate references to the promise generated by `then` alive otherwise they will not get their `onFulfilled` and/or `onRejected` callbacks triggered. Additionally they could do separate processing of the same original promise ultimately generating distinct promises that share a common child promise under the hood. An example of this might be one promise that returns an image from a remote API call that is used in two places, one to generate a blurred version of the full size image, and another to generate a thumbnail of the same image. Both of the tasks can proceed in parallel once the first promise is fulfilled with the remote image.

## Is there more to it than this?

Not covered yet is how a chain of promises, that each return a specific data type, work together to generate a final different data type value. This can be seen in the `fetch` example above where the initial promise returns `NSData`, which then becomes `NSDictionary`, and then finally an instance of `DataModel`. The trick to this is the type of result that is returned from inside the `onFulfilled` or `onRejected` callback. No matter if a promise is fulfilled or rejected, three types of results can be returned which are then passed on to the next promise in the chain. Having all three types available in both callbacks allows you to transform the result from one promise before it is passed to the next.

For example in an `onRejected` callback you could check the error that was generated, and if it matches a certain type of error return a result that represents a valid default value, otherwise just return the original error result. The next promise will either fulfill if the default value is returned or reject if the original error is returned. Another example is taking the original value passed into `onFulfilled` and then extracting one part of it or mapping it to another type of object and then returning that instead. Additionally you could determine that a certain range of values could be considered an error and return an error result instead which would cause any chained promises to reject with that error.

Lastly we come to the most powerful type of result, instead of returning a value or an error, returning a promise instead. When you return a promise in the `onFulfilled` or `onRejected` callbacks you are saying that the chain of promises will not be fulfilled until this new promise is fulfilled. Then when it does fulfill the result it generates (value, error, or proimse) will be used to continue the chain. This is exactly how the `fetch` method is implemented.


## How do I make my own promises?

#### A promise that returns an NSDictionary from JSON data.

    func parseJSON(data: NSData, options: NSJSONReadingOptions = NSJSONReadingOptions(0)) -> Promise<NSDictionary> {
        return Promise<NSDictionary> { (fulfill, reject, isCancelled) in
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
				var error: NSError?
				let value: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: options, error: &error)
                
				if value == nil {
					reject(NSErrorWrapperError(cause: error!))
                } else {
                    fulfill(value! as NSDictionary) // Unsafe cast!
                }
        	}
		}
    }

When you make a promise you pass in a closure to the initiailizer representing the work required to generate the promise's value. At the end of the promise initiaizer it will execute this closure and pass in three closures to it as parameters: `fulfill`, `reject`, and `isCancelled`. These parameters allow the closure doing the work to safely interact with the promise without worrying about memory management or keeping up with a separate reference to the promise instance. To be most useful any work required to calculate the result of the promise should be done on a separate thread. In this case we are using Grand Central Dispatch to execute a block on a global queue.

When the work to calculate the value is complete the original promise can be fulfilled by calling `fulfill` and passing in the generated value. If there is an error whie generating the value you can call `reject` instead passing in an instance of a subclass of `Error` that represents the error condition. `NSErrorWrapperError` is provided to translate between `NSError` and `Error` if needed. Lastly if the work required to do the calculation is long and has multiple sections of complex logic you can intersperse that logic with calls to `isCancelled()` so you can detect as early as you can if the promise associated with the work has been deinitialized and exit early if it makes sense to do so. If the promise has been deinitialized it is still safe to call `fulfill` and `reject` as they do nothing if the promise is missing.

#### Using promises to perform networking

See `URLPromiseFactory.swift` for a basic example of generating promises backed by a NSURLSession. The included FranticApparatusExample_iOS project gives a rough example of loading from the network using a `URLPromiseFactory` and parsing the results using promises.

## Contact

[Justin Kolb](mailto:justin.kolb@franticapparatus.net)  
[@nabobnick](https://twitter.com/nabobnick)

## License

FranticApparatus is available under the MIT license. See the LICENSE file for more info.
