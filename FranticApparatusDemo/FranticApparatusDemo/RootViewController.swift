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

class RootViewController : UIViewController {
    var networkAPI: NetworkAPI!
    var promise: Promise<UIImage>!
    var imageView: UIImageView!
    var activityIndicator: UIActivityIndicatorView!
    
    override func loadView() {
        imageView = UIImageView()
        view = imageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        view.contentMode = .scaleAspectFit
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = UIColor.black
        view.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.hidesWhenStopped = true
        
        let networkLayer = ActivityNetworkLayer(dispatcher: GCDDispatcher.mainDispatcher(), networkLayer: SimpleURLSessionNetworkLayer(), networkActivityIndicator: ApplicationNetworkActvityIndicator())
        let networkDispatcher = OperationDispatcher(queue: OperationQueue())
        networkAPI = NetworkAPI(dispatcher: networkDispatcher, networkLayer: networkLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadData()
    }
    
    func loadData() {
        let width = Int(view.bounds.width)
        let height = Int(view.bounds.height)
        let urlString = "https://placekitten.com/\(width)/\(height)"
        let dataPromise = networkAPI.requestImageForURL(URL(string: urlString)!)
        let dataPromiseContext = OperationDispatcher.mainDispatcher().asContextFor(dataPromise)
        
        showActivity()
        
        promise = dataPromiseContext.thenWithObject(self, { (viewController, image) -> Void in
            viewController.showImage(image)
        }).handleWithObject(self, { (viewController, reason) -> Void in
            viewController.showError(reason)
        }).finallyWithObject(self, { (viewController) in
            viewController.promise = nil
            viewController.hideActivity()
        }).promise
    }
    
    func showActivity() {
        activityIndicator.startAnimating()
    }
    
    func hideActivity() {
        activityIndicator.stopAnimating()
    }
    
    func showImage(_ image: UIImage) {
        imageView.image = image
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: messageForError(error), preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func messageForError(_ error: Error) -> String {
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
}
