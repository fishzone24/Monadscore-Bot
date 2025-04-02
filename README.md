# **Monadscrore 自动推荐和节点更新器**  

一个全自动机器人，旨在使用代理更新多个钱包的 Monadscorenode 启动时间。该机器人确保每日更新，同时记录执行细节以防止冗余请求。  

## 📢 项目描述

MSCORE 自动节点更新器是一个强大的工具，用于自动化更新 MSCORE 网络上钱包启动时间的过程。通过集成代理支持、随机延迟和日志机制，它确保高效和安全的操作，避免不必要的重复更新。  

该机器人从 `account.json` 中读取钱包私钥，随机选择一个代理（如果可用），并通过 API 更新节点启动时间。它还维护一个 `log.json` 文件，以跟踪更新并避免在同一天内重复执行相同操作。  

## **🚀 功能**  

✅ **自动更新** – 每天早上 **7 点** 运行，确保钱包保持活跃。  
✅ **代理支持** – 使用 `proxies.txt` 中的代理来增强匿名性，支持HTTP和SOCKS5代理。  
✅ **钱包管理** – 从 `account.json` 中读取和处理钱包私钥。  
✅ **日志系统** – 通过跟踪执行历史防止冗余更新。  
✅ **重试和延迟机制** – 实施随机延迟和重试以平滑处理 API 故障。  
✅ **可定制执行** – 允许修改更新时间、代理和重试设置。  

---

## **📌 安装**  

### **方法一：使用一键安装脚本**

```bash
wget -O monadscorebot_setup.sh https://raw.githubusercontent.com/fishzone24/Monadscore-Bot/main/monadscorebot_setup.sh && chmod +x monadscorebot_setup.sh && ./monadscorebot_setup.sh
```

### **方法二：手动安装**

#### **步骤 1: 克隆仓库**  

```bash
git clone https://github.com/fishzone24/Monadscore-Bot.git
cd Monadscore-Bot
```

#### **步骤 2: 安装依赖**

```bash
npm install
```

#### **步骤 3: 设置钱包私钥**

创建或修改 `account.json` 文件并按以下格式输入您的钱包私钥（每行一个）：

```
私钥1
私钥2
私钥3
```

注意：私钥可以带"0x"前缀，也可以不带，程序会自动处理。

#### **步骤 4: （可选）添加代理支持**

如果您想使用代理，请将它们添加到 `proxies.txt`（每行一个）。示例：

```
http://username:password@proxy1.com:port
socks5://proxy2.com:port
```

## **💻 使用方法**

### **运行自动推荐机器人**

```bash
./start_referral.sh
```
或者
```bash
node index.js
```

### **运行节点更新服务**

```bash
./start_bot.sh
```
或者
```bash
node start.js
```

该机器人已配置为每天早上 7 点自动运行。它确保每个钱包每天只更新一次，以避免冗余的 API 请求。

---

## **⚙️ 配置选项**

### **账户设置**
- 将私钥添加到 `account.json` 文件，每行一个私钥

### **代理设置**
- 将代理添加到 `proxies.txt` 文件，支持HTTP和SOCKS5代理

### **邀请码设置**
- 修改 `referral.txt` 文件中的邀请码

---

## **📦 依赖**

该机器人使用以下库来平稳运行：

- axios – 处理对 API 的 HTTP 请求
- fs – 读取/写入 JSON 和文本文件以进行钱包和日志管理
- https-proxy-agent – 启用 HTTP 代理支持
- socks-proxy-agent – 启用 SOCKS5 代理支持
- ethers – 处理以太坊钱包创建和验证
- chalk/colors – 增强控制台输出的颜色

---

## **📜 许可证**

该项目是开源的，并根据 MIT 许可证授权。

---

## **❓ 常见问题 (FAQ)**

### **1️⃣ 这个机器人有什么作用？**

它更新 Monadscore 网络上钱包的节点启动时间，确保它们保持活跃和功能正常。

### **2️⃣ 我需要每天手动运行这个机器人吗？**

不，该机器人设计为每天早上 7 点自动执行。不过，如果需要，您也可以手动运行它。

### **3️⃣ 我可以不用代理运行这个机器人吗？**

可以！即使 `proxies.txt` 中没有指定代理，该机器人也能正常工作。

### **4️⃣ 如何修改执行时间？**

您可以通过修改crontab设置来更改执行时间：
```bash
crontab -e
```
然后修改相应的时间设置。

---

## **💡 脚本作者**

脚本作者: fishzone24 - 推特: https://x.com/fishzone24 