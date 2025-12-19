# docker-maven插件

```xml
<!-- docker 插件 -->
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <version>0.48.0</version>
</plugin>
```
该插件用于在Maven构建过程中集成Docker操作，例如构建Docker镜像、推送镜像到仓库等。

## xml配置示例

```xml
<!-- docker 插件 -->
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <version>0.48.0</version>
    <!-- 全局配置 -->
    <configuration>
        <!-- 这一部分是为了实现对远程docker容器的控制 -->
        <!-- docker主机地址,用于完成docker各项功能 -->
        <dockerHost>${docker.dockerHost}</dockerHost>
        <!-- docker远程访问所需证书地址 -->
        <certPath>${docker.certPath}</certPath>

        <!-- 镜像相关配置,支持多镜像 -->
        <images>
            <!-- 镜像配置 -->
            <image>
                <!-- 镜像名(含版本号) -->
                <name>${project.build.finalName}:${project.version}</name>
                <!-- 别名 -->
                <alias>${project.build.finalName}</alias>
                <!-- 镜像构建配置 -->
                <build>
                    <!-- 使用 Dockerfile -->
                    <dockerFile>${project.basedir}/Dockerfile</dockerFile>
                    <contextDir>${project.basedir}</contextDir>
                    <!-- 构建参数 -->
                    <args>
                        <JAR_FILE>${project.build.finalName}</JAR_FILE>
                    </args>
                </build>

                <!-- 容器运行配置 -->
                <run>
                    <!-- 环境变量配置 -->
                    <env>
                        <SPRING_PROFILES_ACTIVE>prod</SPRING_PROFILES_ACTIVE>
                        <JAVA_OPTS>-Xms256m -Xmx512m</JAVA_OPTS>
                    </env>
                    <!-- 配置运行时容器命名策略为:别名 -->
                    <containerNamePattern>%a</containerNamePattern>
                    <!-- 网络配置 -->
                    <network>
                        <!-- 宿主机网络 -->
                        <mode>host</mode>
                        <!-- 桥接网络 -->
                        <!--<mode>bridge</mode>-->
                        <!-- 自定义网络 -->
                        <!--<mode>custom</mode>
                        <name>my-network</name>-->
                    </network>
                    <!-- 端口配置 -->
                    <!--<ports>-->
                    <!--    <port>8501:8501</port>-->
                    <!--</ports>-->
                    <!-- 数据卷配置 -->
                    <volumes>
                        <bind>
                            <volume>/opt/${project.build.finalName}/logs:/app/logs</volume>
                        </bind>
                    </volumes>
                    <!-- 容器重启策略 -->
                    <restartPolicy>
                        <name>always</name>
                    </restartPolicy>
                    <!-- 内存限制(单位字节) -->
                    <memory>786432000</memory>
                    <memorySwap>786432000</memorySwap>
                </run>
            </image>
        </images>
    </configuration>

    <!-- 插件执行配置,在package阶段执行 -->
    <executions>
        <execution>
            <id>docker-deploy</id>
            <phase>package</phase>
            <goals>
                <goal>stop</goal>
                <goal>remove</goal>
                <goal>build</goal>
                <goal>start</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

# 配置docker tls

## Step 1：准备目录

```
mkdir -p /etc/docker/certs
cd /etc/docker/certs
```

------

## Step 2：生成 CA

```
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 3650 \
  -key ca-key.pem -sha256 -out ca.pem
```

✔ 只做一次

------

## Step 3：生成 Server 证书（重点）

```
openssl genrsa -out server-key.pem 4096

openssl req -subj "/CN=192.168.10.20" \
  -new -key server-key.pem -out server.csr
```

### SAN（非常重要）

```
cat > extfile.cnf <<EOF
subjectAltName = IP:192.168.10.20,IP:127.0.0.1
extendedKeyUsage = serverAuth
EOF
openssl x509 -req -days 3650 -sha256 \
  -in server.csr \
  -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem -extfile extfile.cnf
```

------

## Step 4：生成 Client 证书

```
openssl genrsa -out client-key.pem 4096

openssl req -subj "/CN=docker-client" \
  -new -key client-key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile-client.cnf
openssl x509 -req -days 3650 -sha256 \
  -in client.csr \
  -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out client-cert.pem -extfile extfile-client.cnf
```

------

## Step 5：权限整理

```
chmod 0400 ca-key.pem server-key.pem
chmod 0444 ca.pem server-cert.pem
```

客户端用的证书 **稍后拷贝，不留私钥在服务器**

------

## Step 6：配置 Docker（systemd 正确方式）

### 创建 override 文件

```
mkdir -p /etc/systemd/system/docker.service.d
vim /etc/systemd/system/docker.service.d/override.conf
```

内容：

```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd \
  --tlsverify \
  --tlscacert=/etc/docker/certs/ca.pem \
  --tlscert=/etc/docker/certs/server-cert.pem \
  --tlskey=/etc/docker/certs/server-key.pem \
  -H unix:///var/run/docker.sock \
  -H tcp://192.168.5.24:12581
```

------

## Step 7：重载并重启

```
systemctl daemon-reload
systemctl restart docker
```

确认：

```
systemctl status docker
```

------

## Step 8：拷贝客户端证书（只拷 3 个）

```
scp /etc/docker/certs/ca.pem user@client:/opt/docker/certs/
scp /etc/docker/certs/client-cert.pem user@client:/opt/docker/certs/
scp /etc/docker/certs/client-key.pem user@client:/opt/docker/certs/
```

（你也可以在生成后直接放到安全位置）

------

## Step 9：本地验证 Docker TLS

```
docker \
  --tlsverify \
  --tlscacert=ca.pem \
  --tlscert=client-cert.pem \
  --tlskey=client-key.pem \
  -H tcp://192.168.10.20:2376 info
```
如果看到 Docker 信息，说明配置成功。
