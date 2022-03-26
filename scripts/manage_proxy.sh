#!/bin/bash
[[ $(id -u) != 0 ]] && echo -e "請在Root用戶下運行安裝該腳本" && exit 1

cmd="apt-get"
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
    if [[ $(command -v yum) ]]; then
        cmd="yum"
    fi
else
    echo "這個安裝腳本不支持你的系統" && exit 1
fi


install(){
    if [ -d "/root/BenzMinerProxy" ]; then
        echo -e "檢測到您已安裝BenzMinerProxy，請勿重複安裝，如您確認您未安裝請使用rm -rf /root/BenzMinerProxy指令" && exit 1
    fi
    if screen -list | grep -q "BenzMinerProxy"; then
        echo -e "檢測到您的BenzMinerProxy已啟動，請勿重複安裝" && exit 1
    fi

    $cmd update -y
    $cmd install wget screen -y
    
    mkdir /root/BenzMinerProxy
    wget https://cdn.jsdelivr.net/gh/BenzMP/BenzMP@main/others/cert.tar.gz -O /root/BenzMinerProxy/cert.tar.gz --no-check-certificate
    tar -zxvf /root/BenzMinerProxy/cert.tar.gz -C /root/BenzMinerProxy
    wget https://cdn.jsdelivr.net/gh/BenzMP/BenzMP@main/scripts/run.sh -O /root/BenzMinerProxy/run.sh --no-check-certificate
    chmod 777 /root/BenzMinerProxy/run.sh

    wget https://cdn.jsdelivr.net/gh/BenzMP/BenzMP@main/release/BenzMinerProxy_linux999pro.tar -O /root/BenzMinerProxy_linux999pro.tar --no-check-certificate
    tar -zxvf /root/BenzMinerProxy_linux999pro.tar -C /root/BenzMinerProxy
    chmod 777 /root/BenzMinerProxy/BenzMinerProxy

    screen -dmS BenzMinerProxy
    sleep 0.2s
    screen -r BenzMinerProxy -p 0 -X stuff "cd /root/BenzMinerProxy"
    screen -r BenzMinerProxy -p 0 -X stuff $'\n'
    screen -r BenzMinerProxy -p 0 -X stuff "./run.sh"
    screen -r BenzMinerProxy -p 0 -X stuff $'\n'

    sleep 2s
    echo "BenzMinerProxy V1.3.9已經安裝到/root/BenzMinerProxy"
    cat /root/BenzMinerProxy/pwd.txt
    echo ""
    echo "您可以使用指令screen -r BenzMinerProxy查看程式輸出"
}


uninstall(){
    read -p "您確認您是否刪除BenzMinerProxy)[yes/no]：" flag
    if [ -z $flag ];then
         echo "您未正確輸入" && exit 1
    else
        if [ "$flag" = "yes" -o "$flag" = "ye" -o "$flag" = "y" ];then
            screen -X -S BenzMinerProxy quit
            rm -rf /root/BenzMinerProxy
            echo "BenzMinerProxy已成功從您的伺服器上卸載"
        fi
    fi
}



start(){
    if screen -list | grep -q "BenzMinerProxy"; then
        echo -e "檢測到您的BenzMinerProxy已啟動，請勿重複啟動" && exit 1
    fi
    
    screen -dmS BenzMinerProxy
    sleep 0.2s
    screen -r BenzMinerProxy -p 0 -X stuff "cd /root/BenzMinerProxy"
    screen -r BenzMinerProxy -p 0 -X stuff $'\n'
    screen -r BenzMinerProxy -p 0 -X stuff "./run.sh"
    screen -r BenzMinerProxy -p 0 -X stuff $'\n'

    echo "BenzMinerProxy已啟動"
    echo "您可以使用指令screen -r BenzMinerProxy查看程式輸出"
}


restart(){
    if screen -list | grep -q "BenzMinerProxy"; then
        screen -X -S BenzMinerProxy quit
    fi
    
    screen -dmS BenzMinerProxy
    sleep 0.2s
    screen -r BenzMinerProxy -p 0 -X stuff "cd /root/BenzMinerProxy"
    screen -r BenzMinerProxy -p 0 -X stuff $'\n'
    screen -r BenzMinerProxy -p 0 -X stuff "./run.sh"
    screen -r BenzMinerProxy -p 0 -X stuff $'\n'

    echo "BenzMinerProxy 已經重新啟動"
    echo "您可以使用指令screen -r BenzMinerProxy查看程式輸出"
}


stop(){
    screen -X -S BenzMinerProxy quit
    echo "BenzMinerProxy 已停止"
}


change_limit(){
    if grep -q "1000000" "/etc/profile"; then
        echo -n "您的系统连接数限制可能已修改，当前连接限制："
        ulimit -n
        exit
    fi

    cat >> /etc/sysctl.conf <<-EOF

fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100

net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768

# forward ipv4
# net.ipv4.ip_forward = 1
EOF

    cat >> /etc/security/limits.conf <<-EOF
*               soft    nofile          1000000
*               hard    nofile          1000000
EOF

    echo "ulimit -SHn 1000000" >> /etc/profile
    source /etc/profile

    echo "系统连接数限制已修改，手动reboot重启下系统即可生效"
}


check_limit(){
    echo -n "您的系统当前连接限制："
    ulimit -n
}


echo "======================================================="
echo "BenzMinerProxy 一鍵腳本，脚本默认安装到/root/BenzMinerProxy"
echo "                                   腳本版本：V999pro"
echo "  1、安  装"
echo "  2、卸  载"
echo "  4、启  动"
echo "  5、重  启"
echo "  6、停  止"
echo "  7、一键解除Linux连接数限制(需手动重启系统生效)"
echo "  8、查看当前系统连接数限制"
echo "======================================================="
read -p "$(echo -e "請選擇[1-8]：")" choose
case $choose in
    1)
        install
        ;;
    2)
        uninstall
        ;;
    3)
        update
        ;;
    4)
        start
        ;;
    5)
        restart
        ;;
    6)
        stop
        ;;
    7)
        change_limit
        ;;
    8)
        check_limit
        ;;
    *)
        echo "請輸入正確的數字！"
        ;;
esac
