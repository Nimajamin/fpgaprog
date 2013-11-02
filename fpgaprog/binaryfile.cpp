#include "binaryfile.h"
#include "io_exception.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

using namespace std;

BinaryFile::BinaryFile()
  : length(0), buffer(0), Error(false), logfile(stderr) {

  // Initialize bit flip table
  initFlip();
}

// print information of the bit file
void BinaryFile::print()
{
    printf("Bitstream length: %lu bits\n", getLength());
}

// Read in file
void BinaryFile::readFile(char const * fname, bool flip)
{
    FILE *const  fp=fopen(fname,"rb");
    if(!fp)
        throw  io_exception(std::string("Cannot open file ") );
    filename = fname;
    int ret;

	// get length
    fseek(fp, 0L, SEEK_END);
    length=ftell(fp);
    fseek(fp, 0L, SEEK_SET);
    
    if(buffer)
        delete [] buffer;
    buffer=new byte[length];
    printf("length: %ld\n",length);

    for(unsigned int i=0; i<length&&!feof(fp); i++)
    {
        byte b;
        ret = fread(&b,1,1,fp);
        buffer[i]=(flip?bitRevTable[b]:b); // Reverse the bit order.
    }
}

void BinaryFile::error(const string &str)
{
    errorStr=str;
    Error=true;
    fprintf(logfile,"%s\n",str.c_str());
}

void BinaryFile::initFlip()
{
  for(int i=0; i<256; i++){
    int num=i;
    int fnum=0;
    for(int k=0; k<8; k++){
      int bit=num&1;
      num=num>>1;
      fnum=(fnum<<1)+bit;
    }
    bitRevTable[i]=fnum;
  }
}


BinaryFile::~BinaryFile()
{
  if(buffer)
    delete [] buffer;
}
