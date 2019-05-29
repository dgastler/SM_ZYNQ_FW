CXX=source /opt/Xilinx/petalinux/2018.2/settings.sh && arm-linux-gnueabihf-g++
CXXFLAGS+=-c -O2 -Wall -Wextra -Werror -Wno-pointer-arith -I./
LDFLAGS+=-L./ 


UIO_REG=uioReg
SI_REG=siIO

all:  $(UIO_REG) $(SI_REG)

$(UIO_REG):	$(UIO_REG).o
	$(CXX) $(LDFLAGS) -o $@ $^

$(SI_REG):	$(SI_REG).o i2c.o
	$(CXX) $(LDFLAGS) -o $@ $^


%.o:%.cxx
	$(CXX) -c $(CXXFLAGS) -o $@  $<

clean:
	@rm $(UIO_REG) > /dev/null 2>&1
	@rm *.o > /dev/null 2>&1
	@rm *~ > /dev/null 2>&1

