//
// FAURLConnectionDataTask.m
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



#import "FAURLConnectionDataTask.h"
#import "FAURLConnectionDataResult.h"



@interface FAURLConnectionDataTask ()

@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;

@end



@implementation FAURLConnectionDataTask

- (void)handleResponse:(NSURLResponse *)response {
    self.response = response;
    self.data = [self dataForResponse:response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    FAURLConnectionDataResult *result = [[FAURLConnectionDataResult alloc] initWithResponse:self.response data:self.data];
    [self completeWithResult:result error:nil];
}

- (NSMutableData *)dataForResponse:(NSURLResponse *)response {
    long long expectedContentLength = [response expectedContentLength];
    
    if (expectedContentLength <= 0 || expectedContentLength > NSUIntegerMax) {
        return [[NSMutableData alloc] init];
    } else {
        NSUInteger capacity = (NSUInteger)expectedContentLength;
        return [[NSMutableData alloc] initWithCapacity:capacity];
    }
}

@end
