#ifndef ___INVERTER_H
#define ___INVERTER_H

#include <thread>
#include <mutex>

using namespace std;

class cInverter {
    unsigned char buf[1024]; //internal work buffer

    char warnings[1024];
    char status1[1024];
    char status2[1024];
    char mode;

    std::string device;
    std::mutex m;

    void SetMode(char newmode);
    bool CheckCRC(unsigned char *buff, int len);
    bool query(const char *cmd);
    uint16_t cal_crc_half(uint8_t *pin, uint8_t len);

    public:
        cInverter(std::string devicename);
        void poll();
        void runMultiThread() {
            std::thread t1(&cInverter::poll, this);
            t1.detach();
        }

        string *GetQpiriStatus();
        string *GetQpigsStatus();
        string *GetWarnings();

        int GetMode();
        void ExecuteCmd(const std::string cmd);
};

#endif // ___INVERTER_H
