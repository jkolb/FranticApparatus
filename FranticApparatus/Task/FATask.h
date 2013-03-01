//
// FATask.h
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



#import <Foundation/Foundation.h>



@protocol FATask;



typedef NS_ENUM(NSInteger, FATaskEvent) {
    FATaskEventStart    = 0,
    FATaskEventProgress = 1,
    FATaskEventSuccess  = 2,
    FATaskEventFailure  = 3,
    FATaskEventCancel   = 4,
    FATaskEventFinish   = 5,
};

typedef NS_ENUM(NSInteger, FATaskStatus) {
    FATaskStatusPending   = 0,
    FATaskStatusSuccess   = 1,
    FATaskStatusFailure   = 2,
    FATaskStatusCancelled = 3,
};



typedef void (^FACallback)(id object);



@protocol FATask <NSObject>

- (id)initWithParameter:(id)parameter;

- (void)taskEvent:(FATaskEvent)event addCallback:(FACallback)callback;

- (void)addTarget:(id)target action:(SEL)action forTaskEvent:(FATaskEvent)event;

- (BOOL)hasActionForTaskEvent:(FATaskEvent)event;

- (id)parameter;

- (void)start;
- (void)startWithParameter:(id)parameter;

- (FATaskStatus)status;

- (BOOL)isCancelled;
- (void)cancel;

@end
