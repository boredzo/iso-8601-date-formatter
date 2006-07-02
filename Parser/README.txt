HOW TO USE IN YOUR PROGRAM

Add the source files to your project. When you want to parse a string that you believe is in ISO 8601 date format, call [NSCalendarDate calendarDateWithString:myString]. The method will return either an NSCalendarDate or nil.

HOW TO TEST THAT THIS CODE WORKS

Type 'make test'. make will build the test program (testprog), then invoke test.sh.py to generate test.sh. Then make will invoke test.sh, which will invoke the test program with various dates.

Alternatively, type 'make testprog', then invoke testprog yourself with any date you want to. If it doesn't give you the result you expected, contact me, making sure to provide me with both the input and the output.

NOTES

This version is 0.1.

Whitespace before a date, and anything after a date, is ignored. Thus, "    T23 and all's well" is a valid date for the purpose of this method. (Yes, T23 is a valid ISO 8601 date. It means 23:00:00, or 11 PM.)

All of the frills of ISO 8601 are supported, except for extended dates (years longer than 4 digits). Specifically, you can use week-based dates (2006-W2 for the second week of 2006), ordinal dates (2006-365 for December 31), decimal minutes (11:30.5 == 11:30:30), and decimal seconds (11:30:10.5). All methods of specifying a time zone are supported.

ISO 8601 leaves quite a bit up to the parties exchanging dates. I hope I've chosen reasonable defaults. For example (note that I'm writing this on 2006-02-24):

• If the month or month and date are missing, 1 is assumed. "2006" == "2006-01-01".
• If the year or year and month are missing, the current ones are assumed. "--02-01" == "2006-02-01". "---28" == "2006-02-28".
• In the case of week-based dates, with  the day missing, this implementation returns the first day of that week: 2006-W1 is 2006-01-01, 2006-W2 is 2006-01-08, etc.
• For any date without a time, midnight on that date is used.
• ISO 8601 permits the choice of either T0 or T24 for midnight. This implementation uses T0. T24 will get you T0 on the following day.
• If no time-zone is specified, local time (as returned by [NSTimeZone localTimeZone]) is used.

When a date is parsed that has a year but no century, this implementation adds the current century.

The implementation is tolerant of out-of-range numbers. For example, "2005-13-40T24:62:89" == 1:02 AM on 2006-02-10. Notice that the month (13 > 12), date (40 > 31), hour (24 > 23), minute (62 > 59), and second (89 > 59) are all out-of-range.

There is a "strict" mode that enforces sanity checks. In particular, the date must be the entire contents of the string, and numbers are range-checked. If you have any suggestions on how to make this mode more strict, contact me.

BUGS

• This method won't extract a date from just anywhere in a string, only immediately after the start of the string (or any leading whitespace). There are two solutions: either require that -calendarDateValue be invoked on a string that is only an ISO 8601 date, with nothing before or after (bad for parsing purposes), or find an ISO 8601 date as a substring. I won't do the first one, and barring a patch, I probably won't do the second one either.

• Date ranges (also specified by ISO 8601) are not supported; this method will only return one date. To handle ranges would require at least one more method.

• There is no method to analyze a date string and tell you what was found in it (year, month, week, day, ordinal day, etc.). Feel free to submit a patch.

COPYRIGHT

This code is copyright 2006 Peter Hosey. It is under the BSD license; see LICENSE.txt for the full text of the license.
