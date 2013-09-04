//
//  NSLocale+UnitTestSwizzling.h
//  ISO8601ForCocoa
//
//  Created by Matthias Bauch on 8/29/13.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLocale (TestSwizzling)

void SwizzleClassMethod(Class c, SEL orig, SEL new);

+ (NSLocale *)mockCurrentLocale;

@end

