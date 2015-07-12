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

static const int kDefaultPort = 5038;
static const int kADB_SERVER_VERSION = 32;

@interface ADBController()

@property NSTask* mADBServerTask;

//error code will be ADBError from ADBDelegate.h
- (nullable NSString*)executeCommand:(NSString *)command failedWithError:(NSError**)error;
- (BOOL)connect;
- (BOOL)_connect;
- (void)close;
- (void)terminateAdb;
- (BOOL)checkADBVersion:(int)adbServerVersion;
- (BOOL)launchADBServer;

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

- (void)getDevicesListAsync {
    [self executeCommand:@"host:devices" Async: ^(NSString* result, NSError* error){
        if (error != nil) {
            [self.delegate onADBError:error];
        }
        else {
            NSArray* devicesAndTypes = [result componentsSeparatedByString:@"\n"];
            NSMutableArray* devices = [NSMutableArray arrayWithCapacity:[devicesAndTypes count]];
            for (NSString* device in devicesAndTypes) {
                if ([device length] > 0) {
                    NSArray* deviceComponents = [device componentsSeparatedByString:@"\t"];
                    [devices addObject:[deviceComponents objectAtIndex:0]];
                }
            }
            [self.delegate onDeviceListReceived:devices];
        }
    }];
}

- (void)executeCommand:(NSString *)command Async:(asyncCommandResult)result {
    dispatch_async(self->mQueue, ^{
        NSError* error = nil;
        NSString* data = nil;
        if (![self checkADBVersion:kADB_SERVER_VERSION]) {
            error = [NSError errorWithDomain:@"Incorrect ADB server version"
                                         code:ADBErrorCannotConnect userInfo:nil];
        }
        if (error == nil) {
            data = [self executeCommand:command failedWithError:&error];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            result(data, error);
        });
    });
}

- (char*)readBytes:(NSUInteger)expected {
    char* buffer = malloc(expected+1);
    memset(buffer, 0, expected+1);
    char* buffer_ptr = buffer;
    NSUInteger readed = 0;
    do {
        expected -= readed;
        buffer_ptr += readed;
        readed = read(self->mAdbSocket, buffer_ptr, expected);
    } while (readed > 0 && readed < expected);
    
    if (readed == -1) {
        free(buffer);
        return NULL;
    }
    return buffer;
}

- (NSString*)readString:(NSUInteger)expected faildWithError:(NSError**)error {
    char* data = [self readBytes:expected];
    if (data != NULL) {
        NSString* res = [NSString stringWithUTF8String:data];
        free(data);
        return res;
    }
    *error = [NSError errorWithDomain:@"Can not read data from device"
                                 code:ADBErrorReadingData userInfo:nil];
    return nil;
}

- (BOOL)writeBytes:(const char*)data :(NSUInteger)size {
    NSUInteger sent = 0;
    do {
        size -= sent;
        data += sent;
        sent = send(self->mAdbSocket, data, size, 0);
    } while (sent > 0 && sent < size);
    if (sent <= 0) {
        return NO;
    }
    return YES;
}

- (void)sendCommand:(NSString*)command failedWithError:(NSError**)error {
    NSString* commandLength = [NSString stringWithFormat:@"%04lx", [command length]];
    if ([self writeBytes:[commandLength UTF8String] :[commandLength length]]
        && [self writeBytes:[command UTF8String] :[command length]]) {

        NSString* okay = [self readString:4 faildWithError:error];
        if (okay != nil && *error == nil) {
            if ([okay compare:@"OKAY"] != NSOrderedSame) {
                *error = [NSError errorWithDomain:@"Can not send data to device"
                                             code:ADBErrorSendingData userInfo:nil];
            }
        }
    }
    else {
        *error = [NSError errorWithDomain:@"Can not send data to device"
                                     code:ADBErrorSendingData userInfo:nil];
    }
}

- (nullable NSString*)executeCommand:(NSString *)command failedWithError:(NSError**)error {
    if (![self connect]) {
        *error = [NSError errorWithDomain:@"Can not connect to adb"
                                     code:ADBErrorSocketNotCreated userInfo:nil];
        return nil;
    }
    
    [self sendCommand:command failedWithError:error];
    if (*error != nil) {
        [self close];
        return nil;
    }
    
    char* responseSize = [self readBytes:4];
    if (responseSize == NULL) {
        *error = [NSError errorWithDomain:@"Can not read response size from device"
                                     code:ADBErrorReadingData userInfo:nil];
        [self close];
        return nil;
    }
    char* p;
    unsigned long expectedBytes = strtoul(responseSize, &p, 16);
    free(responseSize);
    
    NSString* response = nil;
    if (expectedBytes > 0) {
        response = [self readString:expectedBytes faildWithError:error];
    }
    [self close];
    return response;
}

- (BOOL)connect {
    if (![self _connect]) {
        if ([self launchADBServer]) {
            return [self _connect];
        }
        else {
            return NO;
        }
    }
    return YES;
}

- (BOOL)_connect {
    struct sockaddr_in sa;
    self->mAdbSocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (self->mAdbSocket == -1) {
        NSLog(@"System error. Can not create adb socket");
        return NO;
    }
    memset(&sa, 0, sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_port = htons(kDefaultPort);
    inet_pton(AF_INET, "localhost", &sa.sin_addr);
    if (connect(self->mAdbSocket, (struct sockaddr *)&sa, sizeof sa) == -1) {
        NSLog(@"Can not open connection to adb server");
        [self close];
        return NO;
    }
    return YES;
}

- (void)close {
    if (self->mAdbSocket > 0) {
        NSLog(@"Closing adb connection socket");
        close(self->mAdbSocket);
        self->mAdbSocket = 0;
    }
}

- (void)terminateAdb {
    if (self.mADBServerTask != nil) {
        NSLog(@"Terminating adb server task");
        [self.mADBServerTask terminate];
    }
}

- (BOOL)checkADBVersion:(int)adbServerVersion {
    NSError* error = nil;
    NSString* data = [self executeCommand:@"host:version" failedWithError:&error];
    if (error != nil) {
        NSLog(@"Error geting adb version %@", error);
        return false;
    }
    const char* value = [data UTF8String];
    char* p;
    unsigned long version = strtoul(value, &p, 16);
    return version == adbServerVersion;
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
        NSError* error = [NSError errorWithDomain:@"ADBTask terminated"
                                     code:ADBErrorServerStopped userInfo:nil];
        
        [tmp.delegate onADBError:error];
    }];
    
    @try {
        [self.mADBServerTask launch];
        [NSThread sleepForTimeInterval:1.0f];
    }
    @catch (NSException *exception) {
        NSLog(@"error launching ADB server");
        NSError* error = [NSError errorWithDomain:@"adb not found"
                                             code:ADBErrorNotFound userInfo:nil];
        [self.delegate onADBError:error];
        return NO;
    }
    return YES;
}

@end
