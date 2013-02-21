//
// FAGrandCentralDispatchTask.h
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



#import "FAAbstractTask.h"



@interface FAGCDTask : FAAbstractTask

+ (dispatch_queue_t)mainQueue;
+ (dispatch_queue_t)highPriorityQueue;
+ (dispatch_queue_t)defaultPriorityQueue;
+ (dispatch_queue_t)lowPriorityQueue;
+ (dispatch_queue_t)backgroundPriorityQueue;

- (id)initWithMainQueue;
- (id)initWithHighPriorityQueue;
- (id)initWithDefaultPriorityQueue;
- (id)initWithLowPriorityQueue;
- (id)initWithBackgroundPriorityQueue;
- (id)initWithQueue:(dispatch_queue_t)queue;

- (void)main;

@end