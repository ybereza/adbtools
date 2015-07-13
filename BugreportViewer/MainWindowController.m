//
//  ViewController.m
//  BugreportViewer
//
//  Created by Yury Bereza on 15.06.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "MainWindowController.h"
#import "SidebarTableCellView.h"

#import "ADBController.h"

@implementation MainWindowController

- (void)initADBController {
    
    mADBController = [[ADBController alloc] initWithPathToSDK:@"/Users/y.bereza/android/sdk" andDelegate:self];
    [mADBController getDevicesListAsync];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self->mDeviceList setUsesDataSource:YES];
    [self->mDeviceList setDataSource:self];    
    [self initADBController];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    // The array determines our order
    mTopLevelItems = [NSArray arrayWithObjects:@"Favorites", @"Content Views", @"Mailboxes", @"A Fourth Group", nil];
    
    // The data is stored ina  dictionary. The objects are the nib names to load.
    mChildrenDictionary = [NSMutableDictionary new];
    [mChildrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView1", @"ContentView2", @"ContentView3", nil]
                            forKey:@"Favorites"];
    [mChildrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView1", @"ContentView2", @"ContentView3", nil]
                            forKey:@"Content Views"];
    [mChildrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView2", nil]
                            forKey:@"Mailboxes"];
    [mChildrenDictionary setObject:[NSArray arrayWithObjects:@"ContentView1", @"ContentView1", @"ContentView1", @"ContentView1", @"ContentView2", nil]
                            forKey:@"A Fourth Group"];
    
    // The basic recipe for a sidebar. Note that the selectionHighlightStyle is set to NSTableViewSelectionHighlightStyleSourceList in the nib
    [mOutlineView sizeLastColumnToFit];
    [mOutlineView reloadData];
    [mOutlineView setFloatsGroupRows:NO];
    
    // NSTableViewRowSizeStyleDefault should be used, unless the user has picked an explicit size. In that case, it should be stored out and re-used.
    [mOutlineView setRowSizeStyle:NSTableViewRowSizeStyleDefault];
    
    // Expand all the root items; disable the expansion animation that normally happens
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [mOutlineView expandItem:nil expandChildren:YES];
    [NSAnimationContext endGrouping];
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSArray *)_childrenForItem:(id)item {
    NSArray *children;
    if (item == nil) {
        children = mTopLevelItems;
    } else {
        children = [mChildrenDictionary objectForKey:item];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return [[self _childrenForItem:item] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([outlineView parentForItem:item] == nil) {
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [[self _childrenForItem:item] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [mTopLevelItems containsObject:item];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // For the groups, we just return a regular text view.
    if ([mTopLevelItems containsObject:item]) {
        NSTableCellView *result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        // Uppercase the string value, but don't set anything else. NSOutlineView automatically applies attributes as necessary
        NSString *value = [item uppercaseString];
        [[result textField] setStringValue:value];
        return result;
    } else  {
        // The cell is setup in IB. The textField and imageView outlets are properly setup.
        // Special attributes are automatically applied by NSTableView/NSOutlineView for the source list
        SidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
        result.textField.stringValue = item;
        // Setup the icon based on our section
        id parent = [outlineView parentForItem:item];
        NSInteger index = [mTopLevelItems indexOfObject:parent];
        NSInteger iconOffset = index % 4;
        switch (iconOffset) {
            case 0: {
                result.imageView.image = [NSImage imageNamed:NSImageNameIconViewTemplate];
                break;
            }
            case 1: {
                result.imageView.image = [NSImage imageNamed:NSImageNameHomeTemplate];
                break;
            }
            case 2: {
                result.imageView.image = [NSImage imageNamed:NSImageNameQuickLookTemplate];
                break;
            }
            case 3: {
                result.imageView.image = [NSImage imageNamed:NSImageNameSlideshowTemplate];
                break;
            }
        }
        // Setup the unread indicator to show in some cases. Layout is done in SidebarTableCellView's viewWillDraw
        /*if (index == 0) {
            // First row in the index
            hideUnreadIndicator = NO;
            [result.button setTitle:@"42"];
            [result.button sizeToFit];
            // Make it appear as a normal label and not a button
            [[result.button cell] setHighlightsBy:0];
        } else if (index == 2) {
            // Example for a button
            hideUnreadIndicator = NO;
            result.button.target = self;
            result.button.action = @selector(buttonClicked:);
            [result.button setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
            // Make it appear as a button
            [[result.button cell] setHighlightsBy:NSPushInCellMask|NSChangeBackgroundCellMask];
        }
        [result.button setHidden:hideUnreadIndicator];*/
        return result;
    }
}

- (IBAction)createNewWindow:(NSMenuItem *)sender {
    NSLog(@"Create new window");
}

- (IBAction)onRefreshButtonClick:(id)sender {
    [mADBController getLogcatAsync];
}

#pragma mark -
#pragma mark ADBDelegate

- (void)onDeviceListReceived:(NSArray*) devices {
    self.connectedDevices = devices;
    NSLog(@"onDeviceListReceived %@", devices);
    [self->mDeviceList reloadData];
    if ([self.connectedDevices count] == 1) {
        [self->mDeviceList selectItemAtIndex:0];
    }
}

- (void)onLogcatReceived:(NSString *)logcat {
    [self.textView setString:logcat];
}

- (void)onADBError:(NSError*) error {
    NSLog(@"onADBError %@", error);
}

#pragma mark -
#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return self.connectedDevices != nil ? [self.connectedDevices count] : 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [self.connectedDevices objectAtIndex:index];
}

@end
