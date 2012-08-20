#import <Foundation/Foundation.h>
#import "ISO8601DateFormatter.h"
#import "ARCMacros.h"

int main(int argc, const char **argv) {
	SAFE_ARC_AUTORELEASE_POOL_START()

	BOOL parseStrictly = NO;
	if((argc > 1) && (strcmp(argv[1], "--strict") == 0)) {
		--argc;++argv;
		parseStrictly = YES;
	}

	[NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:+0]];

	ISO8601DateFormatter *formatter = SAFE_ARC_AUTORELEASE([[ISO8601DateFormatter alloc] init]);
	formatter.parsesStrictly = parseStrictly;

	while(--argc) {
		NSString *str = [NSString stringWithUTF8String:*++argv];
		NSLog(@"Parsing strictly: %hhi", parseStrictly);
		NSDate *date = [formatter dateFromString:str];
		fputs([[NSString stringWithFormat:@"%@ %C %@\n", str, 0x2192, date] UTF8String], stdout);
	}

	SAFE_ARC_AUTORELEASE_POOL_END()
	return 0;
}
