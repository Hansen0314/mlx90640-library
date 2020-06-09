#include <stdint.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <chrono>
#include <thread>
#include "headers/MLX90640_API.h"
#include "headers/MLX90641_API.h"


#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_NONE    "\x1b[30m"
#define ANSI_COLOR_RESET   "\x1b[0m"

//#define FMT_STRING "%+06.2f "
#define FMT_STRING "\u2588\u2588"

#define MLX_I2C_ADDR 0x33

int main(){
    printf("Starting...\n");
    
    std::fstream fs;

    const int MLX90641_address = 0x33; //Default 7-bit unshifted address of the MLX90641
    #define TA_SHIFT 8 //Default shift for MLX90641 in open air

    uint16_t eeMLX90641[832];
    float MLX90641To[192];
    uint16_t MLX90641Frame[242];
    paramsMLX90641 MLX90641;
    int errorno = 0;

    int status;
    status = MLX90641_DumpEE(MLX90641_address, eeMLX90641);
    status = MLX90641_ExtractParameters(eeMLX90641, &MLX90641);
    MLX90641_SetRefreshRate(MLX90641_address, 0x03); //Set rate to 4Hz

    while (1){
        for (int x = 0 ; x < 2 ; x++) {
            status = MLX90641_GetFrameData(MLX90641_address, MLX90641Frame);

            float vdd = MLX90641_GetVdd(MLX90641Frame, &MLX90641);
            float Ta = MLX90641_GetTa(MLX90641Frame, &MLX90641);

            float tr = Ta - TA_SHIFT; //Reflected temperature based on the sensor ambient temperature
            float emissivity = 0.95;

            MLX90641_CalculateTo(MLX90641Frame, &MLX90641, emissivity, tr, MLX90641To);
        }
        //MLX90641_SetSubPage(MLX_I2C_ADDR,!subpage);

        for(int x = 0; x < 12; x++){
            for(int y = 0; y < 16; y++){
                //std::cout << image[32 * y + x] << ",";
                float val = MLX90641To[12 * (15-y) + x];
                if(val > 99.99) val = 99.99;
                if(val > 32.0){
                    printf(ANSI_COLOR_MAGENTA FMT_STRING ANSI_COLOR_RESET, val);
                }
                else if(val > 29.0){
                    printf(ANSI_COLOR_RED FMT_STRING ANSI_COLOR_RESET, val);
                }
                else if (val > 26.0){
                    printf(ANSI_COLOR_YELLOW FMT_STRING ANSI_COLOR_YELLOW, val);
                }
                else if ( val > 20.0 ){
                    printf(ANSI_COLOR_NONE FMT_STRING ANSI_COLOR_RESET, val);
                }
                else if (val > 17.0) {
                    printf(ANSI_COLOR_GREEN FMT_STRING ANSI_COLOR_RESET, val);
                }
                else if (val > 10.0) {
                    printf(ANSI_COLOR_CYAN FMT_STRING ANSI_COLOR_RESET, val);
                }
                else {
                    printf(ANSI_COLOR_BLUE FMT_STRING ANSI_COLOR_RESET, val);
                }
            }
            std::cout << std::endl;
        }
        //std::this_thread::sleep_for(std::chrono::milliseconds(20));
        printf("\x1b[33A");
    }
    return 0;
}
