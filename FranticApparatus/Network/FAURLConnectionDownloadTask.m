//
// FAURLConnectionDownloadTask.m
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



#import "FAURLConnectionDownloadTask.h"
#import "FAURLReceiveProgress.h"



@interface FAURLConnectionDownloadTask () <NSURLConnectionDownloadDelegate>

@end



@implementation FAURLConnectionDownloadTask

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes {
    if (self.onProgress == nil) return;
    FAURLReceiveProgress *progress = [[FAURLReceiveProgress alloc] initWithBytesReceived:bytesWritten totalBytesReceived:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
    self.onProgress(progress);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.onError) self.onError(error);
    if (self.onFinish) self.onFinish();
}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {
    if (self.onResult) self.onResult(destinationURL);
    if (self.onFinish) self.onFinish();
}

@end
