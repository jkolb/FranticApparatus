//
// FATaskFinishEvent.m
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



#import "FATaskFinishEvent.h"

#import "NSError+FATask.h"



@implementation FATaskFinishEvent

+ (instancetype)eventWithSource:(id)source result:(id <NSCopying>)result error:(NSError *)error {
    return [[self alloc] initWithSource:source result:result error:error];
}

- (id)initWithSource:(id)source {
    return [self initWithSource:source result:[NSNull null] error:nil];
}

- (id)initWithSource:(id)source result:(id <NSCopying>)result error:(NSError *)error {
    NSAssert(result != nil || error != nil, @"result and error must not both be nil");
    self = [super initWithSource:source];
    if (self == nil) return nil;
    _result = [(id)result copy];
    _error = [error copy];
    return self;
}

- (BOOL)hasError {
    return self.error != nil;
}

- (BOOL)hasCancelError {
    return [self.error FA_isCancelError];
}

@end
