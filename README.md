#dyldDecacheFix
Was using the dsc_extractor inside dyld source code,results in a extra segment LC_SEGMENT_SPLIT_INFO with wrong info,rendered the Mach-O useless.

This is a simple fix by replacing LC_SEGMENT_SPLIT_INFO to LC_SOURCE_VERSION. Static analyzing seems OK,didn't compare in other methods
