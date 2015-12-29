//
//  MachOHelper.h
//  dyldDecacheFix
//
//  Created by Zhang Naville on 29/12/2015.
//  Copyright © 2015 NavilleZhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MachOHelper : NSObject
+(void)RemoveSEGMENTSPLITINFO:(NSString*)InputPath;
+(void)FixDataSegments:(NSString*)InputPath;
@end

