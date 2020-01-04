//
//  zhouhua.c
//  myTestTCP
//
//  Created by zhouhua on 2019/12/21.
//  Copyright © 2019 zhouhua. All rights reserved.
//

#include <stdio.h>

//
//  zhouhua.c
//  myStory
//
//  Created by zhouhua on 2019/12/21.
//  Copyright © 2019 zhouhua. All rights reserved.
//

#include <stdio.h>


int zhouhua(int a,int b)
{
    return a+b;
    
}


#include<stdlib.h>
#include<string.h>
#include<sys/socket.h>
#include<sys/types.h>
#include<netinet/in.h>
#include<netdb.h>
#include<errno.h>
#include<unistd.h>
#include<arpa/inet.h>


#define SEND_BUF_SIZE 400
int listenfd = 0, connfd = 0;
int startServer(int port)
{
    printf("lets bidn %d\n",port);
    struct sockaddr_in serv_addr, peer_addr;
    memset(&serv_addr, '0', sizeof(serv_addr));
    memset(&peer_addr, '0', sizeof(peer_addr));
    serv_addr.sin_family      = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port        = htons(port);
 
    
    //创建socket
    listenfd = socket(AF_INET, SOCK_STREAM, 0);
    if (listenfd == -1) {
        printf("Error. failed to create socket!\n");
        return -1;
    }
    int bReuseaddr=1;
    setsockopt(listenfd,SOL_SOCKET ,SO_REUSEADDR,(const char*)&serv_addr,sizeof(bReuseaddr));
    //绑定socket
    int ret = bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
    if (ret < 0) {
        printf("Error. failed to bind! %d\n",ret);
        perror("reason:");
        return -1;
    }
    //监听socket
    if (listen(listenfd, 10) < 0) {
        printf("Error. failed to listen!\n");
        return -1;
    }
 
    char sendBuff[SEND_BUF_SIZE] = {0};
    const char *src = "SERVER====";
    strncpy(sendBuff, src, SEND_BUF_SIZE - 1);
    sendBuff[SEND_BUF_SIZE - 1] = '\0';
 
    int size = sizeof(struct sockaddr_in);
    while(1){
        connfd = accept(listenfd, (struct sockaddr*)&peer_addr, (socklen_t*)&size);
        if (connfd < 0) {
           printf("Error. accept failed!\n");
           return -1;
        }
        //连上之后，打印客户端的ip
        printf("has a clinet connet ip %s\n",inet_ntoa(peer_addr.sin_addr));
    }
    /*
    while(1)
    {
        //等等客户端连接
        connfd = accept(listenfd, (struct sockaddr*)&peer_addr, (socklen_t*)&size);
        if (connfd < 0) {
            printf("Error. accept failed!\n");
            return -1;
        }
        //连上之后，打印客户端的ip
        printf("has a clinet connet ip %s\n",inet_ntoa(peer_addr.sin_addr));
 
        //向客户端发送信息
        for (int i = 0; i < 200; ++i) {
            write(connfd, sendBuff, strlen(sendBuff));
        }
 
        int n = 0;
        char recvBuff[1024];
        while ((n = read(connfd, recvBuff, sizeof(recvBuff)-1)) > 0)
        {
            printf("%d\n", n);
            recvBuff[n] = 0;
            printf("%s\n", recvBuff);
        }
 
        close(connfd);
        sleep(1);
    }*/
}

int recvStuck(unsigned char* buf,int num)
{
    int cnt = 0;
    int n;
    while(connfd == 0);
    static int i=0;
    while(1)
    {
        i++;
        n = read(connfd, &(buf[cnt]), num-cnt);
        printf("recv %d %d\n", n,i);
        if (n <= 0) {printf(",,,,,,,,,\n\n\n\n");break;};
        cnt+=n;
        if(cnt == num)break;
         
    }
    return cnt;
}
