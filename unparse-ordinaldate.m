#import "NSCalendarDate+ISO8601Parsing.h"
#import "NSCalendarDate+ISO8601Unparsing.h"

int main(int argc, const char **argv) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	while(--argc) {
		NSString *arg = [NSString stringWithUTF8String:*++argv];
		printf("%s\n", [[NSString stringWithFormat:@"%@:\t%@", arg, [[NSCalendarDate calendarDateWithString:arg] ISO8601OrdinalDateStringWithTime:NO]] UTF8String]);
	}

	[pool release];
	return 0;
}
