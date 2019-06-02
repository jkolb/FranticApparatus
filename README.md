# FranticApparatus 
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

#### A thread safe, type safe, and memory safe [Promises/A+](https://promisesaplus.com) implementation for Swift 5

Here are some examples pulled directly from the included Demo code.

Building a promise that returns the result of a network request:
```swift
import Foundation
import FranticApparatus

public struct NetworkResult {
    public let response: URLResponse
    public let data: Data
}

public enum NetworkError : Error {
    case unexpectedData(Data)
    case unexpectedResponse(URLResponse)
    case unexpectedStatusCode(Int)
    case unexpectedContentType(String)
}

public protocol NetworkLayer : class {
    func requestData(_ request: URLRequest) -> Promise<NetworkResult>
}

public final class SimpleURLSessionNetworkLayer : NetworkLayer {
    private let session: URLSession

    public init() {
        let sessionConfiguration = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfiguration)
    }

    deinit {
        session.invalidateAndCancel()
    }

    public func requestData(_ request: URLRequest) -> Promise<NetworkResult> {
        return Promise<NetworkResult> { (fulfill, reject) in
            session.dataTask(with: request, completionHandler: { (data, response, error) in
                if let error = error {
                    reject(error)
                }
                else if let data = data, let response = response {
                    fulfill(NetworkResult(response: response, data: data))
                }
                else {
                    fatalError("Unexpected")
                }
            }).resume()
        }
    }
}
```

Chaining off of a network request promise to display thumbnails in a collection view:
```swift
func loadImage(at indexPath: IndexPath) {
    let model = models[indexPath.item]

    ApplicationNetworkActvityIndicator.shared.show()
    promises[indexPath] = fetchImage(url: model.url).then(on: DispatchQueue.main, { (image) in
        self.images[indexPath] = image
        self.showImage(at: indexPath)
    }).catch(on: DispatchQueue.main, { (error) in
        self.errors[indexPath] = error
        self.showError(at: indexPath)
    }).finally(on: DispatchQueue.main, {
        ApplicationNetworkActvityIndicator.shared.hide()
        self.promises[indexPath] = nil
    })
}

func fetchImage(url: URL) -> Promise<UIImage> {
    return networkLayer.requestData(URLRequest(url: url)).then(on: processQueue, map: { (result) in
        guard let httpResponse = result.response as? HTTPURLResponse else {
            throw NetworkError.unexpectedResponse(result.response)
        }

        guard Set<Int>([200]).contains(httpResponse.statusCode) else {
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let contentType = httpResponse.mimeType ?? ""

        guard Set<String>(["image/jpeg", "image/png"]).contains(contentType) else {
            throw NetworkError.unexpectedContentType(contentType)
        }

        guard let image = UIImage(data: result.data) else {
            throw NetworkError.unexpectedData(result.data)
        }

        return image
    })
}

func showImage(at indexPath: IndexPath) {
    if let cell = collectionView.cellForItem(at: indexPath) as? ImageCell {
        cell.hideActivity()
        cell.image = images[indexPath]
    }
}

func showError(at indexPath: IndexPath) {
    if let cell = collectionView.cellForItem(at: indexPath) as? ImageCell {
        cell.hideActivity()

        if let error = errors[indexPath] {
            cell.error = messageFor(error: error)
        }
        else {
            cell.error = nil
        }
    }
}
```

Loading JSON, parsing it, and then waiting for all thumbnails to load before displaying them:
```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if thumbnailsPromise == nil {
        ApplicationNetworkActvityIndicator.shared.show()
        thumbnailsPromise = fetchThumbnails().then(on: DispatchQueue.main, { (thumbnails) in
            self.thumbnails = thumbnails
            self.collectionView.reloadData()
        }).catch(on: DispatchQueue.main, { (error) in
            NSLog("\(error)")
        }).finally(on: DispatchQueue.main, {
            ApplicationNetworkActvityIndicator.shared.hide()
            self.thumbnailsPromise = nil
        })
    }
}

func fetchThumbnails() -> Promise<[UIImage]> {
    return networkLayer.requestData(URLRequest(url: URL(string: "https://reddit.com/.json")!)).then(on: processQueue, promise: { (result) in
        guard let httpResponse = result.response as? HTTPURLResponse else {
            throw NetworkError.unexpectedResponse(result.response)
        }

        guard Set<Int>([200]).contains(httpResponse.statusCode) else {
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let contentType = httpResponse.mimeType ?? ""

        guard Set<String>(["application/json"]).contains(contentType) else {
            throw NetworkError.unexpectedContentType(contentType)
        }

        let object = try JSONSerialization.jsonObject(with: result.data, options: [])

        guard let dictionary = object as? NSDictionary else {
            throw NetworkError.unexpectedData(result.data)
        }

        let thumbnailURLs = try self.thumbnailsFromJSON(object: dictionary)
        let thumbnailPromises = thumbnailURLs.map({ self.fetchImage(url: $0) })
        
        return all(context: self.processQueue, promises: thumbnailPromises)
    })
}

func thumbnailsFromJSON(object: NSDictionary) throws -> [URL] {
    guard let data = object["data"] as? NSDictionary else { throw JSONError.unexpectedJSON }
    guard let children = data["children"] as? NSArray else { throw JSONError.unexpectedJSON }
    var thumbnailURLs = [URL]()
    thumbnailURLs.reserveCapacity(children.count)

    for child in children {
        if let childObject = child as? NSDictionary {
            if let childData = childObject["data"] as? NSDictionary {
                if let thumbnail = childData["thumbnail"] as? NSString {
                    if thumbnail.hasPrefix("http") {
                        if let thumbnailURL = URL(string: thumbnail as String) {
                            thumbnailURLs.append(thumbnailURL)
                        }
                    }
                }
            }
        }
    }

    return thumbnailURLs
}
```

## Contact

[Justin Kolb](mailto:franticapparatus@gmail.com)  
[@nabobnick](https://twitter.com/nabobnick)

## License

FranticApparatus is available under the MIT license. See the LICENSE file for more info.
