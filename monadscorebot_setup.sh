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
        echo -e "${YELLOW}提示: 您可以在proxies.txt中添加代理服务器${NC}"
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

// 读取配置文件
const accounts = JSON.parse(fs.readFileSync('./account.json', 'utf8'));
const referralCode = fs.readFileSync('./referral.txt', 'utf8').trim();
const proxies = fs.readFileSync('./proxies.txt', 'utf8')
    .split('\n')
    .filter(line => line.trim())
    .map(line => line.trim());

// 创建日志文件
if (!fs.existsSync('./log.json')) {
    fs.writeFileSync('./log.json', '{}');
}

// 读取日志
const logs = JSON.parse(fs.readFileSync('./log.json', 'utf8'));

// 获取随机代理
function getRandomProxy() {
    if (proxies.length === 0) return null;
    return proxies[Math.floor(Math.random() * proxies.length)];
}

// 创建代理agent
function createProxyAgent(proxy) {
    if (!proxy) return null;
    if (proxy.startsWith('socks5://')) {
        return new SocksProxyAgent(proxy);
    }
    return new HttpsProxyAgent(proxy);
}

// 更新节点
async function updateNode(privateKey) {
    const proxy = getRandomProxy();
    const agent = createProxyAgent(proxy);
    
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
    
    for (const account of accounts) {
        const privateKey = account.privateKey;
        const address = account.address;
        
        // 检查今天是否已经更新过
        const today = new Date().toISOString().split('T')[0];
        if (logs[address] && logs[address].lastUpdate === today) {
            console.log(colors.yellow(`地址 ${address} 今天已经更新过，跳过`));
            continue;
        }
        
        console.log(colors.cyan(`正在更新地址: ${address}`));
        const result = await updateNode(privateKey);
        
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
    (crontab -l 2>/dev/null; echo "0 7 * * * cd $(pwd) && node start.js >> bot.log 2>&1") | crontab -
    echo -e "${GREEN}✓ 已设置每天早上7点自动运行${NC}"
}

# 主函数
main() {
    check_system
    install_dependencies
    create_files
    create_main_files
    setup_cron
    
    echo -e "${GREEN}安装完成！${NC}"
    echo -e "${YELLOW}您现在可以：${NC}"
    echo -e "1. 编辑 account.json 添加您的钱包私钥"
    echo -e "2. 编辑 proxies.txt 添加代理服务器（可选）"
    echo -e "3. 运行 ./start_bot.sh 启动节点更新服务"
}

# 运行主函数
main
