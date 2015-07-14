//
//  ADBDelegate.h
//  BugreportViewer
//
//  Created by Yury Bereza on 05.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ADBError) {
    ADBErrorSocketNotCreated,
    ADBErrorCannotConnect,
    ADBErrorUnknownHost,
    ADBErrorNotFound,
    ADBErrorServerStopped,
    ADBErrorSendingData,
    ADBErrorReadingData,
    ADBErrorIncorrectResponse
};

@protocol ADBDelegate <NSObject>

- (void)onDeviceListReceived:(NSArray*)devices;
- (void)onLogcatReceived:(NSString*)logcat;
- (void)onBugreportReceived:(NSString*)bugreport;
//error code will be ADBError
- (void)onADBError:(NSError*)error;

@end
