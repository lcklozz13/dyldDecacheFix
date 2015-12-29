//
//  MachOHelper.m
//  dyldDecacheFix
//
//  Created by Zhang Naville on 29/12/2015.
//  Copyright © 2015 NavilleZhang. All rights reserved.
//

#import "MachOHelper.h"
@import  MachO;
uint32_t minVMADD=UINT32_MAX;
uint32_t totalSize=0;
uint32_t minOffset=UINT32_MAX;
@implementation MachOHelper
+(void)RemoveSEGMENTSPLITINFO:(NSString*)InputPath{
    
    NSData* InputData=[NSData dataWithContentsOfFile:InputPath];
    struct fat_header* fatheader=(struct fat_header*)InputData.bytes;
    NSData* archData;
    if(fatheader->magic!=FAT_CIGAM&&fatheader->magic!=FAT_MAGIC){
        
        NSLog(@"Not A Fat Mach-O");
        NSLog(@"Not A Fat Mach-O");
        archData=[InputData copy];
    }
    else{
        struct fat_arch* fatArch=(struct fat_arch*)[InputData subdataWithRange:NSMakeRange(0+sizeof(struct fat_header), InputData.length-sizeof(struct fat_header))].bytes;
        int ArchSize=CFSwapInt32(fatArch->size);
        int ArchOffSet=CFSwapInt32(fatArch->offset);
        archData=[InputData subdataWithRange:NSMakeRange(ArchOffSet, ArchSize)];
        
        
    }
    //int narchs=CFSwapInt32(fatheader->nfat_arch);
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
            //Change LC_SEGMENT_SPLIT_INFO to LC_SOURCE_VERSION.(For now),Mach-O allows more than one LC_SOURCE_VERSION
            NSLog(@"Replaced LC_SEGMENT_SPLIT_INFO to LC_SOURCE_VERSION");
            [wholeArchData writeToFile:InputPath atomically:YES];
            [[NSFileManager defaultManager] removeItemAtPath:[InputPath stringByAppendingString:@"SingleArch"] error:nil];
            return ;
            
            
            
        }
        
        
        NSLog(@"Iterating LC_Command Type:0x%x Size:0x%x",currentcmd,currentSize);
        long newOffset=nsfh.offsetInFile+currentSize-sizeof(struct load_command);
        NSLog(@"Going to Offset:0x%lx",newOffset);
        [nsfh seekToFileOffset:newOffset];
        
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:[InputPath stringByAppendingString:@"SingleArch"] error:nil];
    
    NSLog(@"LC_SEGMENT_SPLIT_INFO NOT FOUND");
    
    
    
}
+(void)FixDataSegments:(NSString*)InputPath{
    long long offsetForData = 0;
    
    NSData* InputData=[NSData dataWithContentsOfFile:InputPath];
    struct fat_header* fatheader=(struct fat_header*)InputData.bytes;
    NSData* archData;
    if(fatheader->magic!=FAT_CIGAM&&fatheader->magic!=FAT_MAGIC){
        
        NSLog(@"Not A Fat Mach-O");
        NSLog(@"Not A Fat Mach-O");
        archData=[InputData copy];
    }
    else{
        struct fat_arch* fatArch=(struct fat_arch*)[InputData subdataWithRange:NSMakeRange(0+sizeof(struct fat_header), InputData.length-sizeof(struct fat_header))].bytes;
        int ArchSize=CFSwapInt32(fatArch->size);
        int ArchOffSet=CFSwapInt32(fatArch->offset);
        archData=[InputData subdataWithRange:NSMakeRange(ArchOffSet, ArchSize)];
        
        
    }
    //int narchs=CFSwapInt32(fatheader->nfat_arch);
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
    NSMutableDictionary *SectionCommandList=[NSMutableDictionary dictionary];
    for(int i=0;i<numberOfLC;i++){
        unsigned long StartOffset=nsfh.offsetInFile;
        NSData* LCData=[nsfh readDataOfLength:sizeof(struct load_command)];
        struct load_command* currentLoadCommand=(struct load_command*)[LCData bytes];
        int currentcmd=currentLoadCommand->cmd;
        int currentSize=currentLoadCommand->cmdsize;
        if(currentcmd==LC_SEGMENT||currentcmd==LC_SEGMENT_64){
            [nsfh seekToFileOffset:StartOffset];
            NSData* LSData=[nsfh readDataOfLength:sizeof(struct segment_command)];
            struct segment_command* currentSegmentCommand=(struct segment_command*)[LSData bytes];
            NSString* segName=[NSString stringWithUTF8String:currentSegmentCommand->segname];
            NSLog(@"Offset:0x%lx SegName:%@",StartOffset,segName);
            if([segName isEqualToString:@"__DATA"]){
                offsetForData=StartOffset;
                
            }
            if([segName containsString:@"__DATA"]){
            
                uint32_t numberOfSecs=currentSegmentCommand->nsects;
                NSLog(@"Found Segment:%@ With %u Sections",segName,numberOfSecs);
                [nsfh seekToFileOffset:StartOffset+sizeof(struct segment_command)];
                NSData* SegmentHeader=[nsfh readDataOfLength:numberOfSecs*sizeof(struct section)];
                //NSLog(@"%@",SegmentHeader);
                [SectionCommandList addEntriesFromDictionary:[self SortSectionCommandList:SegmentHeader WithSections:numberOfSecs]];
                
                
            
            
            }
        
        
        
        
        }
        
        
        long newOffset=StartOffset+currentSize;
        NSLog(@"Going to Offset:0x%lx",newOffset);
        [nsfh seekToFileOffset:newOffset];

        
        
        
    }
    if(offsetForData==0){
        NSLog(@"__DATA Section Not Found");
        exit(-1);
        
    }
    
    NSData* SecHeader=[self dataFromSecComList:SectionCommandList];
    NSMutableData* ResultData=[NSMutableData dataWithContentsOfFile:InputPath];
    struct segment_command* dataSeg=(struct segment_command*)[[ResultData subdataWithRange:NSMakeRange(offsetForData, sizeof(struct segment_command))] bytes];
    NSLog(@"Total __DATA SIZE:0x%x",totalSize);
    dataSeg->nsects=(unsigned int)[SectionCommandList.allKeys count];
    dataSeg->vmaddr=minVMADD;
    dataSeg->vmsize=totalSize;
    dataSeg->filesize=totalSize;
    dataSeg->fileoff=minOffset;
    dataSeg->cmdsize=sizeof(struct segment_command)+totalSize;
    [ResultData replaceBytesInRange:NSMakeRange(offsetForData, sizeof(struct segment_command)) withBytes:dataSeg];
    
    [ResultData replaceBytesInRange:NSMakeRange(offsetForData, ResultData.length) withBytes:SecHeader.bytes];
    [ResultData writeToFile:@"/Users/Naville/Desktop/Test" atomically:YES];
    
}
+(NSMutableDictionary*)SortSectionCommandList:(NSData*)commandData WithSections:(long long)numberOfSecs{
    NSMutableDictionary* retDict=[NSMutableDictionary dictionary];
    for(int i=0;i<numberOfSecs;i++){
        struct section* currentSC=(struct section*)[[commandData subdataWithRange:NSMakeRange(i*sizeof(struct section), sizeof(struct section))] bytes];
                                                                                    
        [retDict setObject:[commandData subdataWithRange:NSMakeRange(i*sizeof(struct section), sizeof(struct section))] forKey:[NSString stringWithFormat:@"%u",currentSC->addr]];
        
        
    }
    
    
    
    return retDict;
}
+(NSData*)dataFromSecComList:(NSMutableDictionary*)Dict{
    NSMutableData* retData=[NSMutableData data];
    NSMutableArray* KeyList=[Dict.allKeys mutableCopy];
    [KeyList sortUsingComparator:^NSComparisonResult(NSString* obj1,NSString* obj2) {
        if(obj1.intValue<obj2.intValue){
            return NSOrderedAscending;
        }
        else if(obj1.intValue>obj2.intValue){
            return NSOrderedDescending;
        }
        else{
            return NSOrderedSame;
        }
   
    }];
    for(int i=0;i<KeyList.count;i++){
        NSString* Key=[KeyList objectAtIndex:i];
        struct section* curSec=(struct section*)[[Dict objectForKey:Key] bytes];
        totalSize=totalSize+curSec->size;
        if(curSec->addr<minVMADD){
            minVMADD=curSec->addr;
        }
        if(curSec->offset<minOffset&&curSec->offset>0){
            minOffset=curSec->offset;
            NSLog(@"Minimum offset:%i",minOffset);
        }
        
        [retData appendData:[Dict objectForKey:Key]];
        
        
    }
    
    
    
    
    return retData;
}
@end
