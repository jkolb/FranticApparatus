//
// FAHTTPURLResponseFilter.m
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



#import "FAHTTPURLResponseFilter.h"



@implementation FAHTTPURLResponseFilter

- (id)init {
    return [self initWithErrorDomain:FAHTTPErrorDomain];
}

- (id)initWithErrorDomain:(NSString *)errorDomain {
    self = [super initWithErrorDomain:errorDomain];
    if (self == nil) return nil;
    
    _acceptableStatusCodes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(200, 100)];
    
    return self;
}

- (BOOL)shouldAllowResponse:(NSURLResponse *)response withError:(NSError **)error {
    if (![self isResponse:response allowedByFilterBlock:[self responseIsHTTPValidator] withErrorCode:FAHTTPErrorNotHTTPResponse error:error]) return NO;
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    if (![self isHTTPResponse:HTTPResponse allowedByHTTPFilterBlock:[self maximumContentLengthValidator] withErrorCode:FAHTTPErrorMaximumContentLengthExceeded error:error]) return NO;
    if (![self isHTTPResponse:HTTPResponse allowedByHTTPFilterBlock:[self acceptableStatusCodeValidator] withErrorCode:FAHTTPErrorUnacceptableStatusCode error:error]) return NO;
    if (![self isHTTPResponse:HTTPResponse allowedByHTTPFilterBlock:[self acceptableContentTypeValidator] withErrorCode:FAHTTPErrorUnacceptableContentType error:error]) return NO;
    if (![self isHTTPResponse:HTTPResponse allowedByHTTPFilterBlock:[self acceptableTextEncodingNameValidator] withErrorCode:FAHTTPErrorUnacceptableTextEncodingName error:error]) return NO;
    return [super shouldAllowResponse:response withError:error];
}

- (void)errorCode:(NSInteger)errorCode addHTTPFilterBlock:(BOOL (^)(NSHTTPURLResponse *))filterBlock {
    [super errorCode:errorCode addFilterBlock:(BOOL (^)(NSURLResponse *))filterBlock];
}

- (BOOL)isHTTPResponse:(NSHTTPURLResponse *)response allowedByHTTPFilterBlock:(BOOL (^)(NSHTTPURLResponse *))filterBlock withErrorCode:(NSInteger)errorCode error:(NSError **)error {
    return [self isResponse:response allowedByFilterBlock:(BOOL (^)(NSURLResponse *))filterBlock withErrorCode:errorCode error:error];
}

- (BOOL (^)(NSURLResponse *))responseIsHTTPValidator {
    return ^BOOL(NSURLResponse *response) {
        return [response isKindOfClass:[NSHTTPURLResponse class]];
    };
}

- (BOOL (^)(NSHTTPURLResponse *))maximumContentLengthValidator {
    long long maximumContentLength = self.maximumContentLength;
    return ^BOOL(NSHTTPURLResponse *response) {
        return maximumContentLength == 0 || (maximumContentLength > 0 && maximumContentLength >= [response expectedContentLength]);
    };
}

- (BOOL (^)(NSHTTPURLResponse *))acceptableStatusCodeValidator {
    NSIndexSet *acceptableStatusCodes = self.acceptableStatusCodes;
    return ^BOOL(NSHTTPURLResponse *response) {
        return [acceptableStatusCodes count] == 0 || ([acceptableStatusCodes count] > 0 && [acceptableStatusCodes containsIndex:[response statusCode]]);
    };
}

- (BOOL (^)(NSHTTPURLResponse *))acceptableContentTypeValidator {
    NSSet *acceptableContentTypes = self.acceptableContentTypes;
    return ^BOOL(NSHTTPURLResponse *response) {
        return [acceptableContentTypes count] == 0 || ([acceptableContentTypes count] > 0 && [acceptableContentTypes containsObject:[response MIMEType]]);
    };
}

- (BOOL (^)(NSHTTPURLResponse *))acceptableTextEncodingNameValidator {
    NSSet *acceptableTextEncodingNames = self.acceptableTextEncodingNames;
    return ^BOOL(NSHTTPURLResponse *response) {
        return [acceptableTextEncodingNames count] == 0 || ([acceptableTextEncodingNames count] > 0 && [acceptableTextEncodingNames containsObject:[response textEncodingName]]);
    };
}

@end
