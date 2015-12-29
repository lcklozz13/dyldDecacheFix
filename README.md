#dyldDecacheFix
Was using the dsc_extractor inside dyld source code,results in a extra segment LC_SEGMENT_SPLIT_INFO with wrong info,rendered the Mach-O useless.

This is a simple fix by replacing LC_SEGMENT_SPLIT_INFO to LC_SOURCE_VERSION. Static analyzing seems OK,didn't compare in other methods

Issues:
Serval Important Segments,For example:
>>__DATA/__objc_imageinfo

was moved to __DATA_const and __DATA_dirty,so class-dump can't recognize them
FIX:
Directly copy DATA in __DATA_const and __DATA_dirty(not including the segment header itself)right after the last sect in __DATA,alter __DATA's:
>command size

>VM Size

>file Size

>Number of sections

Then put two new LC_SEGMENT right after the new __DATA to fill the space.(Not Finished)

>>New __DATA generate still has error,
