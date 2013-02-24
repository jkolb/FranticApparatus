//
// FABatchTask.h
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



@interface FABatchTask : FAAbstractTask

- (NSSet *)allKeys;

- (void)setSubtaskFactory:(id <FATask> (^)(id parameter))subtaskFactory forKey:(id <NSCopying>)key;

- (id <FATask>)subtaskWithKey:(id)key parameter:(id)parameter;

- (void)configureSubtask:(id <FATask>)subtask withKey:(id)key;

- (id <FATask>)subtaskForKey:(id)key;
- (void)setSubtask:(id <FATask>)subtask forKey:(id <NSCopying>)key;

- (void)subtaskDidStartWithKey:(id)key;
- (void)subtaskWithKey:(id)key didReportProgress:(id)progress;
- (void)subtaskWithKey:(id)key didFinishWithResult:(id)result;
- (void)subtaskWithKey:(id)key didFinishWithError:(NSError *)error;
- (void)subtaskDidFinishWithKey:(id)key;

@end
