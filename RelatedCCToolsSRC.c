  			sg = (struct segment_command *)lc;
  			s = (struct section *)
		    ((char *)sg + sizeof(struct segment_command));

		    if(sg->vmsize != 0 && s->size != 0 && s->addr+s->size >sg->vmaddr+sg->vmsize){
			Mach_O_error(ofile, "malformed object (addr field plus "
				"size of section %u in LC_SEGMENT command %u "
				"greater than than the segment's vmaddr plus "
				"vmsize)", j, i);
			goto return_bad;
		    }
		    //0x36AF16FC+00000068=0x36AF1764 //MAX ADDRESS