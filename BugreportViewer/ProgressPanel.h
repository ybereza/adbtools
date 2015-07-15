//
//  ProgressPanel.h
//  BugreportViewer
//
//  Created by y.bereza on 15.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProgressPanel : NSPanel
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *primaryText;
@property (weak) IBOutlet NSTextField *secondaryText;

@end
