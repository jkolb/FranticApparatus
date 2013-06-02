//
// FAURLConnectionTask.m
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



#import "FAURLConnectionTask.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskFinishEvent.h"
#import "FAURLResponseValidator.h"



@interface FAURLConnectionTask () <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSError *error;

@end



@implementation FAURLConnectionTask

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super init];
    if (self == nil) return nil;
    _request = request;
    if (_request == nil) return nil;
    return self;
}

- (void)didStart {
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                      delegate:self
                                              startImmediately:NO];
    NSOperationQueue *queue = self.queue;
    if (queue != nil) [self.connection setDelegateQueue:queue];
    [self.connection start];
}

- (id)result {
    return nil;
}

- (void)willCancel {
    [self.connection cancel];
}

- (void)handleValidResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSError *error = nil;
    BOOL isValidResponse = YES;
    
    if (self.responseValidator != nil) {
        isValidResponse = [self.responseValidator isValidResponse:response withError:&error];
    }
    
    if (isValidResponse) {
        [self handleValidResponse:response];
    } else {
        [connection cancel];
        self.error = error;
        [self finish];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.error = error;
    [self finish];
}

- (void)willFinish {
    if (self.error == nil) {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:[self result]]];
    } else {
        [self dispatchEvent:[FATaskErrorEvent eventWithSource:self error:self.error]];
    }
}

@end
