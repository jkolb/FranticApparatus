/*
 The MIT License (MIT)
 
 Copyright (c) 2016 Justin Kolb
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit
import FranticApparatus

class RootViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var networkAPI: NetworkAPI!
    var collectionView: UICollectionView!
    var models = [
        ImageModel(width: 125, height: 100, url: URL(string: "https://placekitten.com/100/100")!),
        ImageModel(width: 125, height: 100, url: URL(string: "https://placebear.com/100/100")!),
        ImageModel(width: 125, height: 100, url: URL(string: "https://placekitten.com/AA/BB")!),
        ImageModel(width: 125, height: 100, url: URL(string: "https://google.com")!),
        ImageModel(width: 125, height: 100, url: URL(string: "https://placehold.it/100x100")!),
        ImageModel(width: 125, height: 125, url: URL(string: "https://placekitten.com/125/125")!),
        ImageModel(width: 125, height: 125, url: URL(string: "https://placebear.com/125/125")!),
        ImageModel(width: 125, height: 100, url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/d/d0/Test_animation.gif")!),
    ]
    var images = [IndexPath : UIImage](minimumCapacity: 8)
    var errors = [IndexPath : Error](minimumCapacity: 8)
    var promises = [IndexPath : Promise<UIImage>](minimumCapacity: 8)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = view.backgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "imageCell")

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let networkLayer = ActivityNetworkLayer(dispatcher: GCDDispatcher.main, networkLayer: SimpleURLSessionNetworkLayer(), networkActivityIndicator: ApplicationNetworkActvityIndicator())
        let networkDispatcher = OperationDispatcher(queue: OperationQueue())
        networkAPI = NetworkAPI(dispatcher: networkDispatcher, networkLayer: networkLayer)
    }
    
    func loadImage(at indexPath: IndexPath) {
        let model = models[indexPath.item]
        
        promises[indexPath] = PromiseMaker.makeUsing(context: self) { (makePromise) in
            makePromise { (context) in
                return context.networkAPI.requestImageForURL(model.url)
            }.whenFulfilled { (context, image) in
                context.images[indexPath] = image
                context.showImage(at: indexPath)
            }.whenRejected { (context, reason) in
                context.errors[indexPath] = reason
                context.showError(at: indexPath)
            }.whenComplete { (context) in
                context.promises[indexPath] = nil
            }
        }
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
    
    func messageFor(error: Error) -> String {
        switch error {
        case let networkError as NetworkError:
            switch networkError {
            case .highlyImprobable:
                return "Nothing is impossible"
            case .unexpectedData(let data):
                return "Unexpected Data: \(data)"
            case .unexpectedResponse(let response):
                return "Unexpected Response: \(response)"
            case .unexpectedStatusCode(let statusCode):
                return "Unexpected Status Code: \(statusCode)"
            case .unexpectedContentType(let contentType):
                return "Unexpected Content Type: \(contentType)"
            }
        case let error as NSError:
            return "\(error)"
        default:
            return "Unknown error"
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImageCell {
            if let image = images[indexPath] {
                cell.hideActivity()
                cell.image = image
            }
            else if let error = errors[indexPath] {
                cell.hideActivity()
                cell.error = messageFor(error: error)
            }
            else {
                cell.showActivity()
                
                if promises[indexPath] == nil {
                    loadImage(at: indexPath)
                }
            }
            
            return cell
        }
        else {
            fatalError("No cell to display")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let model = models[indexPath.item]
        
        return CGSize(width: model.width, height: model.height)
    }
}
