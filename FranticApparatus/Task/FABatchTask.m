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

@property (nonatomic, strong) NSMutableSet *keys;
@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *factories;

@end



@implementation FABatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _keys = [[NSMutableSet alloc] initWithCapacity:2];
    if (_keys == nil) return nil;
    
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_tasks == nil) return nil;
    
    _factories = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_factories == nil) return nil;
    
    return self;
}

- (void)setTask:(id <FATask>)task forKey:(id <NSCopying>)key {
    if ([self.allKeys containsObject:key]) {
        NSString *reason = [NSString stringWithFormat:@"Key '%@' already exists in batch", key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    [self.keys addObject:key];
    [self.tasks setObject:task forKey:key];
    [self configureTask:task withKey:key];
}

- (void)setFactory:(FATaskFactory)factory forKey:(id <NSCopying>)key {
    if ([self.allKeys containsObject:key]) {
        NSString *reason = [NSString stringWithFormat:@"Key '%@' already exists in batch", key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    [self.keys addObject:key];
    [self.factories setObject:factory forKey:key];
}

- (NSSet *)allKeys {
    return [self.keys copy];
}

- (NSUInteger)count {
    return [self.keys count];
}

- (id <FATask>)taskForKey:(id)key {
    return [self.tasks objectForKey:key];
}

- (id <FATask>)taskWithKey:(id)key parameter:(id)parameter {
    id <FATask> task = [self taskForKey:key];
    
    if (task == nil) {
        FATaskFactory factory = [self.factories objectForKey:key];
        if (factory == nil) return nil;
        task = factory(parameter);
        [self setTask:task forKey:key];
    }
    
    return task;
}

- (void)configureTask:(id <FATask>)task withKey:(id)key {
    task.onStart = [self callbackForEvent:FATaskEventStart forKey:key];
    task.onProgress = [self callbackForEvent:FATaskEventProgress forKey:key];
    task.onResult = [self callbackForEvent:FATaskEventResult forKey:key];
    task.onError = [self callbackForEvent:FATaskEventError forKey:key];
    task.onCancel = [self callbackForEvent:FATaskEventCancel forKey:key];
    task.onFinish = [self callbackForEvent:FATaskEventFinish forKey:key];
}

- (FACallback)callbackForEvent:(FATaskEvent)event forKey:(id)key {
    typeof(self) __weak weakSelf = self;
    return ^(id object) {
        typeof(self) blockSelf = weakSelf;
        if (blockSelf == nil) return;
        if ([blockSelf isCancelled]) return;
        [blockSelf event:event didTriggerForKey:key withObject:object];
    };
}

- (void)event:(FATaskEvent)event didTriggerForKey:(id)key withObject:(id)object {
    switch (event) {
        case FATaskEventStart:
            if (self.onKeyStart) self.onKeyStart(key, object);
            [self taskWithKeyDidStart:key];
            break;
            
        case FATaskEventProgress:
            if (self.onKeyProgress) self.onKeyProgress(key, object);
            [self taskWithKey:key didReportProgress:object];
            break;
            
        case FATaskEventResult:
            if (self.onKeyResult) self.onKeyResult(key, object);
            [self taskWithKey:key didSucceedWithResult:object];
            break;
            
        case FATaskEventError:
            if (self.onKeyError) self.onKeyError(key, object);
            [self taskWithKey:key didFailWithError:object];
            break;
            
        case FATaskEventCancel:
            if (self.onKeyCancel) self.onKeyCancel(key, object);
            [self taskWithKeyDidCancel:key];
            break;
            
        case FATaskEventFinish:
            if (self.onKeyFinish) self.onKeyFinish(key, object);
            [self taskWithKeyDidFinish:key];
            break;
            
        default:
            break;
    }
}

- (void)taskWithKeyDidStart:(id)key {
    
}

- (void)taskWithKey:(id)key didReportProgress:(id)progress {
    
}

- (void)taskWithKey:(id)key didSucceedWithResult:(id)result {
    
}

- (void)taskWithKey:(id)key didFailWithError:(id)error {
    
}

- (void)taskWithKeyDidCancel:(id)key {
    
}

- (void)taskWithKeyDidFinish:(id)key {
    
}

@end
