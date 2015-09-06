//
//  ISO8601ForCocoaTimeOnlyTests.h
//  ISO8601ForCocoa
//
//  Created by Peter Hosey on 2013-09-17.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ISO8601ForCocoaTimeOnlyTests : XCTestCase

- (void) testParsingStringWithOnlyHourMinuteSecondZulu;
- (void) testParsingStringWithOnlyHourMinuteZulu;
- (void) testParsingStringWithOnlyHourMinuteSecondAndTimeZone;
- (void) testParsingStringWithOnlyHourMinuteAndTimeZone;

@end
