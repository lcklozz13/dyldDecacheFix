//
//  main.m
//  dyldDecacheFix
//
//  Created by Zhang Naville on 28/12/2015.
//  Copyright © 2015 NavilleZhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach-o/loader.h>
@import MachO;
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString* InputPath=[NSString stringWithUTF8String:argv[1]];
        NSData* InputData=[NSData dataWithContentsOfFile:InputPath];
        struct fat_header* fatheader=(struct fat_header*)InputData.bytes;
        //int narchs=CFSwapInt32(fatheader->nfat_arch);
        struct fat_arch* fatArch=(struct fat_arch*)[InputData subdataWithRange:NSMakeRange(0+sizeof(struct fat_header), InputData.length-sizeof(struct fat_header))].bytes;
        int ArchSize=CFSwapInt32(fatArch->size);
        int ArchOffSet=CFSwapInt32(fatArch->offset);
        NSData* archData=[InputData subdataWithRange:NSMakeRange(ArchOffSet, ArchSize)];
        struct mach_header* sliceHeader=(struct mach_header*)archData.bytes;
        [archData writeToFile:[InputPath stringByAppendingString:@"SingleArch"] atomically:YES];
        NSFileHandle* nsfh=[NSFileHandle fileHandleForUpdatingAtPath:[InputPath stringByAppendingString:@"SingleArch"]];
        [nsfh seekToFileOffset:0];
        int numberOfLC=sliceHeader->ncmds;
        if(sliceHeader->magic==MH_MAGIC){
        [nsfh seekToFileOffset:sizeof(struct mach_header)];
            
        }
        else if(sliceHeader->magic==MH_MAGIC_64){
            
            [nsfh seekToFileOffset:sizeof(struct mach_header_64)];
        }
        else{
            NSLog(@"Wrong Mach-O Magic");
            exit(-1);
            
        }
          NSLog(@"Starting At Offset:0x%llx",nsfh.offsetInFile);
        for(int i=0;i<=numberOfLC;i++){
        
            NSData* LCData=[nsfh readDataOfLength:sizeof(struct load_command)];
            struct load_command* currentLoadCommand=(struct load_command*)[LCData bytes];
            int currentcmd=currentLoadCommand->cmd;
            int currentSize=currentLoadCommand->cmdsize;
            if(currentcmd==LC_SEGMENT_SPLIT_INFO){
                unsigned long long  currentOffSet=nsfh.offsetInFile-sizeof(struct load_command);
                
                NSLog(@"Found LC_SEGMENT_SPLIT_INFO at Offset:%llu",currentOffSet);
                [nsfh seekToFileOffset:0];
                NSMutableData* wholeArchData=[[nsfh readDataToEndOfFile] mutableCopy];
                
                [wholeArchData replaceBytesInRange:NSMakeRange(currentOffSet, sizeof(currentLoadCommand->cmd)) withBytes:"\x2A\x00\x00\x00"];
                //Change LC_SEGMENT_SPLIT_INFO to LC_SOURCE_VERSION.(For now),Mach-O allows more than one LC_SEGMENT_SPLIT_INFO
                [wholeArchData writeToFile:InputPath atomically:YES];
                [[NSFileManager defaultManager] removeItemAtPath:[InputPath stringByAppendingString:@"SingleArch"] error:nil];
                exit(0);
                
                
                
            }
            
            
            NSLog(@"Iterating LC_Command Type:0x%x Size:0x%x",currentcmd,currentSize);
            long newOffset=nsfh.offsetInFile+currentSize-sizeof(struct load_command);
            NSLog(@"Going to Offset:0x%lx",newOffset);
            [nsfh seekToFileOffset:newOffset];
            
        }
        
        
        
        
        
        
        
    }
    return 0;
}
