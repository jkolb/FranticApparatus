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



@implementation FAOrderedBatchTask

- (NSComparator)keyComparator {
    if (_keyComparator == nil) {
        return ^(id key1, id key2) {
            // number < string < pointer
            BOOL key1IsNumber = [key1 isKindOfClass:[NSNumber class]];
            BOOL key2IsNumber = [key2 isKindOfClass:[NSNumber class]];
            BOOL key1IsString = [key1 isKindOfClass:[NSString class]];
            BOOL key2IsString = [key2 isKindOfClass:[NSString class]];
            BOOL key1IsPointer = !key1IsNumber && !key1IsString;
            BOOL key2IsPointer = !key2IsNumber && !key2IsString;
            
            if (key1IsNumber && key2IsNumber) {
                return [key1 compare:key2];
            } else if (key1IsString && key2IsString) {
                return [key1 compare:key2];
            } else if ((key1IsNumber && (key2IsString || key2IsPointer)) || (key1IsString && key2IsPointer) || (key1 < key2)) {
                return NSOrderedAscending;
            } else if ((key2IsNumber && (key1IsString || key1IsPointer)) || (key2IsString && key1IsPointer) || (key2 > key1)) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        };
    }
    
    return _keyComparator;
}

@end
