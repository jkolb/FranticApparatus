//
// FAEvent.m
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



#import "FAEvent.h"
#import "FAEventHandler.h"



@implementation FAEvent

+ (instancetype)eventWithSource:(id)source {
    return [[self alloc] initWithSource:source];
}

- (id)init {
    return [self initWithSource:nil];
}

- (id)initWithSource:(id)source {
    self = [super init];
    if (self == nil) return nil;
    _source = source;
    return self;
}

+ (FAEventHandler *)handlerWithBlock:(FAEventHandlerBlock)block {
    return [FAEventHandler handlerWithEventClass:self block:block];
}

+ (FAEventHandler *)handlerWithContext:(id)context block:(FAEventHandlerContextBlock)block {
    return [FAEventHandler handlerWithEventClass:self context:context block:block];
}

+ (FAEventHandler *)handlerWithTarget:(id)target action:(SEL)action {
    return [FAEventHandler handlerWithEventClass:self target:target action:action];
}



#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
