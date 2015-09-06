//
//  ISO8601Testing.h
//  ISO8601ForCocoa
//
//  Created by Peter Hosey on 2015-09-06.
//  Copyright © 2015 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <XCTest/XCTest.h>

#define ISO8601AssertEqualRanges(range1, range2, ...) \
do { \
	XCTAssertEqual((range1).location, (range2).location, __VA_ARGS__); \
	XCTAssertEqual((range1).length, (range2).length, __VA_ARGS__); \
} while(0)
