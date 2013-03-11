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
#import "FAURLDownloadResult.h"
#import "FAURLReceiveProgress.h"



static const NSUInteger kFAURLConnectionDownloadTaskDefaultBufferSize = 128;



@interface FAURLConnectionDownloadTask () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) FAMutableURLReceiveProgress *progress;
@property (nonatomic, strong) FAURLDownloadResult *result;

@end



@implementation FAURLConnectionDownloadTask

- (void)handleValidResponse:(NSURLResponse *)response {
    self.result = [[FAURLDownloadResult alloc] initWithResponse:response];
    self.result.downloadPath = self.downloadPath;
    self.progress = [[FAMutableURLReceiveProgress alloc] initWithExpectedTotalBytes:[response expectedContentLength]];
    
    [self.outputStream close];
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.result.downloadPath append:NO];
    [self.outputStream open];

    if (self.buffer == nil) {
        self.buffer = [[NSMutableData alloc] initWithCapacity:kFAURLConnectionDownloadTaskDefaultBufferSize];
    } else {
        [self.buffer setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSError *error = nil;
    NSUInteger dataOffset = 0;
    NSUInteger dataLength = [data length];
    const uint8_t *dataBytes = [data bytes];
    
    while (dataOffset < dataLength) {
        NSInteger bytesWritten = [self.outputStream write:&dataBytes[dataOffset] maxLength:dataLength - dataOffset];
        
        if (bytesWritten < 0) {
            error = [self.outputStream streamError];
            break;
        } else if (bytesWritten == 0) {
            // Stream has reached its capacity
            break;            
        } else {
            dataOffset += bytesWritten;
            [self.progress addBytes:bytesWritten];
        }
        
        assert(dataOffset <= dataLength);
    }
    
    if (error != nil) {
        [self failWithError:error];
    } else if (dataOffset > 0) {
        [self triggerEventWithType:FATaskEventTypeProgress payload:[self.progress copy]];
    }
}

- (void)cleanup {
    [super cleanup];
    [self.outputStream close];
    self.outputStream = nil;
    self.progress = nil;
    self.buffer = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self succeedWithResult:self.result];
}

@end
