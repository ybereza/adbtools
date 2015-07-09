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
    ADBErrorServerStopped
};

@protocol ADBDelegate <NSObject>

- (void)onDeviceListReceived:(NSArray*) devices;
- (void)onADBError:(ADBError) error;

@end
