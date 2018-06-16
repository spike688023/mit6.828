
去我DigitalOcean 的 Node，建構環境好了：

sudo apt-get install qemu-user-static


ssh root@159.65.134.118

這個的作者，明確的說了， 它是為MIT OS 的課去弄的一個Image:
用play with docker 來跑看看吧
https://github.com/kmontg03/xv6-docker


Docker Hub 的格式為 UserName/Repo , 格式不對，傳不上去。

改名：
sudo docker tag myapp2:latest skychang/myapp:latest


push :

sudo docker push skychang/myapp
