//
// FAParallelBatchTask.m
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



#import "FAParallelBatchTask.h"
#import "FABatchResult.h"



@interface FAParallelBatchTask ()

@property (nonatomic) NSUInteger finishedCount;

@end



@implementation FAParallelBatchTask

- (id)initWithParameterDictionary:(NSDictionary *)parameters {
    return [self initWithParameter:parameters];
}

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    
    for (id key in [self allKeys]) {
        [self startTaskForKey:key withParameter:[self parameterForKey:key]];
    }
}

- (id)parameterForKey:(id)key {
    return [[self parameter] objectForKey:key];
}

- (void)configureTask:(id<FATask>)task withKey:(id)key {
    [task eventType:FATaskEventTypeResult task:self addTaskHandler:^(__typeof__(self) blockTask, FATaskEvent *event) {
        FABatchResult *result = [[FABatchResult alloc] initWithKey:key value:event.payload];
        [blockTask triggerEventWithType:FATaskEventTypeResult payload:result];
    }];
    
    [task eventType:FATaskEventTypeError task:self addTaskHandler:^(__typeof__(self) blockTask, FATaskEvent *event) {
        FABatchResult *error = [[FABatchResult alloc] initWithKey:key value:event.payload];
        [blockTask triggerEventWithType:FATaskEventTypeError payload:error];
    }];

    [task eventType:FATaskEventTypeFinish task:self addTaskHandler:^(__typeof__(self) blockTask, FATaskEvent *event) {
        ++blockTask.finishedCount;
        
        if (blockTask.finishedCount >= [blockTask count]) {
            [blockTask triggerEventWithType:FATaskEventTypeFinish payload:nil];
        }
    }];
}

@end
