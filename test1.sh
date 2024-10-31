#!/bin/bash

# 检查是否是 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "正在提升为 root 权限，需要输入密码..."
    sudo "$0" "$@"
    exit 0
fi


# 查找名为"autorunwang.sh"的进程的PID
pid=$(pgrep -f autorunwang.sh)

# 检查是否找到了进程
if [ -z "$pid" ]; then
	    echo "未找到名为'autorunwang.sh'的进程。"
    else
	        echo "找到名为'autorunwang.sh'的进程，其PID为：$pid"
		    # 尝试终止进程
		        kill -9 $pid
			    echo "已尝试终止进程。"
fi

# 查找名为"aiui_sample"的进程的PID
pid=$(pgrep -f aiui_sample)

# 检查是否找到了进程
if [ -z "$pid" ]; then
	    echo "未找到名为'aiui_sample'的进程。"
    else
	        echo "找到名为'aiui_sample'的进程，其PID为：$pid"
		    # 尝试终止进程
		        kill -9 $pid
			    echo "已尝试终止进程。"
fi

# 查找名为"aiui_sample_elf"的进程的PID
pid=$(pgrep -f aiui_sample_elf)

# 检查是否找到了进程
if [ -z "$pid" ]; then
	    echo "未找到名为'aiui_sample_elf'的进程。"
    else
	        echo "找到名为'aiui_sample_elf'的进程，其PID为：$pid"
		    # 尝试终止进程
		        kill -9 $pid
			    echo "已尝试终止进程。"
fi



# 检查是否提供了设备编号
if [ "$#" -ne 1 ]; then
    echo "用法: $0 <设备编号>"
    exit 1
fi

# 提取设备编号
device_number="$1"

# 定义文件路径
device_json="device.json"
device_info_json="device_info.json"

# 查找匹配的设备信息
device_info=$(jq -r --arg deviceName "00000000$device_number" \
    '.[] | select(.deviceName == $deviceName)' "$device_json")

# 检查是否找到设备信息
if [ -z "$device_info" ]; then
    echo "未找到设备编号为 $device_number 的设备信息"
    exit 1
fi

# 提取设备信息
deviceName=$(echo "$device_info" | jq -r '.deviceName')
deviceSecretKey=$(echo "$device_info" | jq -r '.deviceSecretKey')
productId=$(echo "$device_info" | jq -r '.productId')

# 使用 jq 更新 device_info.json 文件
jq --arg deviceName "$deviceName" \
   --arg deviceSecretKey "$deviceSecretKey" \
   --arg productId "$productId" \
   '.deviceName = $deviceName | .key_deviceinfo.deviceSecret = $deviceSecretKey | .productId = $productId' \
   "$device_info_json" > tmp.json && mv tmp.json "$device_info_json"

chmod a+x device_info.json
echo "设备信息已成功更新到 $device_info_json，并添加了可执行权限。"


# 无限循环，直到 wlan0 接口就绪
while true; do
    # 执行命令并检查返回状态码
    if ip link show wlan0 > /dev/null 2>&1; then
        # 如果命令返回状态码为 0，表示 wlan0 接口就绪
        echo "Wlan0 Ready."
        #nmcli device wifi connect Y password 88111111
        # 退出循环
        break
    else
        # 如果命令返回非零状态码，表示 wlan0 接口尚未就绪，等待一段时间后重试
        echo "wlan0 is not ready, waiting..."
        sleep 5
    fi
done

# 获取MAC地址
mac=$(cat /sys/class/net/wlan0/address)
# 提取后5位
last_six=$(echo $mac | awk -F: '{print $4$5$6}')
echo $last_six
last_five=$(echo "$last_six" | awk '{print substr($1, length($1)-4, 5)}')
echo $last_five
# 将十六进制转换为十进制
decimal=$(printf "%d" 0x$last_five)
echo $decimal
# 补齐到7位
formatted=$(printf "%07d" $decimal)
echo $formatted
cteiv=$(echo "18012455$formatted")
# 输出结果
echo MAC:$mac
echo CTEI:$cteiv
echo Name:$deviceName

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Test Start!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
aplay /usr/share/sounds/alsa/Side_Left.wav
sleep 3
amixer set Master 30%
sleep 1
alsactl store -f /etc/asound.state
sleep 1
alsactl store
sleep 1
sync
echo "set Master 30% done"
sleep 1
cd /home/ubt/
echo ">>>>>>>>>>>>>>>>>>>>record 5s,please speak to the device<<<<<<<<<<<<<<<<<<<"
arecord -D plughw:1,0   -r 16000 -c 4  -f S16_LE  test.wav -d 5
sleep 2
aplay /home/ubt/test.wav
rm test.wav
sync
echo "test over!!!"
