//
//  ViewController.h
//  BugreportViewer
//
//  Created by Yury Bereza on 15.06.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ADBDelegate.h"

@class ADBController;

@interface MainWindowController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate, ADBDelegate, NSComboBoxDataSource>
{
@private
    NSArray* mTopLevelItems;
    NSMutableDictionary* mChildrenDictionary;
    IBOutlet NSOutlineView *mOutlineView;
    IBOutlet NSComboBox* mDeviceList;
    ADBController* mADBController;
}


- (IBAction)createNewWindow:(NSMenuItem *)sender;
- (IBAction)onRefreshButtonClick:(id)sender;

@property (weak) IBOutlet NSToolbarItem* refreshButton;
@property (assign) IBOutlet NSWindow *window;
@property NSArray* connectedDevices;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

