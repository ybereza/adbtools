//
//  BugreportParser.m
//  BugreportViewer
//
//  Created by y.bereza on 16.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "BugreportParser.h"

#include "parsing_functions.h"

typedef NS_ENUM(NSInteger, ParsingStage) {
    DEFAULT,
    PARSE_UPTIME
};

typedef void (*parsing_function)();

typedef struct _parsing_state {
    const char*  group_name;
    parsing_function parsing_function_ptr;
    ParsingStage stage;
} parsing_state;

parsing_state parsing_states[] = {
    {"UPTIME (uptime)", parse_uptime, PARSE_UPTIME}
};

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
    
    NSDate *date = [NSDate date];
    NSTimeInterval start = [date timeIntervalSince1970];
    
    for (NSUInteger index = 0; index < stringLength; ++index) {
        if (([self.bugreport characterAtIndex:index] == newLine) ||
            ([self.bugreport characterAtIndex:index] == lineBreak)) {
            if (index+1 < stringLength &&
                (([self.bugreport characterAtIndex:index+1] == lineBreak) || ([self.bugreport characterAtIndex:index+1] == newLine))) {
                ++index;
            }
            lineEnd = index;
            NSRange lineSubString = NSMakeRange(lineStart, lineEnd - lineStart);
            doOnEachLine([self.bugreport substringWithRange:lineSubString]);
            lineStart = lineEnd;
        }
    }
    if (lineStart != stringLength) {
        NSRange lineSubString = NSMakeRange(lineStart, stringLength - lineStart);
        doOnEachLine([self.bugreport substringWithRange:lineSubString]);
    }
    NSTimeInterval finish = [date timeIntervalSince1970];
    NSLog(@"Finished parsing in %f", finish - start);
}

- (void)parse {
    __block NSInteger foundSections = 0;
    [self walkThroughLines:^(NSString *lineSubstring) {
        NSArray<NSTextCheckingResult*>* matches = [_bugreportSectionsRegexp matchesInString:lineSubstring
                                                                                    options:0
                                                                                      range:NSMakeRange(0, [lineSubstring length])];
        for (NSTextCheckingResult* match in matches) {
            NSRange sectionRange = [match rangeAtIndex:1];
            NSLog(@"Group name %@", [lineSubstring substringWithRange:sectionRange]);
            ++foundSections;
        }
    }];
    NSLog(@"Found %ld sections", foundSections);
}

@end
