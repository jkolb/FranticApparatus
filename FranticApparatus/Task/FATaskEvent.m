//
// FATaskEvent.m
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



#import "FATaskEvent.h"



@interface FATaskEvent ()

@property (nonatomic) BOOL consumed;

@end



@implementation FATaskEvent

- (id)init {
    return [self initWithType:@"" source:nil payload:nil];
}

- (id)initWithType:(NSString *)type source:(id <FATask>)source payload:(id)payload {
    self = [super init];
    if (self == nil) return nil;
    
    _type = type;
    if ([_type length] == 0) return nil;
    
    _source = source;
    if (_source == nil) return nil;
    
    _payload = payload;
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
