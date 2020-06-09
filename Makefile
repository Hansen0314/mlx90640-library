I2C_MODE = LINUX
I2C_LIBS = 
#I2C_LIBS = -lbcm2835
SRC_DIR = examples/src/
BUILD_DIR = examples/
LIB_DIR = $(SRC_DIR)lib/
CHIP_TYPE = MLX90641

examples = test
examples_objects = $(addsuffix .o,$(addprefix $(SRC_DIR), $(examples)))
examples_output = $(addprefix $(BUILD_DIR), $(examples))

#PREFIX is environment variable, but if it is not set, then set default value
ifeq ($(PREFIX),)
	PREFIX = /usr/local
endif

ifeq ($(I2C_MODE), LINUX)
	I2C_LIBS =
endif

all: examples

examples: $(examples_output)

lib$(CHIP_TYPE)_API.so: functions/$(CHIP_TYPE)_API.o functions/MLX9064x_$(I2C_MODE)_I2C_Driver.o
	$(CXX) -fPIC -shared $^ -o $@ $(I2C_LIBS)

lib$(CHIP_TYPE)_API.a: functions/$(CHIP_TYPE)_API.o functions/MLX9064x_$(I2C_MODE)_I2C_Driver.o
	ar rcs $@ $^
	ranlib $@
	
functions/$(CHIP_TYPE)_API.o functions/MLX9064x_RPI_I2C_Driver.o functions/MLX9064x_LINUX_I2C_Driver.o : CXXFLAGS+=-fPIC -I headers -shared $(I2C_LIBS)

$(examples_objects) : CXXFLAGS+=-std=c++11

$(examples_output) : CXXFLAGS+=-I. -std=c++11

examples/src/lib/interpolate.o : CC=$(CXX) -std=c++11

examples/src/sdlscale.o : CXXFLAGS+=`sdl2-config --cflags --libs`

$(BUILD_DIR)sdlscale: $(SRC_DIR)sdlscale.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS) `sdl2-config --libs`

$(BUILD_DIR)hotspot: $(SRC_DIR)hotspot.o $(LIB_DIR)fb.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS)

$(BUILD_DIR)test: $(SRC_DIR)test.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS)

$(BUILD_DIR)rawrgb: $(SRC_DIR)rawrgb.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS)

$(BUILD_DIR)step: $(SRC_DIR)step.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS)

$(BUILD_DIR)fbuf: $(SRC_DIR)fbuf.o $(LIB_DIR)fb.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS)

$(BUILD_DIR)interp: $(SRC_DIR)interp.o $(LIB_DIR)interpolate.o $(LIB_DIR)fb.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS)

$(BUILD_DIR)video: $(SRC_DIR)video.o $(LIB_DIR)fb.o lib$(CHIP_TYPE)_API.a
	$(CXX) -L/home/pi/$(CHIP_TYPE)-library $^ -o $@ $(I2C_LIBS) -lavcodec -lavutil -lavformat

bcm2835-1.55.tar.gz:	
	wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.55.tar.gz

bcm2835-1.55: bcm2835-1.55.tar.gz
	tar xzvf bcm2835-1.55.tar.gz

bcm2835: bcm2835-1.55
	cd bcm2835-1.55; ./configure; make; sudo make install

clean:
	rm -f $(examples_output)
	rm -f $(SRC_DIR)*.o
	rm -f $(LIB_DIR)*.o
	rm -f functions/*.o
	rm -f *.o
	rm -f *.so
	rm -f *.a

install: lib$(CHIP_TYPE)_API.a lib$(CHIP_TYPE)_API.so
	install -d $(DESTDIR)$(PREFIX)/lib/
	install -m 644 lib$(CHIP_TYPE)_API.a $(DESTDIR)$(PREFIX)/lib/
	install -m 644 lib$(CHIP_TYPE)_API.so $(DESTDIR)$(PREFIX)/lib/
	install -d $(DESTDIR)$(PREFIX)/include/$(CHIP_TYPE)/
	install -m 644 headers/*.h $(DESTDIR)$(PREFIX)/include/$(CHIP_TYPE)/
	ldconfig
