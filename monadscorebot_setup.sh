#!/bin/bash

# 署名和说明
cat << "EOF"

    __   _         _                                  ___    _  _   
  / _| (_)       | |                                  |__ \  | || |  
 | |_   _   ___  | |__    ____   ___    _ __     ___     ) | | || |_ 
 |  _| | | / __| | '_ \  |_  /  / _ \  | '_ \   / _ \   / /  |__   _|
 | |   | | \__ \ | | | |  / /  | (_) | | | | | |  __/  / /_     | |  
 |_|   |_| |___/ |_| |_| /___|  \___/  |_| |_|  \___| |____|    |_|  
                                                                     
                                                                     

                                                                                                                                  

EOF
echo -e "${BLUE}==================================================================${RESET}"
echo -e "${GREEN}Monadscore-Bot 节点一键管理脚本${RESET}"
echo -e "${YELLOW}脚本作者: fishzone24 - 推特: https://x.com/fishzone24${RESET}"
echo -e "${YELLOW}此脚本为免费开源脚本，如有问题请提交 issue${RESET}"
echo -e "${BLUE}==================================================================${RESET}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 设置安装目录
INSTALL_DIR="/root/MonandScore-Bot"

# 创建安装目录
create_install_dir() {
    echo -e "${BLUE}正在创建安装目录...${NC}"
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    echo -e "${GREEN}✓ 已创建安装目录: $INSTALL_DIR${NC}"
}

# 检查系统要求
check_system() {
    echo -e "${BLUE}正在检查系统要求...${NC}"
    
    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${GREEN}✓ 操作系统: Linux${NC}"
    else
        echo -e "${RED}✗ 不支持的操作系统${NC}"
        exit 1
    fi
    
    # 检查必要的命令
    for cmd in curl wget node npm git; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}✗ 未找到 $cmd${NC}"
            echo -e "${YELLOW}正在安装 $cmd...${NC}"
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y $cmd
            elif command -v yum &> /dev/null; then
                sudo yum install -y $cmd
            else
                echo -e "${RED}无法安装 $cmd，请手动安装后重试${NC}"
                exit 1
            fi
        else
            echo -e "${GREEN}✓ 已安装 $cmd${NC}"
        fi
    done
}

# 安装依赖
install_dependencies() {
    echo -e "${BLUE}正在安装项目依赖...${NC}"
    
    # 创建package.json
    cat > package.json << EOF
{
  "name": "monadscore-bot",
  "version": "1.0.0",
  "description": "Monadscore自动推荐和节点更新器",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "start:bot": "node start.js"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "chalk": "^4.1.2",
    "colors": "^1.4.0",
    "ethers": "^5.7.2",
    "https-proxy-agent": "^7.0.2",
    "socks-proxy-agent": "^8.0.2"
  }
}
EOF

    # 安装依赖
    npm install
}

# 创建必要的文件
create_files() {
    echo -e "${BLUE}正在创建必要的文件...${NC}"
    
    # 创建referral.txt
    if [ ! -f referral.txt ]; then
        echo "请输入您的邀请码:"
        read referral_code
        echo "$referral_code" > referral.txt
        echo -e "${GREEN}✓ 已创建referral.txt${NC}"
    fi
    
    # 创建proxies.txt
    if [ ! -f proxies.txt ]; then
        touch proxies.txt
        echo -e "${GREEN}✓ 已创建proxies.txt${NC}"
    fi
    
    # 创建account.json
    if [ ! -f account.json ]; then
        echo "[]" > account.json
        echo -e "${GREEN}✓ 已创建account.json${NC}"
    fi
}

# 创建主程序文件
create_main_files() {
    echo -e "${BLUE}正在创建主程序文件...${NC}"
    
    # 创建index.js
    cat > index.js << 'EOF'
const axios = require('axios');
const fs = require('fs');
const { HttpsProxyAgent } = require('https-proxy-agent');
const { SocksProxyAgent } = require('socks-proxy-agent');
const colors = require('colors');
const { ethers } = require('ethers');

// 读取配置文件
const privateKeys = JSON.parse(fs.readFileSync('./account.json', 'utf8'));
const referralCode = fs.readFileSync('./referral.txt', 'utf8').trim();
const proxies = fs.readFileSync('./proxies.txt', 'utf8')
    .split('\n')
    .filter(line => line.trim())
    .map(line => line.trim());

// 读取地址映射
let addressMap = {};
try {
    addressMap = JSON.parse(fs.readFileSync('./addresses.json', 'utf8'));
} catch (error) {
    console.log(colors.yellow('未找到地址映射文件，将自动生成地址'));
}

// 创建日志文件
if (!fs.existsSync('./log.json')) {
    fs.writeFileSync('./log.json', '{}');
}

// 读取日志
const logs = JSON.parse(fs.readFileSync('./log.json', 'utf8'));

// 创建代理agent
function createProxyAgent(proxy) {
    if (!proxy) return null;
    if (proxy.startsWith('socks5://')) {
        return new SocksProxyAgent(proxy);
    }
    return new HttpsProxyAgent(proxy);
}

// 从私钥获取地址
function getAddressFromPrivateKey(privateKey) {
    // 如果地址映射中存在，直接返回
    if (addressMap[privateKey]) {
        return addressMap[privateKey];
    }
    
    // 否则从私钥派生地址
    const wallet = new ethers.Wallet(privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`);
    const address = wallet.address;
    
    // 更新地址映射
    addressMap[privateKey] = address;
    fs.writeFileSync('./addresses.json', JSON.stringify(addressMap, null, 2));
    
    return address;
}

// 更新节点
async function updateNode(privateKey, proxy) {
    const agent = createProxyAgent(proxy);
    const address = getAddressFromPrivateKey(privateKey);
    
    try {
        const response = await axios.post('https://api.monadscore.io/api/v1/node/update', {
            privateKey: privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`,
            referralCode: referralCode
        }, {
            httpsAgent: agent,
            timeout: 10000
        });
        
        return response.data;
    } catch (error) {
        console.error(colors.red(`更新失败: ${error.message}`));
        return null;
    }
}

// 主函数
async function main() {
    console.log(colors.cyan('开始更新节点...'));
    
    for (let i = 0; i < privateKeys.length; i++) {
        const privateKey = privateKeys[i];
        const address = getAddressFromPrivateKey(privateKey);
        const proxy = proxies[i] || null;
        
        // 检查今天是否已经更新过
        const today = new Date().toISOString().split('T')[0];
        if (logs[address] && logs[address].lastUpdate === today) {
            console.log(colors.yellow(`地址 ${address} 今天已经更新过，跳过`));
            continue;
        }
        
        console.log(colors.cyan(`正在更新地址: ${address}`));
        const result = await updateNode(privateKey, proxy);
        
        if (result) {
            console.log(colors.green(`更新成功: ${address}`));
            // 更新日志
            logs[address] = {
                lastUpdate: today,
                status: 'success'
            };
        } else {
            console.log(colors.red(`更新失败: ${address}`));
            logs[address] = {
                lastUpdate: today,
                status: 'failed'
            };
        }
        
        // 随机延迟5-15秒
        const delay = Math.floor(Math.random() * 10000) + 5000;
        await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    // 保存日志
    fs.writeFileSync('./log.json', JSON.stringify(logs, null, 2));
    console.log(colors.green('所有更新完成！'));
}

main().catch(console.error);
EOF

    # 创建start.js
    cat > start.js << 'EOF'
const { exec } = require('child_process');
const colors = require('colors');

console.log(colors.cyan('启动节点更新服务...'));

// 执行更新脚本
exec('node index.js', (error, stdout, stderr) => {
    if (error) {
        console.error(colors.red(`执行错误: ${error}`));
        return;
    }
    console.log(colors.green(stdout));
    if (stderr) {
        console.error(colors.yellow(stderr));
    }
});
EOF

    # 创建启动脚本
    cat > start_bot.sh << 'EOF'
#!/bin/bash
cd /root/MonandScore-Bot
node start.js
EOF

    chmod +x start_bot.sh

    echo -e "${GREEN}✓ 已创建主程序文件${NC}"
}

# 设置定时任务
setup_cron() {
    echo -e "${BLUE}正在设置定时任务...${NC}"
    
    # 检查是否已经存在定时任务
    if crontab -l | grep -q "node.*start.js"; then
        echo -e "${YELLOW}定时任务已存在，跳过${NC}"
        return
    fi
    
    # 添加定时任务
    (crontab -l 2>/dev/null; echo "0 7 * * * cd $INSTALL_DIR && node start.js >> bot.log 2>&1") | crontab -
    echo -e "${GREEN}✓ 已设置每天早上7点自动运行${NC}"
}

# 管理账号
manage_accounts() {
    while true; do
        echo -e "\n${BLUE}账号管理${NC}"
        echo -e "1. 添加账号"
        echo -e "2. 查看所有账号"
        echo -e "3. 删除账号"
        echo -e "4. 返回主菜单"
        read -p "请选择操作 [1-4]: " choice
        
        case $choice in
            1)
                echo -e "${YELLOW}请输入私钥（不需要0x前缀），直接按回车键结束输入:${NC}"
                
                while true; do
                    read -p "私钥: " private_key
                    
                    # 如果用户直接按回车键，则结束输入
                    if [ -z "$private_key" ]; then
                        break
                    fi
                    
                    echo -e "${YELLOW}请输入对应的代理地址（可选，直接回车跳过）:${NC}"
                    read proxy
                    
                    # 使用ethers库从私钥派生地址
                    address=$(node -e "
                        const { ethers } = require('ethers');
                        const wallet = new ethers.Wallet('0x${private_key}');
                        console.log(wallet.address);
                    ")
                    
                    # 确保在正确的目录中
                    cd $INSTALL_DIR
                    
                    # 添加到account.json（只存储私钥）
                    if [ ! -f account.json ]; then
                        echo "[]" > account.json
                    fi
                    
                    # 使用Python处理JSON
                    python3 -c "
import json
import sys

# 读取现有账号
try:
    with open('account.json', 'r') as f:
        accounts = json.load(f)
except:
    accounts = []

# 添加新账号（只存储私钥）
accounts.append('$private_key')

# 写回文件
with open('account.json', 'w') as f:
    json.dump(accounts, f, indent=4)
"
                    
                    # 添加到addresses.json（存储私钥和地址的映射）
                    if [ ! -f addresses.json ]; then
                        echo "{}" > addresses.json
                    fi
                    
                    python3 -c "
import json
import sys

# 读取现有地址映射
try:
    with open('addresses.json', 'r') as f:
        addresses = json.load(f)
except:
    addresses = {}

# 添加新地址映射
addresses['$private_key'] = '$address'

# 写回文件
with open('addresses.json', 'w') as f:
    json.dump(addresses, f, indent=4)
"
                    
                    # 添加到proxies.txt
                    if [ ! -z "$proxy" ]; then
                        echo "$proxy" >> proxies.txt
                    else
                        echo "" >> proxies.txt
                    fi
                    
                    echo -e "${GREEN}✓ 账号添加成功${NC}"
                    echo -e "${YELLOW}继续输入下一个账号，或直接按回车键结束输入${NC}"
                done
                
                echo -e "${GREEN}✓ 所有账号添加完成${NC}"
                ;;
            2)
                # 确保在正确的目录中
                cd $INSTALL_DIR
                
                echo -e "\n${BLUE}当前账号列表：${NC}"
                if [ -f account.json ]; then
                    # 读取私钥列表
                    private_keys=$(cat account.json | python3 -c "
import json
import sys
keys = json.load(sys.stdin)
print(json.dumps(keys, indent=4))
")
                    
                    # 读取地址映射
                    if [ -f addresses.json ]; then
                        addresses=$(cat addresses.json | python3 -c "
import json
import sys
addrs = json.load(sys.stdin)
print(json.dumps(addrs, indent=4))
")
                        
                        # 显示账号和地址信息
                        echo -e "${BLUE}私钥列表：${NC}"
                        echo "$private_keys"
                        echo -e "${BLUE}地址映射：${NC}"
                        echo "$addresses"
                    else
                        echo "$private_keys"
                    fi
                else
                    echo "[]"
                fi
                
                echo -e "\n${BLUE}当前代理列表：${NC}"
                if [ -f proxies.txt ]; then
                    cat proxies.txt
                else
                    echo "暂无代理"
                fi
                ;;
            3)
                # 确保在正确的目录中
                cd $INSTALL_DIR
                
                echo -e "${YELLOW}请输入要删除的私钥:${NC}"
                read private_key
                
                # 从account.json中删除
                if [ -f account.json ]; then
                    python3 -c "
import json
import sys

# 读取现有账号
with open('account.json', 'r') as f:
    accounts = json.load(f)

# 过滤掉要删除的账号
accounts = [acc for acc in accounts if acc != '$private_key']

# 写回文件
with open('account.json', 'w') as f:
    json.dump(accounts, f, indent=4)
"
                fi
                
                # 从addresses.json中删除
                if [ -f addresses.json ]; then
                    python3 -c "
import json
import sys

# 读取现有地址映射
with open('addresses.json', 'r') as f:
    addresses = json.load(f)

# 删除要删除的账号
if '$private_key' in addresses:
    del addresses['$private_key']

# 写回文件
with open('addresses.json', 'w') as f:
    json.dump(addresses, f, indent=4)
"
                fi
                
                # 从proxies.txt中删除对应的代理
                if [ -f proxies.txt ]; then
                    sed -i "/$private_key/d" proxies.txt
                fi
                
                echo -e "${GREEN}✓ 账号删除成功${NC}"
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 管理代理
manage_proxies() {
    while true; do
        echo -e "\n${BLUE}代理管理${NC}"
        echo -e "1. 添加代理"
        echo -e "2. 查看所有代理"
        echo -e "3. 删除代理"
        echo -e "4. 返回主菜单"
        read -p "请选择操作 [1-4]: " choice
        
        case $choice in
            1)
                echo -e "${YELLOW}请输入代理地址（支持http和socks5）:${NC}"
                read proxy
                echo "$proxy" >> proxies.txt
                echo -e "${GREEN}✓ 代理添加成功${NC}"
                ;;
            2)
                echo -e "\n${BLUE}当前代理列表：${NC}"
                cat proxies.txt
                ;;
            3)
                echo -e "${YELLOW}请输入要删除的代理地址:${NC}"
                read proxy
                sed -i "/$proxy/d" proxies.txt
                echo -e "${GREEN}✓ 代理删除成功${NC}"
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 控制机器人
control_bot() {
    while true; do
        echo -e "\n${BLUE}机器人控制${NC}"
        echo -e "1. 启动机器人"
        echo -e "2. 停止机器人"
        echo -e "3. 查看运行状态"
        echo -e "4. 返回主菜单"
        read -p "请选择操作 [1-4]: " choice
        
        case $choice in
            1)
                if pgrep -f "node.*start.js" > /dev/null; then
                    echo -e "${YELLOW}机器人已经在运行中${NC}"
                else
                    cd $INSTALL_DIR
                    nohup node start.js > bot.log 2>&1 &
                    echo -e "${GREEN}✓ 机器人已启动${NC}"
                    # 等待一秒，确保进程已经启动
                    sleep 1
                fi
                ;;
            2)
                if pgrep -f "node.*start.js" > /dev/null; then
                    pkill -f "node.*start.js"
                    echo -e "${GREEN}✓ 机器人已停止${NC}"
                else
                    echo -e "${YELLOW}机器人未在运行${NC}"
                fi
                ;;
            3)
                if pgrep -f "node.*start.js" > /dev/null; then
                    echo -e "${GREEN}机器人正在运行${NC}"
                    # 显示进程信息
                    echo -e "${BLUE}进程信息:${NC}"
                    ps aux | grep "node.*start.js" | grep -v grep
                else
                    echo -e "${YELLOW}机器人未在运行${NC}"
                fi
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 查看日志
view_logs() {
    while true; do
        echo -e "\n${BLUE}日志查看${NC}"
        echo -e "1. 查看运行日志"
        echo -e "2. 查看更新记录"
        echo -e "3. 返回主菜单"
        read -p "请选择操作 [1-3]: " choice
        
        case $choice in
            1)
                if [ -f bot.log ]; then
                    tail -n 50 bot.log
                else
                    echo -e "${YELLOW}暂无运行日志${NC}"
                fi
                ;;
            2)
                if [ -f log.json ]; then
                    cat log.json | python3 -m json.tool
                else
                    echo -e "${YELLOW}暂无更新记录${NC}"
                fi
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 主菜单
show_menu() {
    while true; do
        echo -e "\n${BLUE}主菜单${NC}"
        echo -e "1. 管理账号"
        echo -e "2. 管理代理"
        echo -e "3. 控制机器人"
        echo -e "4. 查看日志"
        echo -e "5. 退出"
        read -p "请选择操作 [1-5]: " choice
        
        case $choice in
            1)
                manage_accounts
                ;;
            2)
                manage_proxies
                ;;
            3)
                control_bot
                ;;
            4)
                view_logs
                ;;
            5)
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# 主函数
main() {
    create_install_dir
    check_system
    install_dependencies
    create_files
    create_main_files
    setup_cron
    
    echo -e "${GREEN}安装完成！${NC}"
    echo -e "${YELLOW}安装目录: $INSTALL_DIR${NC}"
    show_menu
}

# 运行主函数
main
