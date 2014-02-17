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
#import "FAURLConnectionDownloadResult.h"
#import "FAURLConnectionDownloadProgressEvent.h"
#import "FATaskProgressEvent.h"



NSString * const FAURLDownloadErrorDomain = @"FAURLDownloadErrorDomain";

static const NSUInteger kFAURLConnectionDownloadTaskDefaultBufferSize = 128;



@interface FAURLConnectionDownloadTask () <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSString *downloadPath;
@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, readwrite) long long bytesReceived;
@property (nonatomic, readwrite) long long totalBytesReceived;

@end



@implementation FAURLConnectionDownloadTask

- (id)initWithRequest:(NSURLRequest *)request {
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *downloadPath = [directories lastObject];
    return [self initWithRequest:request downloadPath:downloadPath];
}

- (id)initWithRequest:(NSURLRequest *)request downloadPath:(NSString *)downloadPath {
    self = [super initWithRequest:request];
    if (self == nil) return nil;
    _downloadPath = downloadPath;
    if ([_downloadPath length] == 0) return nil;
    return self;
}

- (void)handleResponse:(NSURLResponse *)response {
    self.response = response;
    self.bytesReceived = 0;
    self.totalBytesReceived = 0;
    
    [self.outputStream close];
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downloadPath append:NO];
    [self.outputStream open];

    if (self.buffer == nil) {
        self.buffer = [[NSMutableData alloc] initWithCapacity:kFAURLConnectionDownloadTaskDefaultBufferSize];
    } else {
        [self.buffer setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSData *blockData = [data copy];
    
    [self synchronizeWithBlock:^(FATypeOfSelf blockTask) {
        [blockTask.buffer appendData:blockData];
        
        NSError *error = nil;
        BOOL success = [blockTask writeAsMuchDataAsPossibleToOutputStreamAndReportProgressWithError:&error];
        
        if (!success) {
            [connection cancel];
            [blockTask completeWithResult:nil error:error];
        }
    }];
}

- (BOOL)writeAsMuchDataAsPossibleToOutputStreamAndReportProgressWithError:(NSError **)error {
    NSInteger bytesWritten = [self writeData:self.buffer toOutputStream:self.outputStream withError:error];
    
    if (bytesWritten < 0) return NO;

    if (bytesWritten > 0) {
        [self.buffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        self.bytesReceived = bytesWritten;
        self.totalBytesReceived += bytesWritten;
        [self dispatchEvent:[[FAURLConnectionDownloadProgressEvent alloc] initWithSource:self
                                                                           bytesReceived:self.bytesReceived
                                                                      totalBytesReceived:self.totalBytesReceived
                                                                      expectedTotalBytes:[self.response expectedContentLength]]];
    }

    return YES;
}

- (NSInteger)writeData:(NSData *)data toOutputStream:(NSOutputStream *)outputStream withError:(NSError **)error {
    NSInteger dataOffset = 0;
    NSUInteger dataLength = [data length];
    const uint8_t *dataBytes = [data bytes];
    
    while (dataOffset < dataLength && [outputStream hasSpaceAvailable]) {
        NSInteger bytesWritten = [outputStream write:&dataBytes[dataOffset] maxLength:dataLength - dataOffset];
        
        if (bytesWritten < 0) {
            if (error != NULL) {
                *error = [outputStream streamError];
            }
            return -1;
        } else if (bytesWritten == 0) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:FAURLDownloadErrorDomain code:FAURLDownloadErrorOutputStreamCapacityReached userInfo:nil];
            }
            return -1;
        } else {
            dataOffset += bytesWritten;
        }
    }
    
    assert(dataOffset <= dataLength);
    
    return dataOffset;
}

- (void)willCancel {
    [self cleanup];
}

- (void)willComplete {
    [self cleanup];
}

- (void)cleanup {
    [self.outputStream close];
    self.outputStream = nil;
    self.buffer = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self synchronizeWithBlock:^(FATypeOfSelf blockTask) {
        while ([blockTask.buffer length] > 0) {
            NSError *error = nil;
            BOOL success = [blockTask writeAsMuchDataAsPossibleToOutputStreamAndReportProgressWithError:&error];
            
            if (!success) {
                [blockTask completeWithResult:nil error:error];
                return;
            }
        }
        
        id result = [[FAURLConnectionDownloadResult alloc] initWithResponse:blockTask.response
                                                               downloadPath:blockTask.downloadPath];
        [blockTask completeWithResult:result error:nil];
    }];
}

@end
