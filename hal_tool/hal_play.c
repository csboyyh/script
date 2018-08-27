#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <signal.h>
#include <dlfcn.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <cutils/properties.h>
#include <hardware/hardware.h>
#include <system/audio.h>
#include <hardware/audio.h>
                  

#define ID_RIFF 0x46464952
#define ID_WAVE 0x45564157
#define ID_FMT  0x20746d66
#define ID_DATA 0x61746164

#define FOURCC(a,b,c,d) ((d)|(c)<<8|(b)<<16|(a)<<24)


struct riff_wave_header {
    uint32_t riff_id;
    uint32_t riff_sz;
    uint32_t wave_id;
};

struct chunk_header {
    uint32_t id;
    uint32_t sz;
};

struct chunk_fmt {
    uint16_t audio_format;
    uint16_t num_channels;
    uint32_t sample_rate;
    uint32_t byte_rate;
    uint16_t block_align;
    uint16_t bits_per_sample;
};

static struct out_config{
    struct audio_config  config;
    audio_io_handle_t    handle;
    audio_devices_t      devices;
    audio_output_flags_t flags;
    struct audio_stream_out *stream;
    pthread_mutex_t      mtx;
    pthread_cond_t       cond;
    int                  fd;
    bool                 changed;
    int                 stop;
}out_config = {
    .config = 
    {.sample_rate   = 44100,
     .channel_mask  = AUDIO_CHANNEL_OUT_FRONT_RIGHT | AUDIO_CHANNEL_OUT_FRONT_LEFT,
     .format        = AUDIO_FORMAT_PCM_16_BIT,
     .offload_info  = {0},
     .frame_count   = 0
    },
    .handle = 0,
    .devices = AUDIO_DEVICE_OUT_SPEAKER, 
    .flags = AUDIO_OUTPUT_FLAG_PRIMARY,
    .stream = NULL,
    .mtx = PTHREAD_MUTEX_INITIALIZER,
    .cond = PTHREAD_COND_INITIALIZER,
    .fd = -1,
    .changed = true,
    .stop = 1
};

static struct in_config{
    struct audio_config  config;
    audio_io_handle_t    handle;
    audio_devices_t      devices;
    audio_input_flags_t  flags;
    struct audio_stream_in *stream;
    audio_source_t       source;
    pthread_mutex_t      mtx; 
    pthread_cond_t       cond;
    int                  fd;
    bool                 changed;
    int                  stop;
}in_config = {
    .config = 
    {.sample_rate   = 44100,
     .channel_mask  = AUDIO_CHANNEL_OUT_FRONT_RIGHT | AUDIO_CHANNEL_OUT_FRONT_LEFT,
     .format        = AUDIO_FORMAT_PCM_16_BIT,
     .offload_info  = {0},
     .frame_count   = 0
    },
    .handle = 0,
    .devices = AUDIO_DEVICE_IN_BUILTIN_MIC,
    .flags = AUDIO_INPUT_FLAG_RAW,
    .stream = NULL,
    .source = AUDIO_SOURCE_MIC,
    .mtx = PTHREAD_MUTEX_INITIALIZER,
    .cond = PTHREAD_COND_INITIALIZER,
    .fd = -1,
    .changed = true,
    .stop = 1
};

static int closed = 0;
static struct audio_module* p_module = NULL;
static struct audio_hw_device* phw_dev = NULL;

void stream_close(int sig)
{
    /* allow the stream to be closed gracefully */
    signal(sig, SIG_IGN);
    closed = 1;
}
static int stream_set_param(char *args)
{
    int32_t ret = -1;
    char* iter = NULL;
    
    printf("Set parameter:%s",args);
    
    iter = strtok(args," ");

    if (!strcmp(iter,"in")){
        pthread_mutex_lock(&in_config.mtx);
        if(in_config.stream){
            ret = in_config.stream->common.set_parameters(in_config.stream,strtok(NULL," "));
            printf("in set parameter ret %d\n",ret);
        }
        pthread_mutex_unlock(&in_config.mtx);

    }
    else if (!strcmp(iter,"out")){
        pthread_mutex_lock(&out_config.mtx);
        if(out_config.stream){
            ret = out_config.stream->common.set_parameters(out_config.stream,strtok(NULL," "));
            printf("out set parameter ret %d\n",ret);
        }
        pthread_mutex_unlock(&out_config.mtx);
    }
    else {
        ret = phw_dev->set_parameters(phw_dev,iter);
        printf("dev set parameter ret %d\n",ret);
    }
    return ret;
}
static int stream_play_prepare(char * args)
{
    int32_t  ret = -1;
    char*    iter = args;
    int      stop = 1;

    uint32_t sample_rate      = out_config.config.sample_rate;
    uint32_t channel_mask     = out_config.config.channel_mask; 
    uint32_t format           = out_config.config.format;
    audio_devices_t device    = out_config.devices;
    audio_output_flags_t flag = out_config.flags; 

    
    printf("Play cmd %s\n",args);

    while(iter=strtok(iter," =")){
        printf("opt:%s\n",iter);
        if(!strncmp(iter,"simple",sizeof("simple")-1)){
            ret = open("/data/play_44.1_2CH_16B_PCM.pcm",O_RDONLY);
            if(ret<0){
                printf("Open file failed %d,%s\n",ret,strerror(errno));
                return -1;
            }
            pthread_mutex_lock(&out_config.mtx);
            close(out_config.fd);
            out_config.fd = ret;
            pthread_mutex_unlock(&out_config.mtx);
            sample_rate   = 44100;
            channel_mask  = AUDIO_CHANNEL_OUT_FRONT_RIGHT | AUDIO_CHANNEL_OUT_FRONT_LEFT;
            format        = AUDIO_FORMAT_PCM_16_BIT; 
            device        = AUDIO_DEVICE_OUT_SPEAKER;
            flag          = AUDIO_OUTPUT_FLAG_PRIMARY; 
        }
        else if(!strncmp(iter,"sample_rate",sizeof("sample_rate")-1)){
            sample_rate = strtol(strtok(NULL," ="),NULL,0);
            printf("new sample rate %d\n",sample_rate);
        }
        else if(!strncmp(iter,"channel",sizeof("channel")-1)){
            char *schannel =strtok(NULL," =");
            if(schannel){
                channel_mask = 0; 
                if(strstr(schannel,"r"))
                    channel_mask |= AUDIO_CHANNEL_OUT_FRONT_RIGHT;
                if(strstr(schannel,"l"))
                    channel_mask |= AUDIO_CHANNEL_OUT_FRONT_LEFT;
            }
        }
        else if(!strncmp(iter,"stop",sizeof("stop")-1)){
             stop = 1;
        }
        else if(!strncmp(iter,"start",sizeof("start")-1)){
             stop = 0; 
        }
        else if(!strncmp(iter,"device",sizeof("device")-1)){
             char * sdevice = strtok(NULL," =");
             if(sdevice){
                device = AUDIO_DEVICE_NONE;
                if(strstr(sdevice,"speaker"))
                    device |= AUDIO_DEVICE_OUT_SPEAKER;
                if(strstr(sdevice,"earpiece"))
                    device |= AUDIO_DEVICE_OUT_EARPIECE;
                if(strstr(sdevice,"headset"))
                    device |= AUDIO_DEVICE_OUT_WIRED_HEADSET;
                if(strstr(sdevice,"bt_sco"))
                    device |= AUDIO_DEVICE_OUT_ALL_SCO;
             }
        }
        else if(!strncmp(iter,"file",sizeof("file")-1)){
            char * source_file = strtok(NULL," =");;
            do{
                if(access(source_file,R_OK|F_OK)){
                    printf("access file %s failed %s\n",source_file,strerror(errno));
                    break;
                }
                ret = open(source_file,O_RDONLY);
                if(ret<0)printf("Open %s failed ,ret %d,%s\n",source_file,ret,strerror(errno));
            }while(0);
            
            if(ret >= 0){
                pthread_mutex_lock(&out_config.mtx);
                close(out_config.fd);
                out_config.fd = ret;
                pthread_mutex_unlock(&out_config.mtx);
            }
        }
        else{
            printf("Unknown opt: %s\n",iter);
        }
        iter = NULL;
    }

    pthread_mutex_lock(&out_config.mtx);
    if(out_config.config.sample_rate  != sample_rate   ||
       out_config.config.channel_mask != channel_mask  ||
       out_config.config.format       != format        ||
       out_config.devices             != device        ||
       out_config.flags               != flag)
    { 
        out_config.config.sample_rate = sample_rate;
        out_config.config.channel_mask= channel_mask;
        out_config.config.format      = format;
        out_config.devices            = device;
        out_config.flags              = flag;
        out_config.changed            = true;
    }
    
    if(out_config.stop != stop){
        out_config.stop = stop;
    }
    pthread_cond_signal(&out_config.cond);
    pthread_mutex_unlock(&out_config.mtx);
    return 0;
}
static int stream_record_prepare(char *args)
{
    
    char* iter            = args;
    int   stop            = 1;
    int32_t  ret;
    
    uint32_t sample_rate     = in_config.config.sample_rate;
    uint32_t channel_mask    = in_config.config.channel_mask;; 
    uint32_t format          = in_config.config.format;
    audio_input_flags_t flag = in_config.flags;
    audio_source_t source    = in_config.source;
    audio_devices_t  device  = in_config.devices;

    printf("Record sub cmd %s\n",args);
    
    while(iter=strtok(iter," =")){
        printf("record opt %s\n",iter);
        
        if(!strncmp(iter,"simple",sizeof("simple")-1)){
            ret = open("/data/record_44.1_2CH_16B_PCM.pcm",O_WRONLY|O_CREAT,0777);
            if(ret<0){
                printf("Open file failed %d,%s\n",ret,strerror(errno));
                return -1;
            }
            pthread_mutex_lock(&in_config.mtx);
            close(in_config.fd);
            in_config.fd = ret;
            pthread_mutex_unlock(&in_config.mtx);
            sample_rate   = 44100;
            channel_mask  = AUDIO_CHANNEL_OUT_FRONT_RIGHT | AUDIO_CHANNEL_OUT_FRONT_LEFT;
            format        = AUDIO_FORMAT_PCM_16_BIT;
            flag          = AUDIO_INPUT_FLAG_RAW;
            source        = AUDIO_SOURCE_MIC;

        }
        else if(!strncmp(iter,"sample_rate",sizeof("sample_rate")-1)){
            sample_rate = strtol(strtok(NULL," ="),NULL,0);
            printf("new sample rate %d\n",sample_rate);
        }
        else if(!strncmp(iter,"channel",sizeof("channel")-1)){
            char *schannel = strtok(NULL," =");
            if(schannel){
                channel_mask = 0; 
                if(strstr(schannel,"r"))
                    channel_mask |= AUDIO_CHANNEL_OUT_FRONT_RIGHT;
                if(strstr(schannel,"l"))
                    channel_mask |= AUDIO_CHANNEL_OUT_FRONT_LEFT;
            }
        }
        else if(!strncmp(iter,"source",sizeof("source")-1)){
            char *ssource = strtok(iter," =");
            if(ssource){
                source = 0;
                if(strstr(ssource,"mic"))
                    source |= AUDIO_SOURCE_MIC;
                if(strstr(ssource,"fm"))
                    source |= AUDIO_SOURCE_FM_TUNER;
            }
        }
        else if(!strncmp(iter,"device",sizeof("device")-1)){
             char * sdevice = strtok(NULL," =");
             if(sdevice){
                device = AUDIO_DEVICE_NONE;
                if(strstr(sdevice,"mic"))
                    device |= AUDIO_DEVICE_IN_BUILTIN_MIC;
                if(strstr(sdevice,"headmic"))
                    device |= AUDIO_DEVICE_IN_WIRED_HEADSET;
                if(strstr(sdevice,"bt_sco"))
                    device |= AUDIO_DEVICE_IN_BLUETOOTH_SCO_HEADSET;
             }
        }
        else if(!strncmp(iter,"stop",sizeof("stop")-1)){
            stop = 1;
        }
        else if(!strncmp(iter,"start",sizeof("start")-1)){
            stop = 0;
        }
        else if(!strncmp(iter,"file",sizeof("file")-1)){
            char * dst_file = strtok(NULL," =");
            do{
                ret = open(dst_file,O_WRONLY|O_CREAT,0777);
                if(ret<0)
                    printf("Open %s failed ,ret %d,%s\n",dst_file,ret,strerror(errno));
            }while(0);
            
            if(ret >= 0){
                pthread_mutex_lock(&in_config.mtx);
                close(in_config.fd);
                in_config.fd = ret;
                pthread_mutex_unlock(&in_config.mtx);
            }
        }
        else{
            printf("Unknow sub cmd %s\n",iter);
        }
        iter = NULL;
    }

    pthread_mutex_lock(&in_config.mtx);
    if(in_config.config.sample_rate  != sample_rate  ||
       in_config.config.channel_mask != channel_mask ||
       in_config.config.format       != format       ||
       in_config.flags               != flag         ||
       in_config.source              != source)
    { 
        in_config.config.sample_rate  = sample_rate;
        in_config.config.channel_mask = channel_mask;
        in_config.config.format       = format;
        in_config.flags               = flag;
        in_config.source              = source;
        in_config.changed             = true;
    }
    
    if(in_config.stop != stop){
        in_config.stop = stop;
    }
    pthread_cond_signal(&in_config.cond);
    pthread_mutex_unlock(&in_config.mtx);
    return 0;
}

static void * stream_out(void* args __unused)
{
   int32_t  ret;
   int32_t  bsize = 0;
   int8_t*  buf = NULL;
   
   printf("\nPlayback thread ready tid(%d),pid(%d)\n",gettid(),getpid());

   while(!closed){
        pthread_mutex_lock(&out_config.mtx);

        if(out_config.stop){
            if(out_config.stream){
                out_config.stream->common.standby(out_config.stream);
            }
            pthread_cond_wait(&out_config.cond,&out_config.mtx);
        }
        if(out_config.changed || !out_config.stream){
            if(out_config.stream){
                phw_dev->close_output_stream(phw_dev,out_config.stream);
                out_config.stream = NULL;
            }
            ret = phw_dev->open_output_stream(phw_dev,
                                                  out_config.handle++,
                                                  out_config.devices,
                                                  out_config.flags,
                                                  &out_config.config,
                                                  &out_config.stream,
                                                  NULL);
            if(!ret){
                out_config.changed = 0;
                bsize = out_config.stream->common.get_buffer_size(out_config.stream);
                buf = realloc(buf,bsize);
                printf("\nNewly output:\n"
                       "sample_rate %d,channel_mask %#x,format %#x\n"
                       "stream buffer size %d\n",
                        out_config.config.sample_rate,
                        out_config.config.channel_mask,
                        out_config.config.format,
                        bsize);
            }else{
                printf("\nOpen failed %d try again\n",ret);
                pthread_mutex_unlock(&out_config.mtx);
                continue;
            }
        }
        if(!out_config.stop)printf("Start to playback\n");
        pthread_mutex_unlock(&out_config.mtx);
        while(!out_config.stop){
            pthread_mutex_lock(&out_config.mtx);
            ret = read(out_config.fd,buf,bsize);
            pthread_mutex_unlock(&out_config.mtx);
            if(ret < 0){
                printf("read failed %d,%s,seek to start\n",ret,strerror(errno));
                lseek(out_config.fd,0,SEEK_SET);
                continue;
            }
            ret = out_config.stream->write(out_config.stream,buf,ret);
        }
    
    }
    if(out_config.stream)phw_dev->close_output_stream(phw_dev,out_config.stream);
    return 0;
}
static void * stream_in(void* args __unused)
{
   int32_t ret;
   size_t   bsize = 0;
   int8_t*  buf = NULL;

   printf("\nRecord thread ready tid(%d),pid(%d)\n",gettid(),getpid());
   while(!closed){
        pthread_mutex_lock(&in_config.mtx);
        
        if(in_config.stop){
            if(in_config.stream){
                in_config.stream->common.standby(in_config.stream);
            }
            pthread_cond_wait(&in_config.cond,&in_config.mtx);
        }

        if(in_config.changed ||!in_config.stream){
            if(in_config.stream){
                phw_dev->close_input_stream(phw_dev,in_config.stream);
                in_config.stream = NULL;
            }
            ret = phw_dev->open_input_stream(phw_dev,
                                                  in_config.handle++,
                                                  in_config.devices,
                                                  &in_config.config,
                                                  &in_config.stream,
                                                  in_config.flags,
                                                  NULL,
                                                  in_config.source);
            if(!ret){
                in_config.changed = 0;
                bsize = in_config.stream->common.get_buffer_size(in_config.stream);
                buf = realloc(buf,bsize);
                printf("\nNewly opened input stream:\n"
                        "sample_rate %d,channel_mask %#x,format %#x\n"
                        "device %#x\n"
                        "buffer size %d\n",
                        in_config.config.sample_rate,
                        in_config.config.channel_mask,
                        in_config.config.format,
                        bsize);
            }else{
                printf("open failed %d try again\n",ret);
                pthread_mutex_unlock(&in_config.mtx);
                continue;
            }
        }
        if(!in_config.stop)printf("Start to record\n");
        pthread_mutex_unlock(&in_config.mtx);
        while(!in_config.stop){
            ret = in_config.stream->read(in_config.stream,buf,bsize);
            pthread_mutex_lock(&in_config.mtx);
            ret = write(in_config.fd,buf,ret);
            pthread_mutex_unlock(&in_config.mtx);
            if(ret < 0){
                printf("write failed %d,%s\n",ret,strerror(errno));
                continue;
            }
            static int recorded = 0;
            recorded += ret;
            if((recorded + ret)/(1024*1024)-(recorded)/(1024*1024)){
                printf("Recorded size %d MB\n",recorded/(1024*1024)+1);
            }
        }
    
    }
    if(in_config.stream)phw_dev->close_input_stream(phw_dev,in_config.stream);
    return 0;
}

void usage(){
    printf("+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"
           "Usage:not handle cmdline arguments\n"
           "receive options in any order\n"
           "set [in|out] parameters;like routing=2\n"
           "get [in|out] parameters]\n"
           "play simple start device=speaker[,earpiece][,headset][,bt_sco]\n"
           "play sample_rate=44100 channel=l[,r] file=/data/xxx.pcm\n"
           "play stop\n"
           "record simple start\n"
           "record sample_rate=44100 source=mic[,fm] device=mic[,headmic][,bt_sco] channel=l[,r] file=/data/xxx.pcm\n"
           "record stop\n"
           "bye\n"
           "play simple = play sample_rate=44100 channel=l,r device=speaker file=/data/play_44.1_2CH_16B_PCM.pcm"
           "record simple = record sample_rate=44100 channel=l,r source=mic device=mic file=/data/record_44.1_2CH_16B_PCM.pcm"
           "mostly used parameters,routing=2,sprd_voip_start=1,FM_Volume=[1-15]\n"
           "+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n");
}

int main()
{
    pthread_attr_t attr;
    pthread_t pid[2];
    char* lib_path[] = {"/system/lib/hw",
                        "/system/lib64/hw",
                        "/vendor/lib64/hw",
                        "/vendor/lib/hw",
                        NULL};
    char full_name[256] = {0};
    char platform[20]  = {0};

    int  i = 0;
    int  ret;
    void *handle;

    if(ret = property_get("ro.board.platform", platform, "0")<0){
        printf("Unkown platform err:%d\n",ret);
        return -1;
    }

    while(lib_path[i]) {
        sprintf(full_name,"%s/%s%s%s",lib_path[i],"audio.primary.",platform,".so");
        if(!access(full_name,R_OK|F_OK))
            break;
        i++;
    }
    if(!lib_path[i]){
        printf("cannot find share library err:%d,%s\n",errno,strerror(errno));
        return -1;
    }
    

    handle = dlopen(full_name,RTLD_NOW);

    if (!handle) {
        printf("%s\n",dlerror());
        return -1;
    }
    p_module = dlsym(handle,HAL_MODULE_INFO_SYM_AS_STR);
    if(p_module == NULL){
        printf("%s\n",dlerror());
        return -1;
    }
    if(ret = audio_hw_device_open(p_module,&phw_dev) != 0){
        printf("open hal device failed %d\n",ret);
        return -1;
    }else{
        ret = phw_dev->init_check(phw_dev);
        printf("open hal device successfully %d\n",ret);
    }
    pthread_attr_init(&attr);
    
    pthread_create(&pid[0], &attr,
                stream_out,NULL);
    pthread_create(&pid[1], &attr,
                stream_in,NULL);
    /* catch ctrl-c to shutdown cleanly */
    signal(SIGINT, stream_close);

    usage();
    while(!closed){
        char* cmd_args = full_name;
        memset(cmd_args,0,sizeof(full_name));
        printf("waiting for new cmd:");
        fgets(cmd_args,sizeof(full_name)-1,stdin);
        char* sub_args = strchr(cmd_args,' ');
        char* nl = strchr(cmd_args,'\n');
        if(nl)*nl = '\0';
        if(!strncmp(cmd_args,"set",3)){
            stream_set_param(sub_args);
        }
        else if(!strncmp(cmd_args,"play",4)){
            stream_play_prepare(sub_args);
        }
        else if(!strncmp(cmd_args,"record",6)){
            stream_record_prepare(sub_args);
        }
        else if(!strncmp(cmd_args,"bye",3)){
            pthread_kill(pid[0],9);
            pthread_kill(pid[1],9);
            closed = 1;
        }
        else{
            usage();
        }
    }
    dlclose(handle);
    pthread_join(pid[0],NULL);
    pthread_join(pid[1],NULL);

    return 0;
}
