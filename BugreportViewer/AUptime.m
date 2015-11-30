//
//  AUptime.m
//  BugreportViewer
//
//  Created by Yury Bereza on 30.11.15.
//  Copyright © 2015 Yury Bereza. All rights reserved.
//

#import "AUptime.h"

@interface AUptime()
@property NSRegularExpression* parsingExpression;
@end

@implementation AUptime

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        NSError* error;
        _parsingExpression = [NSRegularExpression regularExpressionWithPattern:@"up time:[ ]+([^,]+)[, ]+idle time:[ ]+([^,]+)[, ]+sleep time:[ ]+(.*)"
                                                                       options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil) {
            self = nil;
            NSLog(@"Error init AUptime regular expression %@", error);
        }
    }
    return self;
}

- (NSRegularExpression*)getParsingExpression {
    return _parsingExpression;
}

@end
