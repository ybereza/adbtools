//
//  BugreportParser.m
//  BugreportViewer
//
//  Created by y.bereza on 16.07.15.
//  Copyright (c) 2015 Yury Bereza. All rights reserved.
//

#import "BugreportParser.h"

#include "parsing_functions.h"

@interface BugreportParser()

@property NSRegularExpression* bugreportSectionsRegexp;
@property NSRegularExpression* showMapSubsectionRegexp;
@property SEL currentLineParser;
@property NSDictionary<NSString*, NSValue*> * lineParsers;

- (BOOL)walkThroughLines:(SEL)defaultReader;

@end

@implementation BugreportParser

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        NSError* error;
        self.bugreportSectionsRegexp = [NSRegularExpression regularExpressionWithPattern:@"[-]{6}[ ]{1}(.*)[ ]{1}[-]{6}$"
                                                                                 options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil) {
            return nil;
        }
        self.showMapSubsectionRegexp = [NSRegularExpression regularExpressionWithPattern:@"[-]{6}[ ]{1}SHOW MAP.*[ ]{1}[-]{6}"
                                                                                 options:NSRegularExpressionCaseInsensitive error:&error];
        if (error != nil) {
            return nil;
        }
        
        _lineParsers = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSValue valueWithPointer:@selector(uptime:)], @"UPTIME (uptime)",
                        [NSValue valueWithPointer:@selector(memoryInfo:)], @"MEMORY INFO (/proc/meminfo)",
                        [NSValue valueWithPointer:@selector(cpuInfo:)], @"CPU INFO (top -n 1 -d 1 -m 30 -t)", nil];
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

- (BOOL)walkThroughLines:(SEL)defaultReader {
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
            NSString* line = [self.bugreport substringWithRange:lineSubString];
            if (_currentLineParser == nil) {
                _currentLineParser = defaultReader;
            }
            NSNumber* result = [self performSelector:_currentLineParser withObject:line];
            if (![result boolValue]) {
                _currentLineParser = defaultReader;
                NSNumber* result = [self performSelector:_currentLineParser withObject:line];
                if (![result boolValue]) {
                    //NSLog(@"Can not parse string %@", line);
                }
            }
            lineStart = lineEnd;
        }
    }
    if (lineStart != stringLength) {
        NSRange lineSubString = NSMakeRange(lineStart, stringLength - lineStart);
        NSString* line = [self.bugreport substringWithRange:lineSubString];
        NSNumber* result = [self performSelector:_currentLineParser withObject:line];
        if (![result boolValue]) {
            NSLog(@"Can not parse string %@", line);
            return NO;
        }
        
    }
    NSTimeInterval finish = [date timeIntervalSince1970];
    NSLog(@"Finished parsing in %f", finish - start);
    return YES;
}

- (void)parseWithCompletetionHandler:(parsingResultHandler)handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = [self walkThroughLines:@selector(detectGroup:)];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                handler(nil);
            }
            else {
                handler([NSError errorWithDomain:@"com.bugreport" code:1 userInfo:nil]);
            }
        });
    });
}

- (BOOL)detectGroup:(NSString*)line {
    NSArray<NSTextCheckingResult*> * matches = [_bugreportSectionsRegexp matchesInString:line
                                                                                options:0
                                                                                  range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult* match in matches) {
        NSRange sectionRange = [match rangeAtIndex:1];
        NSString* groupName = [line substringWithRange:sectionRange];
        NSLog(@"Group name %@", groupName);
        NSValue * nextReader = [_lineParsers objectForKey:groupName];
        if (nextReader != nil) {
            _currentLineParser = [nextReader pointerValue];
            return YES;
        }
    }
    return NO;
}

- (BOOL)uptime:(NSString*)line {
    NSLog(@"Found UPTIME section");
    return NO;
}

- (BOOL)memoryInfo:(NSString*)line {
    NSLog(@"Found memory info section");
    return NO;
}


- (BOOL)cpuInfo:(NSString*)line {
    NSLog(@"Found cpu info section");
    return NO;
}

@end
