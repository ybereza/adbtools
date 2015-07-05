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

#define kDefaultPort 5037

@implementation ADBController

- (instancetype)initWithPathToSDK:(NSString *)path andDelegate:(id<ADBDelegate>) delegate {
    self = [super init];
    if (self != nil) {
        self.adbPath = path;
        self.delegate = delegate;
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
    int res = inet_pton(AF_INET, "localhost", &sa.sin_addr);
    if (res <= 0) {
        [self.delegate onADBError:ADBErrorUnknownHost];
        return NO;
    }
    if (connect(self->mAdbSocket, (struct sockaddr *)&sa, sizeof sa) == -1) {
        close(self->mAdbSocket);
    }
    return YES;
}

- (void)launchADBServer {
    NSArray* pathParts = [NSArray arrayWithObjects:self.adbPath, @"platform-tools", "adb", nil];
    NSString* path = [NSString pathWithComponents:pathParts];
    
    
}

@end
