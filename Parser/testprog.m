#import <Foundation/Foundation.h>
#import "NSCalendarDate+ISO8601Parsing.h"

int main(int argc, const char **argv) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	BOOL parseStrictly = NO;
	if((argc > 1) && (strcmp(argv[1], "--strict") == 0)) {
		--argc;++argv;
		parseStrictly = YES;
	}

	while(--argc) {
		NSString *str = [NSString stringWithUTF8String:*++argv];
		NSDate *date = [NSCalendarDate calendarDateWithString:str strictly:parseStrictly];
		fputs([[NSString stringWithFormat:@"%@ %C %@\n", str, 0x2192, date] UTF8String], stdout);
	}

	[pool release];
	return 0;
}
