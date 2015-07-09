//
//  ADBController.m
//  BugreportViewer
//
//  Created by Yury Bereza on 05.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "ADBController.h"

#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#define kDefaultPort 5038

@interface ADBController()
@property NSTask* mADBServerTask;
@end

@implementation ADBController

- (instancetype)initWithPathToSDK:(NSString *)path andDelegate:(id<ADBDelegate>) delegate {
    self = [super init];
    if (self != nil) {
        self.adbPath = path;
        self.delegate = delegate;
        self->mAdbSocket = 0;
        self->mQueue = dispatch_queue_create("bugreportviewer.adbqueue", NULL);
    }
    return self;
}

- (BOOL)connect {
    struct sockaddr_in sa;
    self->mAdbSocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (self->mAdbSocket == -1) {
        [self.delegate onADBError:ADBErrorSocketNotCreated];
        return NO;
    }
    memset(&sa, 0, sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_port = htons(kDefaultPort);
    inet_pton(AF_INET, "localhost", &sa.sin_addr);
    if (connect(self->mAdbSocket, (struct sockaddr *)&sa, sizeof sa) == -1) {
        close(self->mAdbSocket);
        [self.delegate onADBError:ADBErrorCannotConnect];
        return NO;
    }
    return YES;
}

- (void)close {
    if (self->mAdbSocket > 0) {
        NSLog(@"Closing adb connection socket");
        close(self->mAdbSocket);
    }
    if (self.mADBServerTask != nil) {
        NSLog(@"Terminating adb server task");
        [self.mADBServerTask terminate];
    }
}

- (BOOL)launchADBServer {
    NSArray* pathParts = [NSArray arrayWithObjects:self.adbPath, @"platform-tools", @"adb", nil];
    NSString* path = [NSString pathWithComponents:pathParts];
    NSString* port = [NSString stringWithFormat:@"%d", kDefaultPort];
    
    NSLog(@"try to launch adb from path %@", path);
    
    self.mADBServerTask = [[NSTask alloc] init];
    [self.mADBServerTask setLaunchPath:path];
    [self.mADBServerTask setArguments:[NSArray arrayWithObjects:@"-P", port, @"fork-server", @"server", nil]];
    
    ADBController* __weak tmp = self;
    [self.mADBServerTask setTerminationHandler:^(NSTask* task) {
        NSLog(@"ADBTask termination handler invoked %@", task);
        [tmp.delegate onADBError:ADBErrorServerStopped];
    }];
    
    @try {
        [self.mADBServerTask launch];
        [NSThread sleepForTimeInterval:1.0f];
    }
    @catch (NSException *exception) {
        NSLog(@"error launching ADB server");
        [self.delegate onADBError:ADBErrorNotFound];
        return NO;
    }
    return YES;
}

@end
