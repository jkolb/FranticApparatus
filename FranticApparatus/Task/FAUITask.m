//
// FAUITask.m
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



#import "FAUITask.h"



@implementation FAUITask

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    [self.backgroundTask setParentTask:self];
    [self.backgroundTask setExcludeParentEvents:[NSSet setWithObjects:FATaskEventStarted, FATaskEventCancelled, nil]];
    [self.backgroundTask startWithParameter:parameter];
}

- (void)taskEvent:(NSString *)event addCallback:(FATaskCallback)callback {
    [super taskEvent:event addCallback:[self callbackOnMainThread:callback]];
}

- (FATaskCallback)callbackOnMainThread:(FATaskCallback)callback {
    return ^(id object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(object);
        });
    };
}

- (void)cancel {
    [self.backgroundTask cancel];
    [super cancel];
}

@end
