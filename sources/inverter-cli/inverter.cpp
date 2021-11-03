#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "inverter.h"
#include "tools.h"
#include "main.h"

#include <fcntl.h>
#include <termios.h>

cInverter::cInverter(std::string devicename) {
    device = devicename;
    status1[0] = 0;
    status2[0] = 0;
    warnings[0] = 0;
    mode = 0;
}

string *cInverter::GetQpigsStatus() {
    m.lock();
    string *result = new string(status1);
    m.unlock();
    return result;
}

string *cInverter::GetQpiriStatus() {
    m.lock();
    string *result = new string(status2);
    m.unlock();
    return result;
}

string *cInverter::GetWarnings() {
    m.lock();
    string *result = new string(warnings);
    m.unlock();
    return result;
}

void cInverter::SetMode(char newmode) {
    m.lock();
    if (mode && newmode != mode)
        ups_status_changed = true;
    mode = newmode;
    m.unlock();
}

int cInverter::GetMode() {
    int result;
    m.lock();

    switch (mode) {
        case 'P': result = 1;   break;  // Power_On
        case 'S': result = 2;   break;  // Standby
        case 'L': result = 3;   break;  // Line
        case 'B': result = 4;   break;  // Battery
        case 'F': result = 5;   break;  // Fault
        case 'H': result = 6;   break;  // Power_Saving
        default:  result = 0;   break;  // Unknown
    }

    m.unlock();
    return result;
}

#define HEX(x) (x < 10 ? ('0' + x) : ('a' + x - 10))
char *cInverter::escape_strn(unsigned char *str, int n) {
    int j=0;

    for (int i=0; i<n; i++) {
	if (isprint(str[i]))
	    escaped_buf[j++] = str[i];
	else {
	    unsigned char x1 = str[i] >> 4;
	    unsigned char x2 = str[i] & 0x0f;
	    escaped_buf[j++] = '\\';
	    escaped_buf[j++] = 'x';
	    escaped_buf[j++] = HEX(x1);
	    escaped_buf[j++] = HEX(x2);
	}
    }

    escaped_buf[j] = '\0';
    return escaped_buf;
}

bool cInverter::query(const char *cmd) {
    time_t started;
    int fd;
    int i=0, n, write_failed=0;

    fd = open(this->device.data(), O_RDWR | O_NONBLOCK);
    if (fd == -1) {
        lprintf("Unable to open device file (errno=%d %s)", errno, strerror(errno));
        sleep(5);
        return false;
    }

    // Once connected, set the baud rate and other serial config (Don't rely on this being correct on the system by default...)
    speed_t baud = B2400;

    // Speed settings (in this case, 2400 8N1)
    struct termios settings;
    tcgetattr(fd, &settings);

    cfsetospeed(&settings, baud);      // baud rate
    settings.c_cflag &= ~PARENB;       // no parity
    settings.c_cflag &= ~CSTOPB;       // 1 stop bit
    settings.c_cflag &= ~CSIZE;
    settings.c_cflag |= CS8 | CLOCAL;  // 8 bits
    // settings.c_lflag = ICANON;         // canonical mode
    settings.c_oflag &= ~OPOST;        // raw output

    tcsetattr(fd, TCSANOW, &settings); // apply the settings
    tcflush(fd, TCOFLUSH);

    // ---------------------------------------------------------------

    // Generating CRC for a command
    uint16_t crc = cal_crc_half((uint8_t*)cmd, strlen(cmd));
    n = strlen(cmd);
    memcpy(&buf, cmd, n);
    lprintf("%s: command CRC: %X %X", cmd, crc >> 8, crc & 0xff);

    buf[n++] = crc >> 8;
    buf[n++] = crc & 0xff;
    buf[n++] = 0x0d; // '\r'
    buf[n+1] = '\0'; // see workaround below

    // send a command
    int chunk_size = 8;
    for (int offset = 0; offset < n; usleep(50000)) {
	int left = n - offset;
	int towrite = left > chunk_size ? chunk_size : left;
	// WORKAROUND: For some reason, writing 1 byte causes it to error.
	// However, since we padded with '\0' above, we can give it 2 instead.
	// I don't know of any 6 (+ 2*CRC + '\r') byte commands to test it on
	// but this at least gets it to return NAK.
	if (towrite == 1) towrite = 2;
        lprintf("%s: write offset %d, writing %d", cmd, offset, towrite);
	ssize_t written = write(fd, &buf[offset], towrite);
	if (written > 0)
	    offset += written;
	else {
	    lprintf("%s: write failed (written=%d, errno=%d: %s)", cmd, written, errno, strerror(errno));
	    write_failed=1;
	    break;
	}
        lprintf("%s: %d bytes to write, %d bytes written", cmd, n, offset);
    }

    // reads tend to be in multiple of 8 chars with NULL padding as necessary
    char *startbuf = (char *)&buf[0];
    char *endbuf = 0;
    time(&started);
    do {
        n = read(fd, &buf[i], 120-i);
        if (n < 0) {
            if (time(NULL) - started > 2) {
                lprintf("%s: read timeout", cmd);
                break;
            } else {
                usleep(10);
                continue;
            }
        }

	endbuf = (char *)memrchr((void *)&buf[i], 0x0d, n);
        i += n;
    } while (endbuf == NULL);
    close(fd);
    buf[i] = '\0';

    lprintf("%s: %d bytes in reply: %s", cmd, i, escape_strn(buf, i));

    if (write_failed) {
	return false;
    }
    else if (i < 3) {
        lprintf("%s: reply too short (%d bytes)", cmd, i);
	return false;
    }
    else if (endbuf == NULL) {
        lprintf("%s: couldn't find reply <cr>: %s", cmd, buf);
	return false;
    }

    int replysize = endbuf - startbuf + 1;

    // proper response, check CRC
    if (buf[0]=='(' && buf[replysize-1]==0x0d) {
        if (!(CheckCRC(buf, replysize))) {
            lprintf("%s: CRC failed!", cmd);
            return false;
        }
	replysize -= 3;
        buf[replysize] = '\0'; // null terminating on first CRC byte
    }
    else {
        lprintf("%s: incorrect start/stop bytes", cmd);
        return false;
    }

    lprintf("%s: %d bytes in payload", cmd, replysize);
    lprintf("%s: query finished", cmd);
    return true;
}

void cInverter::poll() {
    int n,j;
    extern const int qpiri, qpiws, qmod, qpigs;

    while (true) {

        // Reading mode
        if (!ups_qmod_changed) {
            if (query("QMOD") &&
		strcmp((char *)&buf[1], "NAK") != 0) {
                SetMode(buf[1]);
                ups_qmod_changed = true;
            }
        }

        // reading status (QPIGS)
        if (!ups_qpigs_changed) {
            if (query("QPIGS") &&
		strcmp((char *)&buf[1], "NAK") != 0) {
                m.lock();
                strcpy(status1, (const char*)buf+1);
                m.unlock();
                ups_qpigs_changed = true;
            }
        }

        // Reading QPIRI status
        if (!ups_qpiri_changed) {
            if (query("QPIRI") &&
		strcmp((char *)&buf[1], "NAK") != 0) {
                m.lock();
                strcpy(status2, (const char*)buf+1);
                m.unlock();
                ups_qpiri_changed = true;
            }
        }

        // Get any device warnings...
        if (!ups_qpiws_changed) {
            if (query("QPIWS") &&
		strcmp((char *)&buf[1], "NAK") != 0) {
                m.lock();
                strcpy(warnings, (const char*)buf+1);
                m.unlock();
                ups_qpiws_changed = true;
            }
        }

        sleep(5);
    }
}

void cInverter::ExecuteCmd(const string cmd) {
    // Sending any command raw
    if (query(cmd.data())) {
        m.lock();
        strcpy(status2, (const char*)buf+1);
        m.unlock();
    }
}

uint16_t cInverter::cal_crc_half(uint8_t *pin, uint8_t len) {
    uint16_t crc;

    uint8_t da;
    uint8_t *ptr;
    uint8_t bCRCHign;
    uint8_t bCRCLow;

    uint16_t crc_ta[16]= {
        0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
        0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef
    };

    ptr=pin;
    crc=0;

    while(len--!=0) {
        da=((uint8_t)(crc>>8))>>4;
        crc<<=4;
        crc^=crc_ta[da^(*ptr>>4)];
        da=((uint8_t)(crc>>8))>>4;
        crc<<=4;
        crc^=crc_ta[da^(*ptr&0x0f)];
        ptr++;
    }

    bCRCLow = crc;
    bCRCHign= (uint8_t)(crc>>8);

    if(bCRCLow==0x28||bCRCLow==0x0d||bCRCLow==0x0a)
        bCRCLow++;
    if(bCRCHign==0x28||bCRCHign==0x0d||bCRCHign==0x0a)
        bCRCHign++;

    crc = ((uint16_t)bCRCHign)<<8;
    crc += bCRCLow;
    return(crc);
}

bool cInverter::CheckCRC(unsigned char *data, int len) {
    uint16_t crc = cal_crc_half(data, len-3);
    return data[len-3]==(crc>>8) && data[len-2]==(crc&0xff);
}
