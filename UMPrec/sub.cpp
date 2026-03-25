//
//  sub.cpp
//  UMPrec
//
//  Created by Mikata Hara on 2026/03/25.
//

#include <CoreMIDI/CoreMIDI.h>
#include <iostream>
#include <stdint.h>
#include <unistd.h>
#include <thread>
#include <termios.h>
#include <unistd.h>
#include "sub.hpp"

bool running = true;

int getch()
{
    struct termios oldt, newt;
    tcgetattr(STDIN_FILENO, &oldt);

    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);

    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    int c = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);

    return c;
}

void keyThread()
{
    while (running)
    {
        int c = getch();
        if (c == 27) // ESC
        {
            running = false;
            CFRunLoopStop(CFRunLoopGetMain());
        }
    }
}

void PrintCFString(CFStringRef str)
{
    if (!str) return;

    char buf[256];
    if (CFStringGetCString(str, buf, sizeof(buf), kCFStringEncodingUTF8))
    {
        std::cout << buf;
    }
}

bool setOption(int argc, char *argv[]){

    int option;

    /* option check */
    while ((option = getopt(argc,argv,"i:")) != EOF) {
        switch (option) {
            case'i':
                sscanf(optarg,"%d",&revport);
                fprintf(stderr,"Receive Port No=%d\n",revport);
                break;
            default:
                break;
        }
    }
    
    return true;
}
