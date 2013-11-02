/*
	
*/

#include "config.h"

#ifdef WINDOWS
	#include <windows.h>
#else
  #define Sleep(ms) usleep((ms * 1000))
#endif

#include <sys/time.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "progalgsram.h"



ProgAlgSram::ProgAlgSram(Jtag &j, IOBase &i)
{
    jtag=&j;
    io=&i;

    JPROGRAM=0x0b;
    BYPASS=0x3f;
    USER1=0x02;
    IDCODE=0x09;
}

bool ProgAlgSram::Sram_Write(const byte *data, int length, bool verbose)
{
    byte *tdi;
    int nPages=(length+511)/512;
    int bytes=nPages*512;//bytes in
    int bytes_s=4+bytes+2;//4 bytes pre + 2 bytes post
    int i;

    tdi = (byte*)malloc(sizeof(byte)*bytes_s);
    memset(tdi,0,bytes_s);

    tdi[0]=0x59;
    tdi[1]=0xa6;
    tdi[2]=(nPages)>>8;    // nPages(15:8)
    tdi[3]=(nPages&0xff);  // nPages(7:0)

    for(i=0; i<4; i++)
        tdi[i] = bRevTable[tdi[i]];

    for(i=0; i<bytes; i++)
        tdi[i+4] = bRevTable[data[i]];

    jtag->shiftDR(tdi,0,8*bytes_s);

    free(tdi);

	return true;
}

bool ProgAlgSram::Sram_Verify(const byte *verify_data, int length, bool verbose)
{
    byte *tdi,*tdo;
    int nPages=(length+511)/512;
    int bytes=nPages*512;//bytes in
    int bytes_s=4+bytes+2;//4 bytes pre + 2 bytes post
    int i;

    tdi = (byte*)malloc(sizeof(byte)*bytes_s);
    tdo = (byte*)malloc(sizeof(byte)*bytes_s);
    memset(tdi,0,bytes_s);
    memset(tdo,0,bytes_s);

    tdi[0]=0x59;
    tdi[1]=0xa5;
    tdi[2]=(nPages)>>8;    // nPages(15:8)
    tdi[3]=(nPages&0xff);  // nPages(7:0)

    for(i=0; i<4; i++)
        tdi[i] = bRevTable[tdi[i]];

    jtag->shiftDR(tdi,tdo,8*bytes_s);

    for(i=0; i<length; i++)
        if (verify_data[i] != bRevTable[tdo[i+6]]) {
            fprintf(stderr,"Verify mismatch at address: %08X, expected: %02X, got: %02X\n", i, verify_data[i], bRevTable[tdo[i+6]]);
            break;
        }
    free(tdi);
    free(tdo);

	return true;
}

bool ProgAlgSram::ProgramSram(BinaryFile &file, Sram_Options_t options)
{
    struct timeval tv[2];
    bool verbose=io->getVerbose();
    gettimeofday(tv, NULL);

    // Switch to USER1 register, to access BSCAN..
    jtag->shiftIR(&USER1,0);

    if(options==FULL||options==WRITE_ONLY)
    {
        printf("\nProgramming SRAM\n");
        if(!Sram_Write(file.getData(), file.getLength(), verbose))
            return false;
    }

    if(options==FULL||options==VERIFY_ONLY)
    {
        printf("\nVerifying SRAM\n");
        if(!Sram_Verify(file.getData(), file.getLength(), verbose))
            return false;
    }

    if (verbose)
    {
        gettimeofday(tv+1, NULL);
        printf("\nTotal SRAM execution time %.1f ms\n", (double)deltaT(tv, tv + 1)/1.0e3);
    }

    /* JPROGAM: Trigerr reconfiguration, not explained in ug332, but
     DS099 Figure 28:  Boundary-Scan Configuration Flow Diagram (p.49) */
    if(options==FULL)
    {
        jtag->shiftIR(&JPROGRAM);
        Sleep(1000);//just wait a bit to make sure everything is done..
    }

    jtag->shiftIR(&BYPASS);

  return true;
}
