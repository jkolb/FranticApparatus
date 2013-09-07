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

@property (nonatomic, strong) NSMutableArray *preStartFactories;
@property (nonatomic, strong) NSLock *startLock;
@property (nonatomic, copy) NSArray *factories;
@property (nonatomic, strong) id <FATask> currentTask;

@end



@implementation FAChainedTask

- (id)init {
    return [self initWithFactories:@[]];
}

- (id)initWithFactories:(NSArray *)factories {
    self = [super init];
    if (self == nil) return nil;
    _preStartFactories = [[NSMutableArray alloc] initWithArray:factories];
    if (_preStartFactories == nil) return nil;
    for (id object in _preStartFactories) {
        if (![object isKindOfClass:[FATaskFactory class]]) return nil;
    }
    _startLock = [[NSLock alloc] init];
    if (_startLock == nil) return nil;
    return self;
}

- (void)addTaskBlock:(FATaskFactoryBlock)block {
    [self.startLock lock];
    NSAssert(self.preStartFactories != nil, @"Already started");
    [self.preStartFactories addObject:[FATaskFactory factoryWithBlock:block]];
    [self.startLock unlock];
}

- (void)addContext:(id)context taskBlock:(FATaskFactoryContextBlock)block {
    [self.startLock lock];
    NSAssert(self.preStartFactories != nil, @"Already started");
    [self.preStartFactories addObject:[FATaskFactory factoryWithContext:context block:block]];
    [self.startLock unlock];
}

- (void)addTaskTarget:(id)target action:(SEL)action {
    [self.startLock lock];
    NSAssert(self.preStartFactories != nil, @"Already started");
    [self.preStartFactories addObject:[FATaskFactory factoryWithTarget:target action:action]];
    [self.startLock unlock];
}

- (void)willStart {
    [self.startLock lock];
    NSAssert(self.preStartFactories != nil, @"Already started");
    self.factories = self.preStartFactories;
    self.preStartFactories = nil;
    [self.startLock unlock];
}

- (void)didStart {
    if ([self.factories count] > 0) {
        [self startTaskAtIndex:0 withLastResult:nil];
    } else {
        [self completeWithResult:[NSNull null] error:nil];
    }
}

- (void)startTaskAtIndex:(NSUInteger)index withLastResult:(id)lastResult {
    FATaskFactory *factory = self.factories[index];
    self.currentTask = [factory taskWithLastResult:lastResult];
    
    if (self.currentTask == nil) {
        [self completeWithResult:[NSNull null] error:nil];
        return;
    }
    
    [self onCompleteTask:self.currentTask synchronizeWithBlock:^(FATypeOfSelf blockTask, FATaskCompleteEvent *event) {
        if (event.error != nil) {
            [blockTask completeWithResult:nil error:event.error];
        } else {
            NSUInteger nextIndex = index + 1;
            
            if (nextIndex >= [blockTask.factories count]) {
                [blockTask completeWithResult:event.result error:nil];
            } else {
                [blockTask startTaskAtIndex:nextIndex withLastResult:lastResult];
            }
        }
    }];

    [self.currentTask start];
}

- (void)willCancel {
    [self.currentTask cancel];
}

- (void)willComplete {
    self.currentTask = nil;
}

@end
