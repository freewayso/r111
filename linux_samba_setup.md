# Linux Samba 安装配置指南

## 一、安装 Samba

### Ubuntu/Debian 系统
```bash
# 更新软件包列表
sudo apt update

# 安装 Samba
sudo apt install samba samba-common-bin -y

# 检查安装状态
sudo systemctl status smbd
```

### CentOS/RHEL/Rocky Linux 系统
```bash
# 安装 Samba
sudo yum install samba samba-client samba-common -y

# 或者在较新版本使用 dnf
sudo dnf install samba samba-client samba-common -y

# 启动 Samba 服务
sudo systemctl start smb
sudo systemctl enable smb

# 检查状态
sudo systemctl status smb
```

### Fedora 系统
```bash
# 安装 Samba
sudo dnf install samba -y

# 启动服务
sudo systemctl start smb nmb
sudo systemctl enable smb nmb
```

## 二、配置 Samba

### 1. 创建共享目录
```bash
# 创建共享目录（例如项目目录）
sudo mkdir -p /home/share/projects

# 设置权限
sudo chmod 777 /home/share/projects

# 或者更安全的方式：创建 Samba 用户组
sudo groupadd smbgroup
sudo chgrp smbgroup /home/share/projects
sudo chmod 2775 /home/share/projects
```

### 2. 备份原配置文件
```bash
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
```

### 3. 编辑 Samba 配置文件
```bash
sudo nano /etc/samba/smb.conf
# 或使用 vim
sudo vim /etc/samba/smb.conf
```

在文件末尾添加以下内容：

```ini
# 项目共享配置
[projects]
   comment = Project Files Share
   path = /home/share/projects
   browseable = yes
   writable = yes
   guest ok = no
   valid users = @smbgroup
   create mask = 0775
   directory mask = 0775

# 用户个人共享（可选）
[homes]
   comment = Home Directories
   browseable = no
   writable = yes
   valid users = %S
   create mask = 0700
   directory mask = 0700

# 公共共享（可选，不需要密码）
[public]
   comment = Public Share
   path = /home/share/public
   browseable = yes
   writable = yes
   guest ok = yes
   create mask = 0777
   directory mask = 0777
```

### 4. 创建 Samba 用户
```bash
# 首先需要是 Linux 系统用户
sudo useradd -M -s /sbin/nologin smbuser
# 或者使用现有用户

# 添加到 Samba 用户数据库
sudo smbpasswd -a smbuser
# 会提示输入 Samba 密码（可以与 Linux 密码不同）

# 启用用户
sudo smbpasswd -e smbuser

# 将用户添加到 smbgroup
sudo usermod -aG smbgroup smbuser
```

### 5. 测试配置文件
```bash
# 检查配置文件语法
testparm

# 如果没有错误，会显示有效配置
```

### 6. 重启 Samba 服务
```bash
# Ubuntu/Debian
sudo systemctl restart smbd
sudo systemctl restart nmbd

# CentOS/RHEL/Fedora
sudo systemctl restart smb
sudo systemctl restart nmb

# 设置开机自启
sudo systemctl enable smbd nmbd  # Ubuntu/Debian
sudo systemctl enable smb nmb    # CentOS/RHEL/Fedora
```

## 三、防火墙配置

### Ubuntu/Debian (UFW)
```bash
# 允许 Samba 通过防火墙
sudo ufw allow samba

# 或者手动指定端口
sudo ufw allow 137/udp
sudo ufw allow 138/udp
sudo ufw allow 139/tcp
sudo ufw allow 445/tcp

# 重载防火墙
sudo ufw reload
```

### CentOS/RHEL/Fedora (firewalld)
```bash
# 允许 Samba 服务
sudo firewall-cmd --permanent --add-service=samba
sudo firewall-cmd --reload

# 检查规则
sudo firewall-cmd --list-all
```

### 禁用防火墙（不推荐，仅用于测试）
```bash
# Ubuntu/Debian
sudo ufw disable

# CentOS/RHEL/Fedora
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

## 四、SELinux 配置（CentOS/RHEL/Fedora）

```bash
# 检查 SELinux 状态
getenforce

# 如果是 Enforcing，需要配置 SELinux
sudo setsebool -P samba_enable_home_dirs on
sudo setsebool -P samba_export_all_rw on

# 设置共享目录的 SELinux 上下文
sudo semanage fcontext -a -t samba_share_t "/home/share/projects(/.*)?"
sudo restorecon -Rv /home/share/projects

# 临时禁用 SELinux（不推荐，仅用于测试）
sudo setenforce 0
```

## 五、从 Windows 连接 Samba

### 方法 1：使用文件资源管理器
1. 打开文件资源管理器
2. 在地址栏输入：`\\Linux服务器IP\projects`
3. 例如：`\\192.168.1.100\projects`
4. 输入 Samba 用户名和密码

### 方法 2：映射网络驱动器
1. 右键点击"此电脑" -> "映射网络驱动器"
2. 选择驱动器号（如 Z:）
3. 文件夹输入：`\\192.168.1.100\projects`
4. 勾选"登录时重新连接"
5. 点击"完成"，输入凭据

### 方法 3：使用命令行
```cmd
# 映射网络驱动器
net use Z: \\192.168.1.100\projects /user:smbuser password

# 断开连接
net use Z: /delete
```

## 六、从 Linux 连接 Samba

```bash
# 安装 Samba 客户端
sudo apt install smbclient cifs-utils  # Ubuntu/Debian
sudo yum install samba-client cifs-utils  # CentOS/RHEL

# 列出共享
smbclient -L //192.168.1.100 -U smbuser

# 交互式访问
smbclient //192.168.1.100/projects -U smbuser

# 挂载到本地目录
sudo mkdir /mnt/samba
sudo mount -t cifs //192.168.1.100/projects /mnt/samba -o username=smbuser,password=yourpassword

# 永久挂载（编辑 /etc/fstab）
echo "//192.168.1.100/projects /mnt/samba cifs username=smbuser,password=yourpassword,iocharset=utf8 0 0" | sudo tee -a /etc/fstab
```

## 七、常用管理命令

```bash
# 查看 Samba 用户列表
sudo pdbedit -L

# 查看详细信息
sudo pdbedit -L -v

# 删除 Samba 用户
sudo smbpasswd -x username

# 禁用用户
sudo smbpasswd -d username

# 启用用户
sudo smbpasswd -e username

# 查看当前连接
sudo smbstatus

# 查看共享列表
smbclient -L localhost

# 查看 Samba 日志
sudo tail -f /var/log/samba/log.smbd
```

## 八、常见问题排查

### 1. 无法连接
```bash
# 检查服务状态
sudo systemctl status smbd nmbd

# 检查监听端口
sudo netstat -tulpn | grep -E "137|138|139|445"
# 或
sudo ss -tulpn | grep -E "137|138|139|445"

# 检查配置
testparm
```

### 2. 权限问题
```bash
# 检查目录权限
ls -la /home/share/projects

# 修复权限
sudo chmod -R 775 /home/share/projects
sudo chown -R nobody:smbgroup /home/share/projects
```

### 3. 密码问题
```bash
# 重置 Samba 密码
sudo smbpasswd -a username
```

### 4. 查看日志
```bash
# Samba 日志位置
sudo tail -f /var/log/samba/log.smbd
sudo tail -f /var/log/samba/log.nmbd

# 系统日志
sudo journalctl -u smbd -f
```

## 九、性能优化配置

在 `/etc/samba/smb.conf` 的 `[global]` 部分添加：

```ini
[global]
   # 性能优化
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
   read raw = yes
   write raw = yes
   max xmit = 65535
   dead time = 15
   getwd cache = yes
   
   # 日志设置
   log level = 1
   max log size = 1000
   
   # 字符集（支持中文）
   unix charset = UTF-8
   dos charset = CP936
```

## 十、安全建议

1. **使用强密码**：为 Samba 用户设置复杂密码
2. **限制访问**：使用 `valid users` 限制访问用户
3. **禁用 guest**：生产环境建议设置 `guest ok = no`
4. **使用防火墙**：只允许信任的 IP 访问
5. **定期更新**：保持 Samba 版本更新
6. **最小权限**：只给必要的读写权限

```ini
# 示例：限制特定 IP 访问
[projects]
   hosts allow = 192.168.1.0/24 127.0.0.1
   hosts deny = all
```

## 快速配置脚本

可以使用以下脚本快速配置 Samba：

```bash
#!/bin/bash
# quick_samba_setup.sh

# 安装 Samba
sudo apt update && sudo apt install samba -y

# 创建共享目录
sudo mkdir -p /home/share/projects
sudo chmod 777 /home/share/projects

# 创建用户
read -p "输入 Samba 用户名: " username
sudo useradd -M -s /sbin/nologin $username
sudo smbpasswd -a $username

# 添加共享配置
cat << EOF | sudo tee -a /etc/samba/smb.conf

[projects]
   comment = Project Share
   path = /home/share/projects
   browseable = yes
   writable = yes
   guest ok = no
   valid users = $username
   create mask = 0775
   directory mask = 0775
EOF

# 重启服务
sudo systemctl restart smbd nmbd
sudo systemctl enable smbd nmbd

# 配置防火墙
sudo ufw allow samba

echo "Samba 配置完成！"
echo "访问地址：\\\\$(hostname -I | awk '{print $1}')\\projects"
```

使用方法：
```bash
chmod +x quick_samba_setup.sh
sudo ./quick_samba_setup.sh
```

