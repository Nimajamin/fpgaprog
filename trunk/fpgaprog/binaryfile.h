#ifndef BINARYFILE_H
#define BINARYFILE_H

#include <stdio.h>
#include <string>

typedef unsigned char byte;

class BinaryFile
{
private:
    unsigned long length; // The length of the byte data that follows, multiply by 8 to get bitstream length.
    byte *buffer; // Each byte is reversed, JTAG does things LSB first!
    std::string filename;
    byte bitRevTable[256]; // Bit reverse lookup table
    bool Error;
    std::string errorStr;
    FILE *logfile;

private:
    void initFlip();
    void error(const std::string &str);
    void processData(FILE *fp, bool flip);

public:
    BinaryFile();
    ~BinaryFile();

public:
    void readFile(char const *fname, bool flip=true);

public:
    inline byte *getData(){return buffer;}
    inline unsigned long getLength(){return length;} // Returns length of bitstream, in bytes
    inline const char *getError()
    {
        if(!Error)
            return("");
        Error=false;
        return errorStr.c_str();
    }
    void print();
    unsigned char reverse8(unsigned char b){return bitRevTable[b];};
};

#endif //BINARYFILE_H

