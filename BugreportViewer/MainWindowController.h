//
//  ViewController.h
//  BugreportViewer
//
//  Created by Yury Bereza on 15.06.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ADBDelegate.h"
#import "DeviceListController.h"
#import "ProgressPanel.h"

@class ADBController;

@interface MainWindowController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate, ADBDelegate>
{
@private
    NSArray* mTopLevelItems;
    NSMutableDictionary* mChildrenDictionary;
    ADBController* mADBController;
    IBOutlet NSOutlineView *mOutlineView;
    __weak IBOutlet DeviceListController *mDeviceListController;
}


- (IBAction)createNewWindow:(NSMenuItem *)sender;
- (IBAction)onRefreshButtonClick:(id)sender;

@property (assign) IBOutlet NSToolbarItem* refreshButton;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet ProgressPanel* progressSheet;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

