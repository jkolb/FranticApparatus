//
// FATaskFactory.m
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



#import "FATaskFactory.h"



@interface FATaskFactory ()

@property (nonatomic, copy) id <FATask> (^chainBlock)(id lastResult);

@end



@implementation FATaskFactory

+ (instancetype)taskFactoryWithTask:(id <FATask>)task {
    return [[self alloc] initWithChainBlock:^id <FATask> (id lastResult) {
        return task;
    }];
}

+ (instancetype)taskFactoryWithBlock:(id <FATask> (^)())block {
    return [[self alloc] initWithChainBlock:^id <FATask> (id lastResult) {
        if (block == nil) return nil;
        return block();
    }];
}

+ (instancetype)taskFactoryWithChainBlock:(id <FATask> (^)(id lastResult))chainBlock {
    return [[self alloc] initWithChainBlock:chainBlock];
}

- (id)init {
    return [self initWithChainBlock:^id <FATask> (id lastResult) {
        return nil;
    }];
}

- (id)initWithChainBlock:(id <FATask> (^)(id lastResult))chainBlock {
    self = [super init];
    if (self == nil) return nil;
    _chainBlock = chainBlock;
    if (_chainBlock == nil) return nil;
    return self;
}

- (id <FATask>)task {
    return [self taskWithLastResult:nil];
}

- (id <FATask>)taskWithLastResult:(id)lastResult {
    id <FATask> task = self.chainBlock(lastResult);
    if (task == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"chainBlock generated nil task"
                                     userInfo:nil];
    }
    return task;
}



#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
