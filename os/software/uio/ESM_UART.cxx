#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <string>
#include <unistd.h> // usleep
#include <iostream> // cin
#include <string.h> // strlen

#define RD_ADDR 0xB
#define RD_AVAILABLE 0x1000
#define RD_HALF_FULL 0x2000
#define RD_FULL 0x4000

#define WR_ADDR 0xA
#define WR_HALF_FULL 0x2000
#define WR_FULL 0x4000
#define WR_FULL_FULL (WR_FULL | WR_HALF_FULL)

#define MAXWRCOMMAND 100

#define ACK 0x100

//===============================================================================
//Struct to use for mapping into the AXI slave
//===============================================================================
#define REG_COUNT 256
//struct TestHW {
//  uint32_t reg[REG_COUNT];
//};

char const * const usage = "uio r/w addr <data>";

//===============================================================================
// global variables
bool rdBufferOverflow = false;

// Read buffer
std::string recvline;
char byteRead = 0;
//===============================================================================

//===============================================================================
// helper functions 
void writeByte(uint32_t volatile * hdw, char const byte) {
  hdw[WR_ADDR] = byte;
}

int readLine(uint32_t volatile * hdw) {

  int OK = 0;
  int READBUFFULL = -1;

  while(RD_AVAILABLE & hdw[RD_ADDR]) {
    // Print error if there is available data after prompt
    if('>' == byteRead) {
      printf("Error: more available bytes to be read after prompt >\n");
      // Trash all extra bytes
      while(RD_AVAILABLE & hdw[RD_ADDR]) {
	byteRead = (0xFF&hdw[RD_ADDR]);
      }
      return OK;
    }
    
    // read byte and append to string
    byteRead = (0xFF&hdw[RD_ADDR]);
    recvline.push_back(byteRead);
    // Acknowledge 
    hdw[RD_ADDR] = ACK;
        
    // Check if read buffer is full
    if(RD_FULL & hdw[RD_ADDR]) {
      rdBufferOverflow = true;
      return READBUFFULL;
    }
  }
  
  return OK;
}

int writeLine(uint32_t volatile * hdw, char const msg[]) {

  int OK = 0;
  int READBUFFULL = -1;
  int ERROR = -2;
  
  // write byte by byte
  for(int i = 0; i < MAXWRCOMMAND; i++) {
    byteRead = 0;

    // Before writing a byte, read any available bytes. Stop writing if read buffer overflowed
    if(-1 == readLine(hdw)) {return READBUFFULL;}
    
    // Wait until write buffer is less than half full
    while(WR_HALF_FULL <= hdw[WR_ADDR]) {
      usleep(1000);
      printf("write buffer half full: slept 1000 microsecs\n");
    }
    
    // write byte
    //    printf("writing...\n");
    hdw[WR_ADDR] = msg[i];
    // Command is done after writing newline
    if('\r' == msg[i]) {return OK;}
  }

  // If for some reason newline was not reached. To get rid of compiler error
  return ERROR;
}

void overflowAlert() {
  printf("Received:\n%s\n", recvline.c_str());
  recvline.clear();
  // Notify user of overflow
  printf("Read buffer overflowed\n");
  // Manually print prompt
  printf("> ");
  rdBufferOverflow = false;
}
//===============================================================================

//int main(int argc, char ** argv){
int main() {

  //  uint32_t writeData = 0;
  //uint32_t address;
  //  bool wr = false; //read = false

  //  uint32_t uioNumber = 0;
  // 3 or 5
  uint32_t uioNumber = 5;
  
  // Write buffer
  char sendline[MAXWRCOMMAND];
    
  //=============================================================================
  //UIO access
  //============================================================================= 
  
  //For now hard-code this to uio1, but in the future we should look in sys or some other API to find the correct devices.
  //We do nothing about premissions and assume you are root or someone has changed the permissions to the UIO devices already
  const size_t dev_length = 30;
  char dev[dev_length+1];
  snprintf(dev,dev_length,"/dev/uio%u",uioNumber);
  int fdUIO = open(dev, O_RDWR|O_SYNC);  
  if(-1 == fdUIO){
    fprintf(stderr,"Error!\nBad UIO %s\n",dev);
    return -1;
  }

  //setup memory mappings
  uint32_t volatile * hw = (uint32_t *) mmap(NULL,
					     sizeof(uint32_t), //sizeof(TestHW),
					     PROT_READ|PROT_WRITE,
					     MAP_SHARED,
					     fdUIO,
					     0x0);  //This may need some page size rounding for safety, but for now the AXI devices are easily on page boundaries. 

  //=============================================================================
  //Reads and writes
  //=============================================================================

  int writeReturn = 0;
  
  while(true) {
    // Get command
    std::cin.getline(sendline, MAXWRCOMMAND);
    // Append newline
    sendline[strlen(sendline)] = '\r';
    
    // If read buffer overflowed, don't read, alert user and continue
    if(-1 == (writeReturn = writeLine(hw, sendline))) {
      overflowAlert();
      continue;
    } else if (-2 == writeReturn) {
      printf("Error: carriage return was not sent\n");
      continue;
    }
    
    byteRead = 0;
    // Read all available bytes. If read buffer overflowed, alert user and continue
    if(-1 == readLine(hw)) {
      overflowAlert();
      continue;
    }

    printf("Received:\n%s", recvline.c_str());
    recvline.clear();
  }
  
  //=============================================================================
  //Reads and writes
  //=============================================================================
//  hw[0xb]
//  if(wr){
//    hw->reg[address] = writeData;
//    printf("write 0x%02X: 0x%08X\n",address,writeData);
//  }else{
//    printf("read  0x%02X: 0x%08X\n",address,hw->reg[address]);
//  }
  

  return 0;
}
