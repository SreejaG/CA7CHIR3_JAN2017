/*This header is defined to use following functions in SCREENCAP*/
#ifndef SCREENCAP_H
#define SCREENCAP_H
#include <libavformat/avformat.h>
int screencap(char *,char*);
void SaveFrame(AVFrame *,int, int, int,char*);
#endif /*RTSP_RELAY_H*/
