//
//  AUptime.h
//  BugreportViewer
//
//  Contains state of Android Uptime info from bugreport
//
//  Created by Yury Bereza on 30.11.15.
//  Copyright © 2015 Yury Bereza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AUptime : NSObject

@property NSString* uptime;
@property NSString* idle;
@property NSString* sleep;

- (instancetype)init;
- (NSRegularExpression*)getParsingExpression;

@end
