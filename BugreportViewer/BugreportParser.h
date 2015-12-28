//
//  BugreportParser.h
//  BugreportViewer
//
//  Created by y.bereza on 16.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^parsingResultHandler)(NSError* error);

@interface BugreportParser : NSObject
@property NSString* bugreport;

- (instancetype)init;
- (instancetype)initWithBugreport:(NSString*)bugreport;

- (void)parseWithCompletetionHandler:(parsingResultHandler)handler;

@end
