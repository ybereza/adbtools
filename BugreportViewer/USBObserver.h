//
//  USBObserver.h
//  BugreportViewer
//
//  Created by Yury Bereza on 13/06/2018.
//  Copyright © 2018 Yury Bereza. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol USBObservervable
- (void)onDeviceConnected;
- (void)onDeviceDisconnected;
@end

@interface USBObserver : NSObject

@property (strong, nonatomic) id<USBObservervable> observable;

@end
