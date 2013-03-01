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



@interface FAUITask ()

@property (strong) id <FATask> backgroundTask;

@end



@implementation FAUITask

- (id)init {
    return [self initWithBackgroundTask:nil];
}

- (id)initWithBackgroundTask:(id <FATask>)backgroundTask {
    self = [super init];
    if (self == nil) return nil;
    
    _backgroundTask = backgroundTask;
    if (_backgroundTask == nil) return nil;
    
    return self;
}

- (void)startWithParameter:(id)parameter {
    typeof(self) __weak weakSelf = self;
    
    if (self.onStart) {
        self.backgroundTask.onStart = self.onStart;
    }
    
    if (self.onProgress) {
        [self.backgroundTask setOnProgress:^(id progress) {
            typeof(self) blockSelf = weakSelf;
            if (blockSelf == nil) return;
            if ([blockSelf isCancelled]) return;
            [blockSelf reportProgressOnMainThread:progress];
        }];
    }
    
    if (self.onResult) {
        [self.backgroundTask setOnResult:^(id result) {
            typeof(self) blockSelf = weakSelf;
            if (blockSelf == nil) return;
            if ([blockSelf isCancelled]) return;
            [blockSelf returnResultOnMainThread:result];
        }];
    }
    
    if (self.onError) {
        [self.backgroundTask setOnError:^(id error) {
            typeof(self) blockSelf = weakSelf;
            if (blockSelf == nil) return;
            if ([blockSelf isCancelled]) return;
            [blockSelf returnErrorOnMainThread:error];
        }];
    }
    
    if (self.onFinish) {
        [self.backgroundTask setOnFinish:^(id object){
            typeof(self) blockSelf = weakSelf;
            if (blockSelf == nil) return;
            if ([blockSelf isCancelled]) return;
            [blockSelf finishOnMainThread];
        }];
    }
    
    [self.backgroundTask startWithParameter:parameter];
}

- (void)cancel {
    [super cancel];
    [self.backgroundTask cancel];
}

- (void)reportProgressOnMainThread:(id)progress {
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf reportProgress:progress];
    });
}

- (void)returnResultOnMainThread:(id)result {
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf succeedWithResult:result];
    });
}

- (void)returnErrorOnMainThread:(NSError *)error {
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf failWithError:error];
    });
}

- (void)finishOnMainThread {
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf finish];
    });
}

@end
