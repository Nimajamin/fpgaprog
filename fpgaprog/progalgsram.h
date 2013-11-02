/*
	SRAM programming through TAP, Benjamin Leperchey, based on
	"	AT45DB SPI JTAG programming algorithms
		Copyright (C) 2010 Jochem Govers"

*/



#ifndef PROGALGSRAM_H
#define PROGALGSRAM_H

#include "binaryfile.h"
#include "jtag.h"
#include "iobase.h"
#include "tools.h"

class ProgAlgSram
{
    private:
        byte JPROGRAM;
        byte BYPASS;
        byte USER1;
        byte IDCODE;

        Jtag *jtag;
        IOBase *io;

        bool Sram_SetPage(int page, bool verbose=false);
        bool Sram_Write(const byte *write_data, int length, bool verbose=false);
        bool Sram_Verify(const byte *verify_data, int length, bool verbose);
    public:
        enum Sram_Options_t
        {
            VERIFY_ONLY,
            WRITE_ONLY,
            FULL
        };
        ProgAlgSram(Jtag &j, IOBase &i);
        bool ProgramSram(BinaryFile &file, Sram_Options_t options);
};


#endif
