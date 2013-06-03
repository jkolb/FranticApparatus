//
// FranticApparatus.h
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



// Event
#import "FAEvent.h"
#import "FAEventHandler.h"
#import "FAEventDispatcher.h"

// Task
#import "FATask.h"
#import "FAAbstractTask.h"
#import "FABackgroundTask.h"
#import "FAParallelTask.h"
#import "FAChainedTask.h"
#import "FARetryTask.h"
#import "FANullTask.h"

// Task Events
#import "FATaskEvent.h"
#import "FATaskStartEvent.h"
#import "FATaskCancelEvent.h"
#import "FATaskFinishEvent.h"
#import "FATaskResultEvent.h"
#import "FATaskErrorEvent.h"
#import "FATaskRestartEvent.h"
#import "FATaskDelayEvent.h"
#import "FATaskProgressEvent.h"

// Network Task
#import "FAURLConnectionTask.h"
#import "FAURLConnectionDataTask.h"
#import "FAURLConnectionDownloadTask.h"

// Network Utility
#import "FAHTTPError.h"
#import "NSURLResponse+StringEncoding.h"

// Network Filter
#import "FAURLResponseFilter.h"
#import "FACustomURLResponseFilter.h"
#import "FAHTTPURLResponseFilter.h"

// Network Progress
#import "FAURLConnectionReceiveProgress.h"

// Network Results
#import "FAURLConnectionResult.h"
#import "FAURLConnectionDataResult.h"
#import "FAURLConnectionDownloadResult.h"
