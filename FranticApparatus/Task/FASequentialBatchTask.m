//
// FASequentialBatchTask.m
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



#import "FASequentialBatchTask.h"



@interface FASequentialBatchTask ()

@property (nonatomic, strong) NSArray *sortedKeys;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, strong) NSMutableDictionary *parameters;
@property (nonatomic, strong) id <FATask> currentTask;
@property (nonatomic, strong) id lastResult;

@end



@implementation FASequentialBatchTask

+ (id)sequentialBatchTaskWithParameters:(NSArray *)parameters {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[parameters count]];
    NSUInteger index = 0;
    
    for (id parameter in parameters) {
        NSNumber *key = [[NSNumber alloc] initWithUnsignedInteger:index];
        [dictionary setObject:parameter forKey:key];
    }
    
    return [(FASequentialBatchTask *)[self alloc] initWithParameters:dictionary];
}

- (id)init {
    return [self initWithParameters:nil];
}

- (id)initWithParameters:(NSDictionary *)parameters {
    self = [super init];
    if (self == nil) return nil;
    
    _parameters = [[NSMutableDictionary alloc] initWithDictionary:parameters];
    
    return self;
}

- (id)addKey {
    return [NSNumber numberWithUnsignedInteger:[self count]];
}

- (void)addTask:(id <FATask>)task {
    [self setTask:task forKey:[self addKey]];
}

- (void)addFactory:(FATaskFactory)factory {
    [self setFactory:factory forKey:[self addKey]];
}

- (id)parameter {
    return self.parameters;
}

- (id)currentKey {
    return [self.sortedKeys objectAtIndex:self.currentIndex];
}

- (id)currentParameter {
    return [self.parameters objectForKey:[self currentKey]];
}

- (void)startCurrentTask {
    self.currentTask = [self taskWithKey:[self currentKey] parameter:[self currentParameter]];
    [self.currentTask start];
}

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    
    if ([self parameter] == nil) {
        if (parameter != nil && [parameter isKindOfClass:[NSDictionary class]] == NO) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"parameter must be an NSDictionary" userInfo:nil];
        }
        
        self.parameters = parameter;
    }
    
    self.sortedKeys = [[[self allKeys] allObjects] sortedArrayUsingComparator:self.keyComparator];
    [self startCurrentTask];
}

- (void)cancel {
    [self.currentTask cancel];
    [super cancel];
}

- (void)taskWithKeyDidFinish:(id)key {
    ++self.currentIndex;
    
    if (self.currentIndex < [self count]) {
        [self startCurrentTask];
    } else {
        [self finish];
    }
}

@end
