//
//  AProcess.m
//  BugreportViewer
//
//  Created by y.bereza on 20.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "AProcess.h"

@implementation AProcess

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self.parent = nil;
    }
    return self;
}

- (instancetype)initWithParent:(AProcess*)p {
    if ([self init]) {
        self.parent = p;
    }
    return self;
}

@end
