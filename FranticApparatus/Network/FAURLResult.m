//
// FAURLResult.m
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



#import "FAURLResult.h"
#import "NSURLResponse+StringEncoding.h"



@interface FAURLResult ()

@property (nonatomic, strong) NSMutableData *mutableData;

@end



@implementation FAURLResult

- (id)init {
    return [self initWithResponse:[[NSURLResponse alloc] init]];
}

- (id)initWithResponse:(NSURLResponse *)response {
    self = [super init];
    if (self == nil) return nil;
    
    _response = response;
    if (_response == nil) return nil;
    
    
    long long expectedContentLength = [_response expectedContentLength];
    
    if (expectedContentLength <= 0 || expectedContentLength > NSUIntegerMax) {
        _mutableData = [[NSMutableData alloc] init];
    } else {
        NSUInteger capacity = (NSUInteger)expectedContentLength;
        _mutableData = [[NSMutableData alloc] initWithCapacity:capacity];
    }
    
    if (_mutableData == nil) return nil;
    
    return self;
}

- (NSData *)data {
    return self.mutableData;
}

- (NSString *)text {
    return [[NSString alloc] initWithData:self.mutableData encoding:[self.response stringEncoding]];
}

- (void)appendData:(NSData *)data {
    [self.mutableData appendData:data];
}

- (NSHTTPURLResponse *)HTTPResponse {
    if ([self.response isKindOfClass:[NSHTTPURLResponse class]] == NO) return nil;
    return (NSHTTPURLResponse *)self.response;
}

@end
