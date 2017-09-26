#include<stdio.h>
int main(int argc,char *argv[]){
    if(argc < 3){
        printf("Usage: str_to_hex input_file outpue_file %d,%s\n",argc,argv[0]);
        return 1;
    }
    FILE * fd_i = fopen(argv[1],"r");
    FILE * fd_o = fopen(argv[2],"w+");
    if(fd_i == NULL || fd_o == NULL){
        printf("i %d,o %d\n",fd_i,fd_o);
    }
    unsigned char tmp[512] ={0};
    int  ret_size = fread(tmp,1,512,fd_i);
    int  index = 0;
    while(index <=  ret_size){
        char token;
        int shift = index % 2 ? 0 : 4;
        if(tmp[index]>='0' && tmp[index]<='9')
            token = '0';
        else if(tmp[index]>='a' && tmp[index]<='f')
            token = 'a' - 10;
        else if(tmp[index]>='A' && tmp[index]<='F')
            token = 'A' - 10;
        if(shift){
            tmp[index/2] = (tmp[index] - token)<<shift;
        }else{
            tmp[index/2] |= tmp[index] - token; 
        }
        if(++index == ret_size){
            fwrite(tmp,1,ret_size/2,fd_o);
            ret_size = fread(tmp,1,512,fd_i);
            index = 0;
        }
    }
    return 0;
}
