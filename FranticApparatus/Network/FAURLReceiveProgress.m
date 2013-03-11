//
// FAURLReceiveProgress.m
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



#import "FAURLReceiveProgress.h"



@implementation FAURLReceiveProgress

- (id)init {
    return [self initWithBytesReceived:0 totalBytesReceived:0 expectedTotalBytes:0];
}

- (id)initWithBytesReceived:(long long)bytesReceived totalBytesReceived:(long long)totalBytesReceived expectedTotalBytes:(long long)expectedTotalBytes {
    self = [super init];
    if (self == nil) return nil;

    _bytesReceived = bytesReceived;
    _totalBytesReceived = totalBytesReceived;
    _expectedTotalBytes = expectedTotalBytes;
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[FAMutableURLReceiveProgress alloc] initWithBytesReceived:self.bytesReceived totalBytesReceived:self.totalBytesReceived expectedTotalBytes:self.expectedTotalBytes];
}

@end



@implementation FAMutableURLReceiveProgress

- (id)initWithExpectedTotalBytes:(long long)expectedTotalBytes {
    return [self initWithBytesReceived:0 totalBytesReceived:0 expectedTotalBytes:expectedTotalBytes];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[FAURLReceiveProgress alloc] initWithBytesReceived:self.bytesReceived totalBytesReceived:self.totalBytesReceived expectedTotalBytes:self.expectedTotalBytes];
}

- (void)addBytes:(NSUInteger)count {
    self.bytesReceived = count;
    self.totalBytesReceived += count;
}

@end
