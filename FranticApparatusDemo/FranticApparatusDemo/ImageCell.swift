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

public class ImageCell : UICollectionViewCell {
    fileprivate let imageView: UIImageView
    fileprivate let errorLabel: UILabel
    fileprivate let activityIndicator: UIActivityIndicatorView
    
    public override init(frame: CGRect) {
        self.imageView = UIImageView()
        self.errorLabel = UILabel()
        self.activityIndicator = UIActivityIndicatorView(style: .gray)
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.imageView = UIImageView()
        self.errorLabel = UILabel()
        self.activityIndicator = UIActivityIndicatorView(style: .gray)
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        contentView.addSubview(errorLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)

        errorLabel.lineBreakMode = .byWordWrapping
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            errorLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4.0),
            errorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4.0),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4.0),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4.0),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
    }
    
    public override func prepareForReuse() {
        imageView.image = nil
        errorLabel.text = nil
        contentView.layer.borderColor = contentView.backgroundColor?.cgColor
        contentView.layer.borderWidth = 0.0
    }
    
    public var image: UIImage? {
        get {
            return imageView.image
        }
        
        set {
            imageView.image = newValue
        }
    }
    
    public var error: String? {
        get {
            return errorLabel.text
        }
        
        set {
            errorLabel.text = newValue
            contentView.layer.borderColor = UIColor.red.cgColor
            contentView.layer.borderWidth = 1.0
        }
    }
    
    public func showActivity() {
        activityIndicator.startAnimating()
    }
    
    public func hideActivity() {
        activityIndicator.stopAnimating()
    }
}
