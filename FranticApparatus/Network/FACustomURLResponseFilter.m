//
// FACustomURLResponseFilter.m
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



#import "FACustomURLResponseFilter.h"



@interface FACustomURLResponseFilter ()

@property (nonatomic, copy) NSString *errorDomain;
@property (nonatomic, strong) NSMutableDictionary *filterBlocksByErrorCode;

@end



@implementation FACustomURLResponseFilter

- (id)init {
    return [self initWithErrorDomain:nil];
}

- (id)initWithErrorDomain:(NSString *)errorDomain {
    self = [super init];
    if (self == nil) return nil;
    
    _errorDomain = errorDomain;
    if ([_errorDomain length] == 0) return nil;
    
    _filterBlocksByErrorCode = [[NSMutableDictionary alloc] initWithCapacity:1];
    if (_filterBlocksByErrorCode == nil) return nil;
    
    return self;
}

- (void)errorCode:(NSInteger)errorCode addFilterBlock:(BOOL (^)(NSURLResponse *))filterBlock {
    NSNumber *errorCodeKey = @(errorCode);
    NSMutableArray *validators = [self.filterBlocksByErrorCode objectForKey:errorCodeKey];
    
    if (filterBlock == nil) {
        validators = [[NSMutableArray alloc] initWithCapacity:1];
        [self.filterBlocksByErrorCode setObject:validators forKey:errorCodeKey];
    }
    
    [validators addObject:filterBlock];
}

- (BOOL)shouldAllowResponse:(NSURLResponse *)response withError:(NSError **)error {
    for (NSNumber *errorCode in self.filterBlocksByErrorCode) {
        NSArray *validators = [self.filterBlocksByErrorCode objectForKey:errorCode];
        
        for (BOOL (^validator)(NSURLResponse *) in validators) {
            if (![self isResponse:response allowedByFilterBlock:validator withErrorCode:[errorCode integerValue] error:error]) return NO;
        }
    }
    
    return YES;
}

- (BOOL)isResponse:(NSURLResponse *)response allowedByFilterBlock:(BOOL (^)(NSURLResponse *))filterBlock withErrorCode:(NSInteger)errorCode error:(NSError **)error {
    if (!filterBlock(response)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:self.errorDomain code:errorCode userInfo:@{FAErrorFilteredResponseKey: response}];
        }
        
        return NO;
    }
    
    return YES;
}

@end
