# 《RoboFusion Tycoon》Beta GDD

---

## 目录

1. 核心体验概述
2. 新手落地与教学流程
3. 进程层级与目标
4. 资源与采集体系
5. 功能性建筑 & 升级（并发 10 级制）
6. 机器人与工具系统
7. 私有矿区生成与刷新
8. Base 建设 & 环保系统
9. UI / UX 框架
10. 经济与货币化
11. 每日签到奖励
12. 末端目标与后续赛季
13. 视觉 / 音频风格
14. 可扩展路线图

---

## 1. 核心体验概述

| 流程环 | 说明 |
| --- | --- |
| **降落 → 教学** | 玩家以“空投舱降落地表”的第一视角开始，立即进入分步教学。 |
| **收集 Scrap / 初级资源** | 教学阶段提供免费建筑；采集 **150 Scrap** 后开启下一环。 |
| **生成 Bot Shell → 组装机器人** | 解锁 **Mining Bot**；挖到 **8 块同类矿** 后解锁 **Builder Bot**。 |
| **私有矿区传送 → 核心挖矿** | 专属传送门进入与玩家 ID 绑定的矿区；离线自动重生。 |
| **运营与扩张** | 机器人采矿 → 运输 → 精炼 → 出售 → 升级 / 装饰 / 环保选择。 |
| **终末推进** | 研发火箭，解锁下一星体（赛季内容）。 |

---

## 2. 新手落地与教学流程

| # | 引导要点 | 解锁 / 条件 |
| --- | --- | --- |
| 1 | 降落舱着陆：镜头锁定，BGM 高潮 | — |
| 2 | 打开 **Sho**（右下建筑 UI）：展示四个免费建筑 | UI 教学 |
| 3 | 放置 **Crusher Lv1**：采集 Scrap → **150 Scrap** | — |
| 4 | 打开 **Generator** 面板：生成 *Rusty Shell ×1* | −150 Scrap |
| 5 | 进入 **Assembler**：Rusty Shell → Mining Bot | −10 Scrap |
| 6 | 通过 **传送门** 进入矿区 | 自动分配矿区 |
| 7 | 操作 Mining Bot：挖到 8 块同类矿 | 解锁 Builder Bot |
| 8 | 返回主基地：教程结束 | 解锁全部商店与系统 |

> 时长目标：≈ 10–12 分钟完成。
> 

---

## 3. 进程层级与目标

| 层级 | 核心指标 | 新主要解锁 | 典型时长* |
| --- | --- | --- | --- |
| **Tier 0** | 教程完成 | Builder Bot、基础商店 | 10 min |
| **Tier 1** | 打开 **Iron 层** | Research Bench、节点 Lv2 | 30 min |
| **Tier 2** | 同时产出 Bronze Ore | 功能建筑 ≤ Lv5、Energy Station | 2 h |
| **Tier 3** | 打开 **Gold 层** | 核能链、Eco‑Core | 6 h |
| **Tier 4** | Diamond / Titanium 收集 | 火箭装配链、星际地图 | 10 h+ |

\* 典型时长按中等活跃玩家估算。

---

## 4. 资源与采集体系

| 资源 | 产出 | 主要用途 | 硬度 |
| --- | --- | --- | --- |
| **Scrap** | Scrap Node / Crusher | Generator、低阶升级 |  |
| **Iron Ore** | 20–60 stud | Steel Bar、建筑 ≤ Lv5 | 2 |
| **Bronze Ore** | 60–100 stud | Bronze Gear、Shipper 升级 | 3 |
| **Gold Ore** | 100–160 stud | **Gold‑Plated Edge** | 4 |
| **Diamond Ore** | 160–220 stud | 顶阶工具、Prestige Skin | 5 |
| **Titanium Ore** | 220–280 stud | 建筑 Lv 6–9、机甲外壳 | 6 |
| **Uranium Ore** | ≥ 280 stud | 核电站、火箭燃料 | 6 |
| **Credits** | Robot 出售 / 接单 | 通用货币 |  |
| **Bot Shell** | Generator / 商店 | 机器人组装 |  |
| **Robot** | Assembler | 采集 / 建造 / 出售 |  |

> 矿区刷新：离线 > 5 min 即标记，下次上线前完整再生成。
> 

---

## 5. 功能性建筑 & 升级（并发 10 级制）

> 适用 Generator / Assembler / Crusher / Shipper / Tool Forge / Energy Station…
> 

| Lv | 并发队列上限 | 升级成本（Credits） | 升级 |
| --- | --- | --- | --- |
| 1 | 1 | 教程免费 |  |
| 2 | 5 | 100 | 升级数量+30 |
| 3 | 12 | 250 | 升级数量+30 |
| 4 | 25 | 500 | 升级数量+30 |
| 5 | 40 | 900 | 升级数量+30 |
| 6 | 60 | 1 400 | 升级数量+30 |
| 7 | 90 | 2 000 | 升级数量+30 |
| 8 | 130 | 3 000 | 升级数量+30 |
| 9 | 190 | 4 500 | 升级数量+30 |
| 10 | **250** | 6 000 | 升级数量+30 |
- **制作队列 UI**：输入框

---

## 6. 机器人与工具系统

### 6.1 机器人类别

| 蛋类型 (BotShell) | 解锁条件 | 材料消耗 | 制作时长 | 生成机器人等级 | 特殊机制 |
| --- | --- | --- | --- | --- | --- |
| **Rusty Shell** | Generator Lv 1 | Scrap × 150 | 3 s | uncommon |  |
| **Neon Core Shell** | Bronze x 200 | Scrap × 3 0000 or Iron x 3000 | 10 s | rare |  |
| **Quantum Capsule** | Titanium x 500 | Scrap × 80 0000 or Diamond x 5000 | 60 s | epic | 5 % 概率直接孵 **Golden** |
| **Eco Booster Pod (Not Beta)** | Eco Block build | Credit x 5000 | 20 s | eco |  |
| **Secret Prototype** | 黑市无人机（30 min 刷新） | Scrap × 动态竞价（≥ 120 k） | 45 s | secret | 可孵化 **Mythic / Secret**，全服广播 |

| 类别 | 初始解锁 | 职责 | 基础耐久示例 |
| --- | --- | --- | --- |
| **Mining Bot** | 教程 | 采矿 | 木镐 50 格 |
| **Builder Bot** | 挖 8 矿 | 搬运 / 建造 | 木锤 5 分钟 |
| *Combat / Logistics* | 赛季后续 | — | — |

### 6.2 能量与补给站

- **Energy Station Lv1–Lv5**：范围充能；Lv↑ → 速度↑。Lv+1 = 速度-10%
- 能量为 0 → 原地休眠并寻路至最近补给站（若开启自动返程）。
- 通过 credit 充能，100credit ，15 分钟充能 1 个小时工作时间。

### 6.3 工具 & 耐久

## 挖掘稿子

| 等级 | 材料 | 采矿耐久（格） |
| --- | --- | --- |
| 木 | Scrap Wood | 50 |
| Iron | **Iron Bar** | 120 - 可以挖硬度3 |
| Bronze | **Bronze Gear** | 250 - 可以挖硬度4 |
| Gold | **Gold‑Plated Edge** | 400 - 可以挖硬度5 |
| Diamond | **Diamond Tip** | 800 - 可以挖硬度6 |

## 建造锤子

| 等级 | 材料 | 建造耐久（工作分钟） |
| --- | --- | --- |
| 木 | Scrap Wood | 5 |
| Iron | **Iron Bar** | 30 |
| Bronze | **Bronze Gear** | 5h |
| Gold | **Gold‑Plated Edge** | 10h |
| Diamond | **Diamond Tip** | 100h |

> Iron Bar：Scrap + Iron Ore 熔炼
> 
> 
> Bronze Gear：Scrap + Bronze Ore 合金
> 

### 6.4 任务指派 UI

- **Inventory → Robots Tab**：列表点击进入任务编辑。
- 参数：目标矿种 / 数量 / 优先级 / 自动返仓。
- 后端寻路：A\* 或 Jump Point；细节对玩家透明。

---

## 7. 私有矿区生成与刷新

| 步骤 | 描述 |
| --- | --- |
| **Cube Seed** | 每玩家有大约 300stud 高，150x150 底座的山体，随机种子。 |
| **体块拼贴** | 20x20x20 stud 网格 + Perlin Noise → 石块 / 洞穴 / 空洞。 |
| **矿脉布置** | 各层 5–8 簇；深度范围见 §4；`IntValue_ScrapAmount = 50 × 半径`。 |
| **离线刷新** | 离线 > 5 min 标记，下次上线前完整再生成。 |

---

## 8. Base 建设 & 环保系统

1. **装饰建筑**：桥梁、雕塑、地标（巴黎圣母院等），消耗 Credits。
2. **Eco‑Core（环保核）**
    - Lv1–Lv3；每级 **World Cleanliness +20 %**，并 **全建筑效率 −5 %**（上限 −15 %）。
    - Cleanliness 达阈值：天空盒灰霾 → 蓝天，BGM 低频衰减。
3. **Cleanliness 效果**：影响访客 NPC 稀有订单、社区排行。

---

## 9. UI / UX 框架

| 面板 | 入口 | 关键交互 |
| --- | --- | --- |
| **Sho (Build Shop)** | 右下按钮 | 分类：功能建筑 / 装饰 / 工具 / 特殊 |
| **Inventory** | 左侧栏 | 自适应网格 |
| **Robots** | Inventory 子页 | 列表 + 任务编辑 |
| **Assembler** | 点击建筑 | Shell 选取 → Robot 类型 → 成功率 |
| **GamePass / DevProduct** | 顶部 💎 | 购买说明 |
| **Daily Check‑in** | 首次上线弹窗 / 图标 | 奖励 + 补签 |
| **Prestige / Rocket** | Tier 4 | 火箭零件进度 + 发射按钮 |

---

## 10. 经济与货币化

| 项目 | 价格 (R$) | 功能 |
| --- | --- | --- |
| GamePass – Auto‑Collect | 599 | 自动拾取资源 - scrap |
| GamePass – VIP | 299 | scrap x2 速 + 额外签到 |
| DevProduct – Skip Missed Day | 19 | 补签 |
| DevProduct – Titanium Pack | 99 | Titanium Ore ×100 |
| （预留）装饰皮肤包 | TBD | 纯外观 |

---

## 11. 每日签到奖励（8 天循环）

| 天 | 奖励 | 说明 |
| --- | --- | --- |
| 1 | Scrap ×500 | 起步资源 |
| 2 | Credits ×1 000 | 早期升级 |
| 3 | Rusty Shell ×2 | 立即组装 |
| 4 | Wood Pick ×1 | 工具补给 |
| 5 | Titanium Ore ×25 | 稀有矿 |
| 6 | Energy‑Core (S) ×3 | 机器人充能 |
| 7 | NeonCore Shell ×1 | 稀有 Shell |
| **Bonus** | VIP：**Bronze Pick ×1** | 加速采矿 |

未登录可 DevProduct 补签；VIP 额外获 Bonus。

---

## 12. 末端目标与后续赛季

1. **Rocket Assembly**：收集 Uranium Fuel / Titanium Plates / Quantum Circuits。
2. **火箭发射**：3 min 实机演出 → 星际地图。
3. **赛季 2：月面前哨** – 太阳能、低重力物流带、夜袭机械兽、PvE 塔防。
4. **赛季 3：沙漠卫星** – 风沙腐蚀系统、沙暴电力、热管理链。

---

## 13. 视觉 / 音频风格

- **美术**：Low‑poly + 法线贴图；主色：锈红 / 冷灰 / 霓虹青。
- **UI**：半透明硬边 + 霓虹描边 + Drop Shadow。
- **BGM**：Lo‑fi 工业节拍；深层矿区叠加心跳式低频。
- **SFX**：齿轮、等离子焊、岩石崩裂、传送门回响。

---