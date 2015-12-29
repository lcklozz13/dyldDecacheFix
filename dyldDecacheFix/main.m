//
//  main.m
//  dyldDecacheFix
//
//  Created by Zhang Naville on 28/12/2015.
//  Copyright © 2015 NavilleZhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach-o/loader.h>
#import "MachOHelper.h"
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSString* InputPath=[NSString stringWithUTF8String:argv[1]];
        if([[NSFileManager defaultManager] fileExistsAtPath:InputPath]==NO){
            
            
            NSLog(@"File Doesn't Exist");
            exit(-1);
            
            
        }
        [MachOHelper RemoveSEGMENTSPLITINFO:InputPath];

        [MachOHelper FixDataSegments:InputPath];
        
               
        
        
        
        
    }
    return 0;
}
