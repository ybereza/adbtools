//
//  AProcess.h
//  BugreportViewer
//
//  Created by y.bereza on 20.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AProcess : NSObject

@property (weak) AProcess* parent;
@property NSMutableArray* children;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithParent:(AProcess*)p;

@end
