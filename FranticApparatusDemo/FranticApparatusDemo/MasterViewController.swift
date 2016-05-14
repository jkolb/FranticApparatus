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

class MasterViewController: UITableViewController {
    var networkAPI: NetworkAPI!
    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    var promise: Promise<NSDictionary>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        let networkLayer = ActivityNetworkLayer(dispatcher: GCDDispatcher.mainDispatcher(), networkLayer: SimpleURLSessionNetworkLayer(), networkActivityIndicator: ApplicationNetworkActvityIndicator())
        let networkDispatcher = OperationDispatcher(queue: NSOperationQueue())
        networkAPI = NetworkAPI(dispatcher: networkDispatcher, networkLayer: networkLayer)
        
        loadData()
    }

    func loadData() {
        let urlString = "https://reddit.com/.json"
        let dataPromise = networkAPI.requestJSONObjectForURL(NSURL(string: urlString)!)
        let dataPromiseContext = OperationDispatcher.mainDispatcher().asContextFor(dataPromise)
        
        promise = dataPromiseContext.then({ (dictionary) -> Void in
            NSLog("%@", dictionary)
        }).handle({ (reason) -> Void in
            switch reason {
            case let networkError as NetworkError:
                switch networkError {
                case .HighlyImprobable:
                    NSLog("Nothing is impossible")
                case .UnexpectedData(let data):
                    NSLog("Unexpected Data: %@", data)
                case .UnexpectedResponse(let response):
                    NSLog("Unexpected Response: %@", response)
                case .UnexpectedStatusCode(let statusCode):
                    NSLog("Unexpected Status Code: \(statusCode)")
                case .UnexpectedContentType(let contentType):
                    NSLog("Unexpected Content Type: %@", contentType)
                }
            case let error as NSError:
                NSLog("%@", error)
            default:
                NSLog("Unknown error")
            }
        }).finallyWithObject(self, { (viewController) in
            viewController.promise = nil
        }).promise
    }
    
    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let object = objects[indexPath.row] as! NSDate
        cell.textLabel!.text = object.description
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
        }
    }
}
