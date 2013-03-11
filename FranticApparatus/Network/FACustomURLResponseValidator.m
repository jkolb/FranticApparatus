//
// FACustomURLResponseValidator.m
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



#import "FACustomURLResponseValidator.h"



@interface FACustomURLResponseValidator ()

@property (nonatomic, copy) NSString *errorDomain;
@property (nonatomic, strong) NSMutableDictionary *validatorsByErrorCode;

@end



@implementation FACustomURLResponseValidator

- (id)init {
    return [self initWithErrorDomain:nil];
}

- (id)initWithErrorDomain:(NSString *)errorDomain {
    self = [super init];
    if (self == nil) return nil;
    
    _errorDomain = errorDomain;
    if ([_errorDomain length] == 0) return nil;
    
    _validatorsByErrorCode = [[NSMutableDictionary alloc] initWithCapacity:1];
    if (_validatorsByErrorCode == nil) return nil;
    
    return self;
}

- (void)errorCode:(NSInteger)errorCode addValidator:(BOOL (^)(NSURLResponse *))validator {
    NSNumber *errorCodeKey = @(errorCode);
    NSMutableArray *validators = [self.validatorsByErrorCode objectForKey:errorCodeKey];
    
    if (validator == nil) {
        validators = [[NSMutableArray alloc] initWithCapacity:1];
        [self.validatorsByErrorCode setObject:validators forKey:errorCodeKey];
    }
    
    [validators addObject:validator];
}

- (BOOL)isValidResponse:(NSURLResponse *)response withError:(NSError **)error {
    for (NSNumber *errorCode in self.validatorsByErrorCode) {
        NSArray *validators = [self.validatorsByErrorCode objectForKey:errorCode];
        
        for (BOOL (^validator)(NSURLResponse *) in validators) {
            if (![self isResponse:response validForValidator:validator errorCode:[errorCode integerValue] withError:error]) return NO;
        }
    }
    
    return YES;
}

- (BOOL)isResponse:(NSURLResponse *)response validForValidator:(BOOL (^)(NSURLResponse *))validator errorCode:(NSInteger)errorCode withError:(NSError **)error {
    if (!validator(response)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:self.errorDomain code:errorCode userInfo:@{@"response": response}];
        }
        
        return NO;
    }
    
    return YES;
}

@end
