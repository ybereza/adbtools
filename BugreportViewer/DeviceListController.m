//
//  DeviceListController.m
//  BugreportViewer
//
//  Created by y.bereza on 14.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "DeviceListController.h"

@interface DeviceListController ()
@property (nullable, atomic) NSArray* connectedDevices;
@end

@implementation DeviceListController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.deviceListBox setUsesDataSource:YES];
}

- (void)updateDeviceList:(nonnull NSArray*)deviceList {
    self.connectedDevices = deviceList;
    [self.deviceListBox reloadData];
    if ([self.connectedDevices count] > 0) {
        [self.deviceListBox selectItemAtIndex:0];
    }
}

#pragma mark -
#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return self.connectedDevices != nil ? [self.connectedDevices count] : 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [self.connectedDevices objectAtIndex:index];
}

#pragma mark -
#pragma mark NSComboBoxDeleagate

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
    if (self.deviceChangedDelegate != nil) {
        NSInteger idx = [self.deviceListBox indexOfSelectedItem];
        [self.deviceChangedDelegate deviceDidiChanged:[self.connectedDevices objectAtIndex:idx]];
    }
}

@end
