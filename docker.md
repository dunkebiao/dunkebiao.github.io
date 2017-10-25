### 安装&启动
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum clean all
sudo yum install -y docker-ce
sudo systemctl start docker
```

### 配置国内镜像
```
sudo cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sudo sed -i "s|ExecStart=/usr/bin/dockerd|ExecStart=/usr/bin/dockerd --registry-mirror=https://p7p1xpxw.mirror.aliyuncs.com|g" /lib/systemd/system/docker.service
```

### 搜索镜像
```
sudo docker search centos:7
```

### 下载镜像
```
sudo docker pull centos:7
```

### 查看镜像
```
sudo docker images
```

### 查看镜像详细信息
```
sudo docker inspect
```

### 删除镜像
```
sudo docker rmi [centos:7] [ID]
```

### 创建容器
```
sudo docker create -it centos:7 /bin/bash 
```

### 创建并启动容器
```
sudo docker run -d -t -i -—name test centos:7 /bin/bash
sudo docker run -it -v /local:/docker contos:7
sudo docker run -it --volumes-from ID contos:7
```
    -t 让Docker分配一个伪终端,并绑定到容器的标准输入上.
    -i 则让容器的标准输入保持打开.
    -d 守护进程
    —name 设置容器别名
    -P 端口随机映射到宿主机
    -p 8080:80 端口映射到宿主机
    -v 加载数据卷
    —volumes-from 加载数据卷容器

### 查看容器
```
sudo docker ps [-a]
```

### 进入容器
```
sudo docker attach ID
sudo docker exec -it ID /bin/bash
```

### 获取容器内输出信息
```
sudo docker logs ID
```

### 终止容器
```
sudo docker stop ID
```

### 启动已停止的容器
```
sudo docker start ID
```

### 重启容器
```
sudo docker restart ID
```

### 删除容器
-f 强行终止并删除一个运行中的容器
-l 删除容器的连接,但保留容器
-v 删除容器挂载的数据卷
```
sudo docker rm [-f -l -v] ID
```

### 导出容器快照到本地
```
sudo docker export ID > centos_7.tar
```

### 从容器快照文件中再导入为镜像
```
cat centos_7.tar | docker import - test/centos_a:v1.0
```

### 保存镜像到文件
```
sudo docker save -o centos.6.tar centos:6
```

### 载入镜像文件
```
sudo docker load --input centos.6.tar
```

### 给容器目录添加selinux特权
```
chcon -Rt svirt_sandbox_file_t    /dir
```

### Mac 映射2375端口
```
brew install socat
socat -d TCP-LISTEN:2375,reuseaddr,fork UNIX:/var/run/docker.sock
```
