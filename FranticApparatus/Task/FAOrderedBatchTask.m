//
// FAOrderedBatchTask.m
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



#import "FAOrderedBatchTask.h"



@interface FAOrderedBatchTask ()

@property (nonatomic, strong) NSArray *sortedKeys;
@property (nonatomic) NSUInteger currentIndex;

@end



@implementation FAOrderedBatchTask

- (NSComparator)keyComparator {
    if (_keyComparator == nil) {
        return ^(id key1, id key2) {
            return [key1 compare:key2];
        };
    }
    
    return _keyComparator;
}

- (void)addTask:(id <FATask>)task {
    [self setTask:task forKey:[self nextKey]];
}

- (void)addFactory:(FATaskFactory)factory {
    [self setFactory:factory forKey:[self nextKey]];
}

- (id)nextKey {
    return @([self count]);
}

- (void)startWithParameter:(id)parameter {
    [super startWithParameter:parameter];
    self.sortedKeys = [[self allKeys] sortedArrayUsingComparator:self.keyComparator];
    [self startCurrentTask];
}

- (void)startCurrentTask {
    id key = [self currentKey];
    id parameter = [self currentParamter];
    [self startTaskForKey:key withParameter:parameter];
}

- (id)currentKey {
    return [self.sortedKeys objectAtIndex:self.currentIndex];
}

- (id)currentParamter {
    return nil;
}

- (void)advanceToNextKey {
    ++self.currentIndex;
}

- (BOOL)isFinished {
    return self.currentIndex >= [self.sortedKeys count];
}

@end
