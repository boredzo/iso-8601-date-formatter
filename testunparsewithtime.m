#import <Foundation/Foundation.h>
#import "ISO8601DateFormatter.h"
#import "ARCMacros.h"

static void testFormatStrings(int hour, int minute);

int main(void) {
	SAFE_ARC_AUTORELEASE_POOL_START()
	ISO8601DateFormatter *formatter = SAFE_ARC_AUTORELEASE([[ISO8601DateFormatter alloc] init]);
	formatter.includeTime = YES;
	NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:336614400.0];
	NSLog(@"2011-09-01 at 5 PM ET: %@", [formatter stringFromDate:date]);

	testFormatStrings(11, 6);
	testFormatStrings(2, 6);
	testFormatStrings(-2, 6);

	SAFE_ARC_AUTORELEASE_POOL_END()
	return EXIT_SUCCESS;
}

static void testFormatStrings(int hour, int minute) {
	NSArray *formatStrings = [NSArray arrayWithObjects:
		@"%@: %02d:%02d",
		@"%@: %+02d:%02d",
		@"%@: %0+2d:%02d",
		@"%@: %02+d:%02d",
		@"%@: %+.2d:%02d",
		nil];
	NSLog(@"Testing with NSLog:");
	for (NSString *format in formatStrings) {
		NSLog(format, format, hour, minute);
	}
	printf("Testing with printf:\n");
	for (NSString *format in formatStrings) {
		NSString *cFormat = [format stringByReplacingOccurrencesOfString:@"%@" withString:@"%s"];
		printf([[cFormat stringByAppendingString:@"\n"] UTF8String], [cFormat UTF8String], hour, minute);
	}
}
