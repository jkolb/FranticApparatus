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



NSString * const FAURLDownloadErrorDomain = @"FAURLDownloadErrorDomain";

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
    [self.buffer appendData:data];
    
    NSError *error = nil;
    BOOL success = [self writeAsMuchDataAsPossibleToOutputStreamAndReportProgressWithError:&error];
    
    if (!success) {
        [self failWithError:error];
    }
}

- (BOOL)writeAsMuchDataAsPossibleToOutputStreamAndReportProgressWithError:(NSError **)error {
    NSInteger bytesWritten = [self writeData:self.buffer toOutputStream:self.outputStream withError:error];
    
    if (bytesWritten < 0) return NO;

    if (bytesWritten > 0) {
        [self.buffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
        [self.progress addBytes:bytesWritten];
        [self triggerEventWithType:FATaskEventTypeProgress payload:[self.progress copy]];
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

- (void)cleanup {
    [super cleanup];
    [self.outputStream close];
    self.outputStream = nil;
    self.progress = nil;
    self.buffer = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    while ([self.buffer length] > 0) {
        NSError *error = nil;
        BOOL success = [self writeAsMuchDataAsPossibleToOutputStreamAndReportProgressWithError:&error];
        
        if (!success) {
            [self failWithError:error];
            return;
        }
    }
    
    [self succeedWithResult:self.result];
}

@end
