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

- (void)walkThroughLines:(lineBlock)doOnEachLine;

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

- (void)walkThroughLines:(lineBlock)doOnEachLine {
    NSUInteger lineStart = 0;
    NSUInteger lineEnd = 0;
    NSUInteger stringLength = [self.bugreport length];
    unichar newLine = '\n';
    unichar lineBreak = '\r';
    NSMutableSet* foundLineStart = [[NSMutableSet alloc] init];
    for (NSUInteger index = 0; index < stringLength; ++index) {
        if (([self.bugreport characterAtIndex:index] == newLine) ||
            ([self.bugreport characterAtIndex:index] == lineBreak)) {
            if (index+1 < stringLength &&
                (([self.bugreport characterAtIndex:index+1] == lineBreak) || ([self.bugreport characterAtIndex:index+1] == newLine))) {
                ++index;
            }
            lineEnd = index;
            NSNumber * testLineStart = [NSNumber numberWithUnsignedInteger:lineStart];
            if ([foundLineStart containsObject:testLineStart]) {
                NSLog(@"Error, line position %@ allready exists", testLineStart);
            }
            else {
                [foundLineStart addObject:testLineStart];
            }
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

- (void)parse {
    [self walkThroughLines:^(NSString *lineSubstring) {
        NSArray<NSTextCheckingResult*>* matches = [_bugreportSectionsRegexp matchesInString:lineSubstring
                                                                                    options:0
                                                                                      range:NSMakeRange(0, [lineSubstring length])];
        for (NSTextCheckingResult* match in matches) {
            NSRange sectionRange = [match rangeAtIndex:1];
            NSLog(@"Group name %@", [lineSubstring substringWithRange:sectionRange]);
        }
    }];
}

@end
