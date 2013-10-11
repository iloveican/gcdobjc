//
//  GCDQueue.m
//  GCDObjC
//
//  Copyright (c) 2012 Mark Smith. All rights reserved.
//

#import "GCDGroup.h"
#import "GCDQueue.h"

@interface GCDQueue ()
- (instancetype)initWithDispatchQueue:(dispatch_queue_t)dispatchQueue;
@end

@implementation GCDQueue

static GCDQueue *mainQueue;
static GCDQueue *globalQueue;
static GCDQueue *highPriorityGlobalQueue;
static GCDQueue *lowPriorityGlobalQueue;
static GCDQueue *backgroundPriorityGlobalQueue;

#pragma mark Global queue accessors.

+ (GCDQueue *)mainQueue {
  return mainQueue;
}

+ (GCDQueue *)globalQueue {
  return globalQueue;
}

+ (GCDQueue *)highPriorityGlobalQueue {
  return highPriorityGlobalQueue;
}

+ (GCDQueue *)lowPriorityGlobalQueue {
  return lowPriorityGlobalQueue;
}

+ (GCDQueue *)backgroundPriorityGlobalQueue {
  return backgroundPriorityGlobalQueue;
}

+ (GCDQueue *)currentQueue {
  return [[GCDQueue alloc] initWithDispatchQueue:dispatch_get_current_queue()];
}

#pragma mark Lifecycle.

+ (void)initialize {
  if (self == [GCDQueue class]) {
    mainQueue = [[GCDQueue alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    globalQueue = [[GCDQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    highPriorityGlobalQueue = [[GCDQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    lowPriorityGlobalQueue = [[GCDQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    backgroundPriorityGlobalQueue = [[GCDQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
  }
}

- (instancetype)init {
  return [self initSerial];
}

- (instancetype)initSerial {
  return [super initWithDispatchObject:dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)];
}

- (instancetype)initConcurrent {
  return [super initWithDispatchObject:dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)];
}

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)dispatchQueue {
  return [super initWithDispatchObject:dispatchQueue];
}

#pragma mark Public block methods.

- (void)asyncBlock:(dispatch_block_t)block {
  dispatch_async(self.dispatchQueue, block);
}

- (void)asyncBlock:(dispatch_block_t)block inGroup:(GCDGroup *)group {
  dispatch_group_async(group.dispatchGroup, self.dispatchQueue, block);
}

- (void)asyncBlock:(dispatch_block_t)block afterDelay:(double)seconds {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (seconds * NSEC_PER_SEC)), self.dispatchQueue, block);
}

- (void)asyncBarrierBlock:(dispatch_block_t)block {
  dispatch_barrier_async(self.dispatchQueue, block);
}

- (void)asyncNotifyBlock:(dispatch_block_t)block inGroup:(GCDGroup *)group {
  dispatch_group_notify(group.dispatchGroup, self.dispatchQueue, block);
}

- (void)syncBlock:(dispatch_block_t)block {
  if ([self isCurrentQueue]) {
    block();
  }
  else {
    dispatch_sync(self.dispatchQueue, block);
  }
}

- (void)syncBlock:(void (^)(size_t))block count:(size_t)count {
  if ([self isCurrentQueue]) {
    for (int i = 0; i < count; ++i) {
      block(i);
    }
  }
  else {
    dispatch_apply(count, self.dispatchQueue, block);
  }
}

- (void)syncBarrierBlock:(dispatch_block_t)block {
  // TODO How to deal with attempted dispatch on the current queue?
  dispatch_barrier_sync(self.dispatchQueue, block);
}

#pragma mark Misc public methods.

- (BOOL)isCurrentQueue {
  return self.dispatchQueue == dispatch_get_current_queue();
}

- (void)suspend {
  dispatch_suspend(self.dispatchQueue);
}

- (void)resume {
  dispatch_resume(self.dispatchQueue);
}

- (dispatch_queue_t)dispatchQueue {
  return self.dispatchObject._dq;
}

@end
