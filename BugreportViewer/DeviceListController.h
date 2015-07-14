//
//  DeviceListController.h
//  BugreportViewer
//
//  Created by y.bereza on 14.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DeviceChangedDelegate <NSObject>
- (void)deviceDidiChanged:(nonnull NSString*)deviceId;
@end

@interface DeviceListController : NSViewController <NSComboBoxDataSource, NSComboBoxDelegate>

@property (nullable, weak) IBOutlet NSComboBox *deviceListBox;
@property (nullable, assign) id<DeviceChangedDelegate> deviceChangedDelegate;

- (void)updateDeviceList:(nonnull NSArray*)deviceList;

@end
