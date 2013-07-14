//
// FAChainedTask.m
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



#import "FAChainedTask.h"
#import "FATaskCompleteEvent.h"
#import "FATaskFactory.h"



@interface FAChainedTask ()

@property (copy, readonly) NSArray *factories;
@property (strong) id <FATask> currentTask;
@property (strong) id lastResult;
@property (strong) NSError *lastError;

@end



@implementation FAChainedTask

- (id)init {
    return [self initWithFactories:@[]];
}

- (id)initWithFactories:(NSArray *)factories {
    self = [super init];
    if (self == nil) return nil;
    _factories = [factories copy];
    if (_factories == nil) return nil;
    for (id object in _factories) {
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
    }
    return self;
}

- (void)didStart {
    [self startTaskAtIndex:0];
}

- (void)startTaskAtIndex:(NSUInteger)index {
    if (index >= [self.factories count] || self.lastError != nil) {
        [self completeWithResult:self.lastResult error:self.lastError];
        return;
    }
    
    FATaskFactory *factory = self.factories[index];
    id <FATask> task = [factory taskWithLastResult:self.lastResult];
    
    if (task == nil) {
        [self completeWithResult:nil error:nil];
        return;
    }
    
    [self onCompleteTask:task execute:^(FATypeOfSelf blockTask, FATaskCompleteEvent *event) {
        blockTask.lastResult = event.result;
        blockTask.lastError = event.error;
        [blockTask startTaskAtIndex:index + 1];
    }];

    self.currentTask = task;
    [task start];
}

- (void)willCancel {
    [self.currentTask cancel];
}

- (void)willComplete {
    self.currentTask = nil;
}

@end
