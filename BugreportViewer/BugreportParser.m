//
//  BugreportParser.m
//  BugreportViewer
//
//  Created by y.bereza on 16.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "BugreportParser.h"

typedef void (^lineBlock)(NSString* lineSubstring);

@interface BugreportParser()

@property NSRegularExpression* bugreportSectionsRegexp;
@property NSRegularExpression* showMapSubsectionRegexp;

- (void)walThroughLines:(lineBlock)doOnEachLine;

@end

@implementation BugreportParser

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        NSError* error;
        self.bugreportSectionsRegexp = [NSRegularExpression regularExpressionWithPattern:@"[-]{6}[ ]{1}(.*)[ ]{1}[-]{6}" options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil) {
            return nil;
        }
        self.showMapSubsectionRegexp = [NSRegularExpression regularExpressionWithPattern:@"[-]{6}[ ]{1}SHOW MAP.*[ ]{1}[-]{6}" options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithBugreport:(NSString*)bugreport {
    self = [self init];
    if (self != nil) {
        self.bugreport = bugreport;
    }
    return self;
}

- (void)walThroughLines:(lineBlock)doOnEachLine {
    NSUInteger lineStart = 0;
    NSUInteger lineEnd = 0;
    NSUInteger stringLength = [self.bugreport length];
    unichar newLine = '\n';
    unichar lineBreak = '\r';
    
    for (NSUInteger index = 0; index < stringLength; ++index) {
        if (([self.bugreport characterAtIndex:index] == newLine) ||
            ([self.bugreport characterAtIndex:index] == lineBreak)) {
            if ([self.bugreport characterAtIndex:index+1] == lineBreak) {
                ++index;
            }
            lineEnd = index;
            NSRange lineSubString = NSMakeRange(lineStart, lineEnd);
            doOnEachLine([self.bugreport substringWithRange:lineSubString]);
            lineStart = lineEnd;
        }
    }
    if (lineStart != stringLength) {
        NSRange lineSubString = NSMakeRange(lineStart, stringLength);
        doOnEachLine([self.bugreport substringWithRange:lineSubString]);
    }
}

@end
