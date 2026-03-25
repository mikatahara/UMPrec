//
//  main.cpp
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
#include "sub.hpp"

MIDIClientRef client;
MIDIPortRef inputPort;
uint32_t nRcount=0; //受信したメッセージの数
int8_t revport=-1;    //受信ポート番号

// コールバック（UMP受信）
void MIDIInputCallback(const MIDIEventList *evtlist,
                       void *srcConnRefCon)
{
    const MIDIEventPacket *packet = &evtlist->packet[0];
    nRcount++;
    
    for (unsigned int i = 0; i < evtlist->numPackets; ++i)
    {
        printf("%5d : ",nRcount);

        // UMPは32bit単位
        for (int j = 0; j < packet->wordCount; ++j)
        {
            printf("%08X ", packet->words[j]);
        }
        printf("\n");

        packet = MIDIEventPacketNext(packet);
    }
}

int main(int ac, char *av[])
{
    OSStatus status;
    
    setOption(ac,av);   //Option 設定

    // MIDIクライアント作成
    status = MIDIClientCreate(CFSTR("MIDI Client"), nullptr, nullptr, &client);
    if (status != noErr)
    {
        std::cerr << "MIDIClientCreate error\n";
        return -1;
    }

    // 入力ポート作成（UMP対応）
    status = MIDIInputPortCreateWithProtocol(
        client,
        CFSTR("Input port"),
        kMIDIProtocol_2_0,
        &inputPort,
        ^(const MIDIEventList * _Nonnull evtlist, void * _Nullable srcConnRefCon) {
            MIDIInputCallback(evtlist, srcConnRefCon);
        }
    );
    
    if (status != noErr)
    {
        std::cerr << "MIDIInputPortCreateWithProtocol error\n";
        return -1;
    }

    // すべてのMIDIソースに接続
    ItemCount sourceCount = MIDIGetNumberOfSources();
    
    std::cout << "sourceCount=" << sourceCount << std::endl;

    for (ItemCount i = 0; i < sourceCount; ++i)
        {
            MIDIEndpointRef src = MIDIGetSource(i);

            CFStringRef endpointName = nullptr;
            CFStringRef deviceName = nullptr;

            // --- ポート名（エンドポイント名）
            MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName);

            // --- Entity取得
            MIDIEntityRef entity = 0;
            if (MIDIEndpointGetEntity(src, &entity) == noErr && entity != 0)
            {
                // --- Device取得
                MIDIDeviceRef device = 0;
                if (MIDIEntityGetDevice(entity, &device) == noErr && device != 0)
                {
                    MIDIObjectGetStringProperty(device, kMIDIPropertyName, &deviceName);
                }
            }

            std::cout << "Source " << i << ": ";

            if (deviceName)
            {
                PrintCFString(deviceName);
                std::cout << " : ";
            }

            if (endpointName)
            {
                PrintCFString(endpointName);
            }
            else
            {
                std::cout << "(no name)";
            }

            std::cout << std::endl;

            // メモリ解放
            if (endpointName) CFRelease(endpointName);
            if (deviceName) CFRelease(deviceName);
        }
    
    
    if(revport>=0){
        MIDIEndpointRef src = MIDIGetSource(revport);
        MIDIPortConnectSource(inputPort, src, nullptr);
        
        std::cout << "Listening for MIDI 2.0 UMP..." << std::endl;
        
        // RunLoopで待機
        std::thread t(keyThread);   //ESC Keyを待つ
        CFRunLoopRun();
        t.join();
    }

    return 0;
}

