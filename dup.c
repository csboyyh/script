#include<stdio.h>
int main(){
    FILE *fd_i = fopen(argv[1],"r");
    FILE *fd_o = fopen(argv[1],"w+");
    int count = strtol(argv[2]);
    int size  = fseek(fd_i,0,SEEK_END);
    ftruncate(fd_o,count*size);
    while(count--){
        fread(tmp,1,1024,fd_i);
        
    }
}
