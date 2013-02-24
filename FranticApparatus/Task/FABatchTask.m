//
// FABatchTask.m
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



#import "FABatchTask.h"



@interface FABatchTask ()

@property (nonatomic, strong) NSMutableDictionary *subtaskFactory;
@property (nonatomic, strong) NSMutableDictionary *subtask;

@end



@implementation FABatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _subtaskFactory = [[NSMutableDictionary alloc] init];
    if (_subtaskFactory == nil) return nil;
    
    _subtask = [[NSMutableDictionary alloc] init];
    if (_subtask == nil) return nil;
    
    return self;
}

- (NSSet *)allKeys {
    NSMutableSet *allKeys = [[NSMutableSet alloc] init];
    [allKeys addObjectsFromArray:[self.subtaskFactory allKeys]];
    [allKeys addObjectsFromArray:[self.subtask allKeys]];
    return allKeys;
}

- (void)setSubtaskFactory:(id <FATask> (^)(id parameter))subtaskFactory forKey:(id <NSCopying>)key {
    [self.subtaskFactory setObject:subtaskFactory forKey:key];
}

- (id <FATask>)subtaskWithKey:(id)key parameter:(id)parameter {
    id <FATask> subtask = [self subtaskForKey:key];
    
    if (subtask == nil) {
        id <FATask> (^subtaskFactory)(id parameter) = [self.subtaskFactory objectForKey:key];
        if (subtaskFactory == nil) return nil;
        subtask = subtaskFactory(parameter);
        [self setSubtask:subtask forKey:key];
    }
    
    return subtask;
}

- (void)configureSubtask:(id <FATask>)subtask withKey:(id)key {
    typeof(self) __weak weakSelf = self;
    [subtask setOnStart:^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf subtaskDidStartWithKey:key];
    }];
    [subtask setOnProgress:^(id progress) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf subtaskWithKey:key didReportProgress:progress];
    }];
    [subtask setOnResult:^(id result) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf subtaskWithKey:key didFinishWithResult:result];
    }];
    [subtask setOnError:^(NSError *error) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf subtaskWithKey:key didFinishWithError:error];
    }];
    [subtask setOnFinish:^{
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf subtaskDidFinishWithKey:key];
    }];
}

- (id <FATask>)subtaskForKey:(id)key {
    return [self.subtask objectForKey:key];
}

- (void)setSubtask:(id <FATask>)subtask forKey:(id <NSCopying>)key {
    [self.subtask setObject:subtask forKey:key];
    [self configureSubtask:subtask withKey:key];
}

- (void)subtaskDidStartWithKey:(id)key {
    
}

- (void)subtaskWithKey:(id)key didReportProgress:(id)progress {
    
}

- (void)subtaskWithKey:(id)key didFinishWithResult:(id)result {
    
}

- (void)subtaskWithKey:(id)key didFinishWithError:(NSError *)error {
    
}

- (void)subtaskDidFinishWithKey:(id)key {
    
}

@end
