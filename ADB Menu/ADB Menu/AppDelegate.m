//
//  AppDelegate.m
//  ADB Menu
//
//  Created by y.bereza on 14/06/2018.
//  Copyright © 2018 ybereza. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSMenu *mainMenu;
@property (strong) NSStatusItem* statusItem;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [self createStatusBarItem];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSStatusItem*)createStatusBarItem {
    NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.highlightMode = YES;
    statusItem.title = @"ADB";
    statusItem.menu = self.mainMenu;
    
    return statusItem;
}

- (IBAction)quit:(NSMenuItem *)sender {
    [[NSApplication sharedApplication] terminate:self];
}

@end
