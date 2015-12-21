#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <stdbool.h>
#include <Foundation/Foundation.h>
#include "rtsp_relay.h"

AVFormatContext *m_informat=NULL,*m_outformat=NULL;
AVStream *m_in_vid_strm,*m_out_vid_strm;
int m_in_vid_strm_idx;
AVOutputFormat *outfmt = NULL;
bool m_init_done;
int EXIT_FLAG=0;
AVPacket pkt;
AVDictionary *options = NULL;
NSTimer              *_timer;

int clean_all(){
	av_write_trailer(m_outformat);
	avformat_close_input(&m_informat);
	avformat_free_context(m_outformat);
	m_informat=NULL;
	m_in_vid_strm=NULL;
	options = NULL;
    EXIT_FLAG=0;
	printf("cleaning success\n");
	return 0;
	
	}

int init_streams(char *url_in ,char *url_out){
    int i,ret;
    av_register_all();
    avformat_network_init();
	//av_log_set_level(AV_LOG_TRACE);
    printf("%s\n",url_in);
    ret=avformat_open_input( &m_informat, url_in, NULL,NULL);
	if(ret!=0){
	printf("Error in connection\n");
	return -1;
	}
    if ((ret = avformat_find_stream_info(m_informat, 0))< 0){
        printf("Stream info not found");
        ret = -1;
        return ret;
    }

        for (i = 0; i<m_informat->nb_streams; i++)
        {
           if(m_informat->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
           {
              printf("Found Video Stream \n");
              m_in_vid_strm_idx = i;
              m_in_vid_strm = m_informat->streams[i];
           }
        }
    // 4. Create ouputfile  and allocate output format.
    
    ret=avformat_alloc_output_context2(&m_outformat, NULL, "rtsp", url_out);
	printf("AValloc :%d\n",ret);
    outfmt=m_outformat->oformat;
    if(outfmt==NULL){
    printf("Guess failed\n");
    }
    if(m_outformat){
        m_outformat->oformat = outfmt;    
    }

    AVCodec *out_vid_codec;
    out_vid_codec = NULL;
    if(outfmt->video_codec != AV_CODEC_ID_NONE){
        printf("check1 pass\n");
        out_vid_codec = avcodec_find_encoder(outfmt->video_codec);
        m_out_vid_strm = avformat_new_stream(m_outformat, out_vid_codec);
        if(avcodec_copy_context(m_out_vid_strm->codec,m_informat->streams[m_in_vid_strm_idx]->codec) != 0){
            printf("Failed to Copy Context \n");
            ret = -1;
            return ret;
        }
        else{
            m_out_vid_strm->sample_aspect_ratio.den =m_out_vid_strm->codec->sample_aspect_ratio.den;
            m_out_vid_strm->sample_aspect_ratio.num = m_in_vid_strm->codec->sample_aspect_ratio.num;
            printf("Copied Context \n");
            m_out_vid_strm->codec->codec_id = m_in_vid_strm->codec->codec_id;
            m_out_vid_strm->codec->time_base.num = 1;
            m_out_vid_strm->codec->time_base.den =m_in_vid_strm->codec->time_base.den;         
            m_out_vid_strm->time_base.num = 1;
            m_out_vid_strm->time_base.den = 1000;
            m_out_vid_strm->r_frame_rate.num =m_in_vid_strm->r_frame_rate.num;
            m_out_vid_strm->r_frame_rate.den = 1;
            m_out_vid_strm->avg_frame_rate.den = 1;
            m_out_vid_strm->avg_frame_rate.num = m_in_vid_strm->avg_frame_rate.num;
         }

    }
	av_dict_set(&options, "rtsp_transport", "tcp", 0);
	if (!(outfmt->flags & AVFMT_NOFILE)){
        if (avio_open2(&m_outformat->pb, url_out, AVIO_FLAG_WRITE,NULL, &options) < 0){
            printf("Could Not Open File out(Error in avio_open2)\n");
        }
    }
    
    /* Write the stream header, if any. */
    ret=avio_open2(&m_outformat->pb, url_out, AVIO_FLAG_WRITE,NULL, &options);
    if (m_outformat->pb == NULL) {
        printf("Error in avio_open:%d\n",ret);
    }
	ret=avformat_write_header(m_outformat, &options);
    if (ret < 0){
        printf("ret:%d\n",ret);
        printf("Error Occurred While Writing Header ");
        ret = -1;
        return ret;
    }
    else{
        printf("Written Output header\n");
                m_init_done = true;
    }
	//return 0;
	return 0;
}


int start_stream(){
    
    int fun_ret,ret;
    EXIT_FLAG=0;
	int i;
    while(av_read_frame(m_informat, &pkt) >= 0){
        if(pkt.stream_index == m_in_vid_strm_idx){
            NSLog(@"Stream found\n");
            ret=av_write_frame(m_outformat, &pkt);
             NSLog(@"Writing Stream\n");
			if(ret<0){
				i++;
				printf("i=%d",i);
				if(i==250){
					fun_ret=2;
                     NSLog(@"un_ret=2\n");
					break;
				}
			}
			else
				i=0;   
        }
        if(EXIT_FLAG==1){
			
			EXIT_FLAG=0;
			fun_ret=0;
			NSLog(@"Exiting\n");
        	break;
        }
		else
        {
            NSLog(@"fun_ret=1;");
			fun_ret=1;
        }
    }
	
	NSLog(@"Stream stopped from start\n");
	//av_free_packet(&pkt);
	clean_all();
	return fun_ret;
}

int stop_stream(){
    EXIT_FLAG=1;
    NSLog(@"Stream stopped\n");
	//
    return -1;
    }

