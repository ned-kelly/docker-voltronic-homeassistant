#include <mutex>
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>
#include <sys/time.h>
#include <string>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include "main.h"
#include "tools.h"

std::mutex log_mutex;

void lprintf(const char *format, ...) {
  // Only print if debug flag is set, else do nothing
  if (debugFlag) {
        va_list ap;
        char fmt[2048];

        //actual time
        time_t rawtime;
        struct tm *timeinfo;
        time(&rawtime);
        timeinfo = localtime(&rawtime);
        char buf[256];
        strcpy(buf, asctime(timeinfo));
        buf[strlen(buf)-1] = 0;

        //connect with args
        snprintf(fmt, sizeof(fmt), "%s %s\n", buf, format);

        //put on screen:
        va_start(ap, format);
        vprintf(fmt, ap);
        va_end(ap);

        //to the logfile:
        static FILE *log;
        log_mutex.lock();
        log = fopen(LOG_FILE, "a");
        va_start(ap, format);
        vfprintf(log, fmt, ap);
        va_end(ap);
        fclose(log);
        log_mutex.unlock();
    }
}

int print_help() {
    printf("\nUSAGE:  ./inverter_poller <args> [-r <command>], [-h | --help], [-1 | --run-once]\n\n");

    printf("SUPPORTED ARGUMENTS:\n");
    printf("          -r <raw-command>      TX 'raw' command to the inverter\n");
    printf("          -h | --help           This Help Message\n");
    printf("          -1 | --run-once       Runs one iteration on the inverter, and then exits\n");
    printf("          -d                    Additional debugging\n\n");

    printf("RAW COMMAND EXAMPLES (see protocol manual for complete list):\n");
    printf("Set output source priority  POP00     (Utility first)\n");
    printf("                            POP01     (Solar first)\n");
    printf("                            POP02     (SBU)\n");
    printf("Set charger priority        PCP00     (Utility first)\n");
    printf("                            PCP01     (Solar first)\n");
    printf("                            PCP02     (Solar and utility)\n");
    printf("                            PCP03     (Solar only)\n");
    printf("Set other commands          PEa / PDa (Enable/disable buzzer)\n");
    printf("                            PEb / PDb (Enable/disable overload bypass)\n");
    printf("                            PEj / PDj (Enable/disable power saving)\n");
    printf("                            PEu / PDu (Enable/disable overload restart)\n");
    printf("                            PEx / PDx (Enable/disable backlight)\n\n");

    return 1;
}