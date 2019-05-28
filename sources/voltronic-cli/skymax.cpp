#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "skymax.h"
#include "tools.h"
#include "main.h"

cSkymax::cSkymax(std::string devicename)
{
  device = devicename;
  status1[0] = 0;
  status2[0] = 0;
  mode = 0;
}

string *cSkymax::GetQpigsStatus()
{
  m.lock();
  string *result = new string(status1);
  m.unlock();
  return result;
}

string *cSkymax::GetQpiriStatus()
{
  m.lock();
  string *result = new string(status2);
  m.unlock();
  return result;
}

void cSkymax::SetMode(char newmode)
{
  m.lock();
  if (mode && newmode != mode)
    ups_status_changed = true;
  mode = newmode;
  m.unlock();
}

int cSkymax::GetMode()
{
  int result;
  m.lock();
  switch (mode)
  {
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

bool cSkymax::query(const char *cmd)
{
  time_t started;
  int fd;
  int i = 0, n;

  fd = open(this->device.data(), O_RDWR | O_NONBLOCK);  // device is provided by program arg (usually /dev/hidraw0)
  if (fd == -1)
  {
    lprintf("Skymax:  Unable to open device file (errno=%d %s)", errno, strerror(errno));
    sleep(10);
    return false;
  }

  // Generating CRC for a command
  uint16_t crc = cal_crc_half((uint8_t*)cmd, strlen(cmd));
  n = strlen(cmd);
  memcpy(&buf, cmd, n);
  lprintf("SKYMAX:  Current CRC: %X %X", crc >> 8, crc & 0xff);
  buf[n++] = crc >> 8;
  buf[n++] = crc & 0xff;
  buf[n++] = 0x0d;

  // Send a command
  write(fd, &buf, n);
  time(&started);

  // Instead of using a fixed size for expected response length, lets find it
  // by searching for the first returned <cr> char instead.
  char *startbuf = 0;
  char *endbuf = 0;
  do
  {
    // According to protocol manual, it appears no query should ever exceed 150 byte size in response
    n = read(fd, (void*)buf+i, 120 - i);
    if (n < 0)
    {
      if (time(NULL) - started > 8)     // Wait 8 secs before timeout
      {
        lprintf("SKYMAX:  %s read timeout", cmd);
        break;
      }
      else
      {
        usleep(10);
        continue;
      }
    }
    i += n;

    startbuf = (char *)&buf[0];
    endbuf = strchr(startbuf, '\r');
    //lprintf("SKYMAX:  %s Current buffer: %s", cmd, startbuf);
  } while (endbuf == NULL);     // Still haven't found end <cr> char as long as pointer is null
  close(fd);

  int replysize = endbuf - startbuf + 1;
  lprintf("SKYMAX:  Found <cr> at byte: %d", replysize);

  if (buf[0]!='(' || buf[replysize-1]!=0x0d)
  {
    lprintf("SKYMAX:  %s: incorrect start/stop bytes.  Buffer: %s", cmd, buf);
    return false;
  }
  if (!(CheckCRC(buf, replysize)))
  {
    lprintf("SKYMAX:  %s: CRC Failed!  Reply size: %d  Buffer: %s", cmd, replysize, buf);
    return false;
  }
  buf[replysize-3] = '\0';      // Null-terminating on first CRC byte
  lprintf("SKYMAX:  %s: %d bytes read: %s", cmd, i, buf);
  
  lprintf("SKYMAX:  %s query finished", cmd);
  return true;
}

void cSkymax::poll()
{
  int n,j;

  while (true)
  {
    // Reading mode
    if (!ups_qmod_changed)
    {
      if (query("QMOD"))
      {
        SetMode(buf[1]);
        ups_qmod_changed = true;
      }
    }
    
    // Reading QPIGS status
    if (!ups_qpigs_changed)
    {
      if (query("QPIGS"))
      {
        m.lock();
        strcpy(status1, (const char*)buf+1);
        m.unlock();
        ups_qpigs_changed = true;
      }
    }

    // Reading QPIRI status
    if (!ups_qpiri_changed)
    {
      if (query("QPIRI"))
      {
        m.lock();
        strcpy(status2, (const char*)buf+1);
        m.unlock();
        ups_qpiri_changed = true;
      }
    }
    sleep(5);
  }
}

void cSkymax::ExecuteCmd(const string cmd)
{
  // Sending any command raw
  if (query(cmd.data()))
  {
    m.lock();
    strcpy(status2, (const char*)buf+1);
    m.unlock();
  }
}

uint16_t cSkymax::cal_crc_half(uint8_t *pin, uint8_t len)
{
  uint16_t crc;

  uint8_t da;
  uint8_t *ptr;
  uint8_t bCRCHign;
  uint8_t bCRCLow;

  uint16_t crc_ta[16]=
  {
    0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
    0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef
  };
  ptr=pin;
  crc=0;

  while(len--!=0)
  {
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

bool cSkymax::CheckCRC(unsigned char *data, int len)
{
  uint16_t crc = cal_crc_half(data, len-3);
  return data[len-3]==(crc>>8) && data[len-2]==(crc&0xff);
}
