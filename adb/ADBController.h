//
//  ADBController.h
//  BugreportViewer
//
//  Created by Yury Bereza on 05.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADBDelegate.h"

@interface ADBController : NSObject
{
@private
    int mAdbSocket;
    dispatch_queue_t mQueue;
}

@property NSString* adbPath;
@property id<ADBDelegate> delegate;

- (instancetype)initWithPathToSDK:(NSString *)path andDelegate:(id<ADBDelegate>) delegate;

- (BOOL)launchADBServer;
- (BOOL)connect;
- (void)close;

@end
