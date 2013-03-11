//
// FAHTTPURLResponseValidator.m
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



#import "FAHTTPURLResponseValidator.h"



@implementation FAHTTPURLResponseValidator

- (id)init {
    self = [super init];
    if (self == nil) return nil;
    
    _acceptableStatusCodes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(200, 100)];
    
    return self;
}

- (BOOL)isValidResponse:(NSURLResponse *)response withError:(NSError **)error {
    if (![self isResponse:response validForValidator:[self responseIsHTTPValidator] errorCode:FAHTTPErrorCodeInvalidResponse withError:error]) return NO;
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    if (![self isHTTPResponse:HTTPResponse validForHTTPValidator:[self contentLengthValidator] errorCode:FAHTTPErrorCodeUnacceptableContentLength withError:error]) return NO;
    if (![self isHTTPResponse:HTTPResponse validForHTTPValidator:[self statusCodeValidator] errorCode:FAHTTPErrorCodeUnacceptableStatusCode withError:error]) return NO;
    if (![self isHTTPResponse:HTTPResponse validForHTTPValidator:[self contentTypeValidator] errorCode:FAHTTPErrorCodeUnacceptableContentType withError:error]) return NO;
    if (![self isHTTPResponse:HTTPResponse validForHTTPValidator:[self textEncodingNameValidator] errorCode:FAHTTPErrorCodeUnacceptableTextEncodingName withError:error]) return NO;
    return [super isValidResponse:response withError:error];
}

- (void)errorCode:(NSInteger)errorCode addHTTPValidator:(BOOL (^)(NSHTTPURLResponse *))validator {
    [super errorCode:errorCode addValidator:(BOOL (^)(NSURLResponse *))validator];
}

- (BOOL)isHTTPResponse:(NSHTTPURLResponse *)response validForHTTPValidator:(BOOL (^)(NSHTTPURLResponse *))validator errorCode:(NSInteger)errorCode withError:(NSError **)error {
    return [self isResponse:response validForValidator:(BOOL (^)(NSURLResponse *))validator errorCode:errorCode withError:error];
}

- (BOOL (^)(NSURLResponse *))responseIsHTTPValidator {
    return ^BOOL(NSURLResponse *response) {
        return [response isKindOfClass:[NSHTTPURLResponse class]];
    };
}

- (BOOL (^)(NSHTTPURLResponse *))contentLengthValidator {
    long long maximumContentLength = self.maximumContentLength;
    return ^BOOL(NSHTTPURLResponse *response) {
        return maximumContentLength > 0 && maximumContentLength <= [response expectedContentLength];
    };
}

- (BOOL (^)(NSHTTPURLResponse *))statusCodeValidator {
    NSIndexSet *acceptableStatusCodes = self.acceptableStatusCodes;
    return ^BOOL(NSHTTPURLResponse *response) {
        return [acceptableStatusCodes count] > 0 && [acceptableStatusCodes containsIndex:[response statusCode]];
    };
}

- (BOOL (^)(NSHTTPURLResponse *))contentTypeValidator {
    NSSet *acceptableContentTypes = self.acceptableContentTypes;
    return ^BOOL(NSHTTPURLResponse *response) {
        return [acceptableContentTypes count] > 0 && [acceptableContentTypes containsObject:[response MIMEType]];
    };
}

- (BOOL (^)(NSHTTPURLResponse *))textEncodingNameValidator {
    NSSet *acceptableTextEncodingNames = self.acceptableTextEncodingNames;
    return ^BOOL(NSHTTPURLResponse *response) {
        return [acceptableTextEncodingNames count] > 0 && [acceptableTextEncodingNames containsObject:[response textEncodingName]];
    };
}

@end
