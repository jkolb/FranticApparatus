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

@property (nonatomic, strong) NSMutableDictionary *tasks;

@end



@implementation FABatchTask

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:2];
    if (_tasks == nil) return nil;
    
    return self;
}

- (void)dealloc {
    for (id key in _tasks) {
        id <FATask> task = [_tasks objectForKey:key];
        [task cancel];
    }
}

- (void)setTask:(id <FATask>)task forKey:(id <NSCopying>)key {
    [self.tasks setObject:task forKey:key];
}

- (void)setFactory:(FATaskFactory)factory forKey:(id <NSCopying>)key {
    [self.tasks setObject:factory forKey:key];
}

- (NSArray *)allKeys {
    return [self.tasks allKeys];
}

- (NSUInteger)count {
    return [self.tasks count];
}

- (id <FATask>)taskWithKey:(id)key parameter:(id)parameter {
    id object = [self.tasks objectForKey:key];
    if (object == nil) return nil;
    id <FATask> task;
    
    if ([object conformsToProtocol:@protocol(FATask)]) {
        task = object;
    } else {
        FATaskFactory factory = object;
        task = factory(parameter);
        [self.tasks setObject:task forKey:key];
    }
    
    return task;
}

- (void)configureTask:(id <FATask>)task withKey:(id)key {
}

- (void)startTaskForKey:(id)key withParameter:(id)parameter {
    id <FATask> task = [self taskWithKey:key parameter:parameter];
    [self configureTask:task withKey:key];
    [task startWithParameter:parameter];
}

- (void)cancel {
    for (id key in self.tasks) {
        id <FATask> task = [self.tasks objectForKey:key];
        [task cancel];
    }
    
    [super cancel];
}

@end
