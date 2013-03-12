//
// FAConditionalBatchTask.m
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



#import "FAConditionalBatchTask.h"



@implementation FAConditionalBatchTask

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    NSError *error = nil;
    id taskKey = [self determineTaskKeyWithError:&error];
    
    if (taskKey == nil) {
        [self triggerEventWithType:FATaskEventTypeError payload:error];
        [self triggerEventWithType:FATaskEventTypeFinish payload:nil];
        return;
    }
    
    id taskParameter = [self determineTaskParameterWithError:&error];
    
    if (taskParameter == nil) {
        [self triggerEventWithType:FATaskEventTypeError payload:error];
        [self triggerEventWithType:FATaskEventTypeFinish payload:nil];
        return;
    }
    
    [self startTaskForKey:taskKey withParameter:taskParameter];
}

- (id)determineTaskKeyWithError:(NSError **)error {
    if (self.determineTaskKey == nil) return [[self allKeys] lastObject];
    return self.determineTaskKey([self parameter], error);
}

- (id)determineTaskParameterWithError:(NSError **)error {
    id parameter = [self parameter];
    if (self.determineTaskParameter == nil) return parameter;
    return self.determineTaskParameter(parameter, error);
}

- (void)configureTask:(id<FATask>)task withKey:(id)key {
    for (NSString *eventType in [self registeredEventTypes]) {
        [task forwardEventType:eventType toTask:self];
    }
}

@end
