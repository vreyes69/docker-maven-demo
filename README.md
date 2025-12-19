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