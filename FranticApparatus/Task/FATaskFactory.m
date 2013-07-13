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



NS_INLINE FATaskFactoryBlock FATaskFactoryContextBlockMake(id context, FATaskFactoryContextBlock contextBlock);
NS_INLINE FATaskFactoryBlock FATaskFactoryTargetActionBlockMake(id target, SEL action);



@interface FATaskFactory ()

@property (nonatomic, copy) FATaskFactoryBlock block;

@end



@implementation FATaskFactory

+ (instancetype)factoryWithBlock:(FATaskFactoryBlock)block {
    return [[self alloc] initWithBlock:block];
}

+ (instancetype)factoryWithContext:(id)context block:(FATaskFactoryContextBlock)block {
    return [[self alloc] initWithBlock:FATaskFactoryContextBlockMake(context, block)];
}

+ (instancetype)factoryWithTarget:(id)target action:(SEL)action {
    return [[self alloc] initWithBlock:FATaskFactoryTargetActionBlockMake(target, action)];
}

- (id)init {
    return [self initWithBlock:^id <FATask> (id lastResult) {
        return nil;
    }];
}

- (id)initWithBlock:(FATaskFactoryBlock)block {
    self = [super init];
    if (self == nil) return nil;
    _block = [block copy];
    if (_block == nil) return nil;
    return self;
}

- (id <FATask>)taskWithLastResult:(id)lastResult {
    return self.block(lastResult);
}



#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end



NS_INLINE FATaskFactoryBlock FATaskFactoryContextBlockMake(id context, FATaskFactoryContextBlock contextBlock) {
    __typeof__(context) __weak weakContext = context;
    return ^id <FATask> (id lastResult) {
        __typeof__(context) blockContext = weakContext;
        if (blockContext == nil) return nil;
        if (contextBlock == nil) return nil;
        return contextBlock(blockContext, lastResult);
    };
}

NS_INLINE FATaskFactoryBlock FATaskFactoryTargetActionBlockMake(id target, SEL action) {
    return FATaskFactoryContextBlockMake(target, ^id<FATask>(id blockTarget, id lastResult) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [blockTarget performSelector:action withObject:lastResult];
#pragma clang diagnostic pop
    });
}
