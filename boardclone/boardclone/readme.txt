

命令介绍：
-c 执行的是将参考board复制到diffpack下的new和old文件夹，并对new目录下进行board关键字的修改；
-t  是指将修改好的new文件夹覆盖到原来工程；
-a 是将上面两个合在一起；
-r 对工程中board名进行重新命名；
-s 是指创建子工程。


创建工程：
（比如在9853i_1h10 的基础上创建9853i_2d10）

1、将文件夹boardclone放到工程的vendor目录下；

2、修改权限chmod 777 boardmaker.sh

3、执行脚本./boardmaker.sh -c  9853i_1h10  9853i_2d10  
    
9853i_1h10是参考board名字的关键字，注意关键字前面不要加sp；
9853i_2d10是新建board名字的关键字；
参考board要在device/sprd/ 下能够找到；

4、再将修改后的diffpack/new文件覆盖到原工程，命令如下：             
  ./boardmaker.sh -t 9853i_1h10 


创建sub board
（比如在sp9853i_1h10的基础上创建sp9853i_1h10_vmm）

1、输入命令如下：
./boardmaker.sh -c sp9853i_1h10 sp9853i_1h10_vmm

2、对比diffpack文件夹下的old和new两个文件夹，需要自己调整下

3、再将修改后的diffpack/new文件覆盖到原工程，命令如下：
./boardmaker.sh -t sp9853i_1h10

