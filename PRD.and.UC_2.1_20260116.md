# Wonderful Sunset - 产品需求文档 (PRD) v1.0

## 1. 项目概览

- **App名称**：Wonderful Sunset (全语种统一)
- **目标**：通过 WeatherKit 数据与自研算法，为用户提供精准、感性的晚霞预测。
- **技术栈**：SwiftUI, WeatherKit, CloudKit (无服务端架构), CoreLocation, CoreMotion.
- **语言支持**：中文 (简体), English, 日本語, Español, Français.

---

## 2. 核心算法逻辑 (Technical Logic)

### 2.1 晚霞指数 (Sunset Score) $S$

计算逻辑基于日落前后 30 分钟的平均天气数据：

- **计算公式**：$S = [(C_h \times 0.5 + C_m \times 0.1) \times (1 - C_l)] \times (1.2 - H) \times \min(V/20, 1.2) \times 100$
- **变量定义**：
  - $C_h$ (High Cloud): 高云量 (0.0-1.0)
  - $C_m$ (Mid Cloud): 中云量 (0.0-1.0)
  - $C_l$ (Low Cloud): 低云量 (0.0-1.0)
  - $H$ (Humidity): 相对湿度 (0.0-1.0)
  - $V$ (Visibility): 能见度 (单位: KM)

### 2.2 特殊现象概率

- **反霞 (Afterglow)**：若 $C_l < 0.05$ 且 $V > 30$ 且 $C_h > 0.5$，概率为 $C_h \times 100\%$；否则为 0。
- **丁达尔效应 (Tyndall)**：若 $0.3 < (C_h+C_m+C_l) < 0.7$ 且 $H > 0.7$，概率为 $(1 - |TotalCloud - 0.55|) \times H \times 100\%$。

---

## 3. 界面交互与视觉规格 (UI/UX)

### 界面 1：【今日预报】 (Home - Forecast)

- **视觉**：
  - **背景**：全屏流体渐变 `LinearGradient`。
    - $S \ge 80$: 浓缩橘 (#FF4500) 到 深紫 (#4B0082)。
    - $S \ge 50$: 浅粉 (#FFB6C1) 到 湖蓝 (#87CEEB)。
    - $S < 50$: 灰蓝 (#708090) 到 深蓝 (#2F4F4F)。
- **元素与交互**：
  1. **位置与倒计时**：顶部居中，白色 SF Pro Text 16pt。
     - 文案：`距离黄金时刻还有 02:15:00` (多语言详见下表)。
  2. **晚霞指数**：中央，SF Pro Rounded Bold 120pt，白色。
  3. **感性文案**：指数下方，18pt。
     - $S \ge 80$: “今日大概率出现‘火烧云’，建议准备好相机。”
     - $S \ge 50$: “云层适中，或许会有温柔的粉色邂逅。”
     - $S < 50$: “天空稍显沉闷，适合在室内静候下一次惊喜。”
  4. **时刻轴 (Timeline)**：底部横排。
     - 交互：点击 `黄金时刻` / `日落时刻` / `魔幻时刻`。
     - 反馈：点击时播放 `UISelectionFeedback` (轻微触感)，背景渐变色根据该时刻的分数实时平滑切换。音效：极其微弱的“咔哒”声（模拟机械拨盘）。

### 界面 2：【深度分析】 (Deep Dive)

- **进入方式**：首页向上滑动 (Gesture transition)。
- **元素**：
  1. **云层三段式图表**：
     - 视觉：三个透明磨砂玻璃圆环，分别标注“高/中/低”。
     - 交互：点击“高云”，弹出气泡：“高层云是彩霞的画布，越高颜色越鲜艳。”
  2. **预测卡片**：
     - 丁达尔概率：显示百分比，背景带微光呼吸动画。
     - 反霞可能性：显示百分比，背景带微弱紫光。
  3. **观赏方位图**：
     - 视觉：极简 2D 罗盘。
     - 交互：点击“实景引导”，进入全屏相机流。
     - **AR 叠加**：在屏幕真实方位的地平线处叠加一个半径为 50px 的白色光晕，光晕内标注“Sun Drop Here”。

### 界面 3：【追霞日历】 (Calendar)

- **进入方式**：首页向左滑动。
- **视觉**：纵向卡片流，每张卡片对应一天。
- **交互**：点击卡片上的“铃铛”图标。
  - **逻辑**：系统在当日 15:00 检查 $S$。若 $S \ge 80$，弹出推送。

### 界面 4：【实验室 / 反馈】 (Lab & Feedback)

- **“准吗？”反馈组**：
  - **选项 1：完全一致 (Perfect)** -> 触发：CloudKit 记录 +1。
  - **选项 2：名不虚传 (Good)** -> 触发：CloudKit 记录 +1。
  - **选项 3：翻车了 (Flipped)** -> 触发：展开以下原因复选框：
    1. 低云太多 (Too much low clouds)
    2. 雾霾/空气质量差 (Poor air quality)
    3. 完全没云 (No clouds at all)
    4. 时间预报不准 (Timing was off)
- **交互**：提交成功后，屏幕中心弹出 0.5s 的渐变心形粒子效果。

---

## 4. 多语言文案库 (Localization)

| **键名 (Key)** | **中文 (CN)**      | **English (EN)**         | **日本語 (JP)**            | **Español (ES)**         | **Français (FR)**         |
| -------------------- | ------------------------ | ------------------------------ | -------------------------------- | ------------------------------- | -------------------------------- |
| Countdown_Prefix     | 距离黄金时刻还有         | Golden Hour in                 | 黄金時間まであと                 | Hora dorada en                  | Heure dorée dans                |
| Score_High_Text      | 今日大概率出现“火烧云” | Intense sunset expected today. | 素晴らしい夕焼けが期待できます   | Se espera un atardecer intenso  | Coucher de soleil intense prévu |
| Feedback_Flip_1      | 低云太多                 | Too many low clouds            | 低雲が多すぎる                   | Demasiadas nubes bajas          | Trop de nuages bas               |
| Feedback_Success     | 感谢反馈，算法正在学习   | Thanks! Algorithm is learning  | ありがとうございます。学習中です | ¡Gracias! El algoritmo aprende | Merci ! L'algorithme apprend     |

---

## 5. CloudKit 数据架构 (No-Server Data)

- **Public Database - Record Type: `GlobalFeedback`**
  - `Location`: Location (经纬度模糊到 0.1 度)
  - `PredictedScore`: Int
  - `UserFeedback`: String ("Perfect", "Good", "Flipped")
  - `FlipReason`: String (Optional)
  - `Timestamp`: Date
- **Public Database - Record Type: `GlobalScoreHeatmap`**
  - `Location`: Location
  - `ActualScore`: Int
  - Date: String (yyyy-MM-dd)
    (用于未来生成全球晚霞热力图)

---

## 6. 测试用例文档 (Test Cases)

| **模块**     | **测试场景**               | **预期结果**                                       |
| ------------------ | -------------------------------- | -------------------------------------------------------- |
| **定位**     | 用户拒绝定位权限                 | 弹出引导页，解释为何需要权限；界面显示“默认位置：巴黎” |
| **网络**     | 飞行模式启动 App                 | 显示“数据已离线”，展示最后一次缓存的预测分数           |
| **算法**     | 模拟极端数据：低云量 100%        | 晚霞分数必须小于 10 分                                   |
| **交互**     | 快速连续点击时间轴               | 渐变背景平滑过渡，不出现闪烁或卡顿                       |
| **推送**     | 点击提醒按钮后修改系统时间       | 在下午 16:00 准时收到“Wonderful Sunset”高分提醒        |
| **多语言**   | 切换系统语言为西班牙语           | App 内所有文案实时切换，App 名称保持 "Wonderful Sunset"  |
| **CloudKit** | 在未登录 Apple ID 的设备提交反馈 | 系统提示“请登录 iCloud 以参与社区反馈”                 |
| **AR引导**   | 手机倒置或快速旋转               | 罗盘指针应保持指向正确的地理西偏北方位，无明显延迟       |

---

# Wonderful Sunset - 技术与运营规格说明书 (v2.0)

## 1. 核心数据与算法逻辑 (Data & Algorithm)

### 1.1 WeatherKit 数据策略

* **获取频率** ：
* **策略** ：采用“预报驱动”模式。每次启动或位置大幅变动（>5km）时，单次调用 WeatherKit 获取未来 24 小时的逐小时预报（`HourlyForecast`）。
* **更新频率** ：App 活跃状态下每 60 分钟强制刷新一次缓存，以捕捉气象模型的最新修订。
* **变量精度与定义** ：
* **$C_h, C_m, C_l$**：WeatherKit 原生 `cloudCover` 返回值为 `Double` (0.0 至 1.0)。
* **技术回退 (Fallback)** ：由于 WeatherKit 部分地区不直接暴露分层云量，算法优先尝试读取 `cloudCoverHigh/Medium/Low`。若数据缺失，则根据 `condition`（如：云层分布是否离散）和总云量进行权重模拟。
* **时间窗口与平均值** ：
* 算法取值区间为 **$[Sunset - 45min, Sunset + 15min]$**。
* 将该区间内涉及的两个小时预报点进行 **加权平均** ：**$Val_{avg} = (Val_{h1} \times W_1 + Val_{h2} \times W_2)$**。

### 1.2 特殊现象触发窗口

* **反霞 (Afterglow)** ：检测窗口为 **$[Sunset, Sunset + 25min]$**。若此窗口内低云量突增 > 20%，概率降为 0。
* **丁达尔效应 (Tyndall)** ：检测窗口为 **$[Sunset - 60min, Sunset]$**。此阶段太阳高度角处于 **$-2^\circ$** 至 **$5^\circ$** 之间，散射最明显。

---

## 2. 界面交互与视觉规格 (UI/UX Deep Dive)

### 2.1 时刻轴 (Timeline) 逻辑

* **天文计算** ：不依赖 WeatherKit 文本，使用 `CoreLocation` 经纬度配合本地 `Solar` 算法库计算。
* **黄金时刻 (Golden Hour)** ：太阳高度角在 **$6^\circ$** 至 **$-4^\circ$** 之间。
* **日落时刻 (Sunset)** ：太阳圆盘中心刚好在地平线之下。
* **魔幻时刻 (Blue Hour)** ：太阳高度角在 **$-4^\circ$** 至 **$-6^\circ$** 之间。

### 2.2 AR 实景引导实现

* **技术路径** ：基于 `AVFoundation` (相机预览) + `CoreMotion` (设备姿态)。
* **视觉叠加** ：
* 使用 `DeviceMotion` 获取设备偏航角 (Heading)。
* 计算目标方位角 (Azimuth) 与当前 Heading 的差值。
* 在 UI 上通过 `CGAffineTransform` 移动光晕，当差值 **$< 5^\circ$** 时，光晕从半透明变为高亮，并伴随 `UIImpactFeedbackGenerator(.medium)` 触感。

### 2.3 手势冲突处理

* **层级架构** ：
* **水平导航** ：根容器使用 `TabView` 配合 `.tabViewStyle(.page(indexDisplayMode: .never))`。
* **垂直导航** ：在“首页”内嵌一个 `ScrollView`，并使用 `simultaneousGesture` 捕获滑动手势。
* **优先级** ：当 `ScrollView` 偏移量 (Offset) **$> 0$** 时，禁用 TabView 的水平滑动，确保用户在查看深度分析时不会误切页面。

---

## 3. 数据存储、隐私与性能 (Infra & Privacy)

### 3.1 CloudKit 权限与安全

* **容器配置** ：
* 使用 `Public Database`。
* **Security Roles** ：
  * `World`: 仅 `Read` 权限。
  * `Authenticated`: `Read`, `Create` 权限。
  * `Creator`: `Read`, `Write` (仅能修改自己的反馈记录)。
* **位置模糊化实现** ：
  **Swift**

```
  // 算法：保留小数点后一位（约 11.1km 精度）
  let blurredLat = Double(round(10 * originalLat) / 10)
  let blurredLon = Double(round(10 * originalLon) / 10)
```

### 3.2 缓存与离线策略

* **存储路径** ：使用 `UserDefaults` 存储最近一次计算的 `SunsetScore` 对象（JSON 序列化）。
* **有效期** ：缓存数据在日落 1 小时后自动失效，显示“期待明天”的占位 UI。

### 3.3 兼容性

* **最低版本** ：iOS 16.0 (WeatherKit 强制要求)。
* **硬件建议** ：iPhone 12 及更新机型（为了流畅运行 SwiftUI Canvas 流体渐变）。

---

## 4. 运营文案与反馈系统 (Localization & Feedback)

### 4.1 反馈选单与触发逻辑

| **触发动作** | **反馈按钮文案 (5国语言示例)**                | **触发后果**   |
| ------------------ | --------------------------------------------------- | -------------------- |
| **高分契合** | 绝美 / Stunning / 最高 / Impresionante / Magnifique | 记录一次“算法成功” |
| **低分翻车** | 并不准 / Not Accurate / 違う / Inexacto / Inexact   | 展开具体原因选单     |

**翻车原因选单 (具体填充)：**

1. **LowCloud_Block** : "低云挡住了阳光" (Low clouds blocked it)
2. **Haze_Issue** : "空气太脏/灰蒙蒙" (Haze or poor AQI)
3. **No_Color** : "云太少/没颜色" (No clouds, just clear sky)
4. **Time_Error** : "时间对不上" (The timing was off)

---

## 5. 测试用例文档 (Technical Test Cases)

### 5.1 性能与渲染测试

* **TC-PRF-01** ：在 iPhone 13 mini 上开启 AR 模式并持续 5 分钟。预期：设备无明显发烫，帧率保持在 55fps 以上。
* **TC-PRF-02** ：快速在时刻轴的三个点之间切换。预期：背景渐变色插值动画无跳变。

### 5.2 边界算法测试

* **TC-ALG-01** ：模拟能见度 < 1km (大雾)。预期：晚霞分数自动惩罚至 15 分以下，并触发文案“雾气太重，美景被藏起来了”。
* **TC-ALG-02** ：在高纬度地区（如北欧夏季）日落时间极晚。预期：时刻轴应能正确显示跨越凌晨的黄金时刻。

### 5.3 多语言热更新测试

* **TC-LOC-01** ：在 App 运行状态下，进入系统设置切换语言。预期：返回 App 后，所有 WeatherKit 返回的描述语（如“Cloudy”）和 App 内置文案全部实时更新。

---

## 6. 扩展性考虑 (Future-Proofing)

* **模块化** ：所有计算逻辑封装在 `SunsetScienceEngine` 框架下，不与 UI 耦合。
* **Widget** ：预留 `TimelineProvider` 接口，支持 iOS 桌面小组件显示实时分数。

---



# Wonderful Sunset - 技术与运营规格说明书 (v2.1)

## 1. 算法深度定义 (Algorithm Refinement)

### 1.1 时间加权平均权重 (**$W_1, W_2$**)

为了平滑跨小时的天气预报，采用  **线性内插法 (Linear Interpolation)** ：

* **定义** ：设日落的具体分钟为 **$m$**（例如 18:40，则 **$m=40$**）。
* **权重计算** ：
* **$W_1 = (60 - m) / 60$** （当前小时预报的权重）
* **$W_2 = m / 60$** （下一小时预报的权重）
* **示例** ：若日落为 18:20，则 18:00 的预报占 66.6%，19:00 的预报占 33.3%。

### 1.2 低云量突增检测

* **计算逻辑** ：比较检测窗口 **$T_{start}$** (日落前45分) 与 **$T_{end}$** (日落后15分) 的 WeatherKit 预测值。
* **判定公式** ：**$\Delta C_l = C_l(T_{end}) - C_l(T_{start})$**。
* **后果** ：若 **$\Delta C_l > 0.2$** (即云量增加了20%)，系统判定“晚霞被遮挡风险高”，将综合分数 **$S$** 强制乘以衰减系数 **$0.5$**。

### 1.3 天文算法库 (Solar Library)

* **选型** ：推荐使用开源 Swift 库 [Solar](https://github.com/ceeK/Solar)。
* **集成方式** ：通过 Swift Package Manager (SPM) 集成。
* **作用** ：本地离线计算经纬度对应的日出、日落、民用曙暮光（Civil Twilight）时间，不依赖网络 API。

---

## 2. 技术实现与稳定性 (Technical Infrastructure)

### 2.1 WeatherKit API 重试策略

* **机制** ： **指数退避算法 (Exponential Backoff)** 。
* **执行** ：若请求失败，分别在 1s、2s、4s 后进行重试。
* **上限** ：最多重试 3 次。若全部失败，显示缓存数据并弹出小字提示：“数据更新延迟，显示为上次预测”。

### 2.2 缓存失效与清理

* **失效逻辑** ：App 每次从后台进入前台 (`scenePhase` 变为 `.active`) 或首页加载时进行检查。
* **条件判断** ：当前时间 **$> (CachedSunsetDate + 3600s)$**。
* **清理策略** ：一旦判定失效，立即清空 `UserDefaults` 中的旧数据并触发新的 API 请求。

### 2.3 高纬度地区特殊处理

* **极昼/极夜判定** ：当 `Solar` 库返回的日落时间为 `nil` 时。
* **UI 响应** ：
* **极昼** ：指数显示“--”，文案：“极昼期间，太阳暂不落山”。
* **极夜** ：指数显示“--”，文案：“极夜期间，期待漫长黑夜后的第一缕阳光”。
* **跨零点逻辑** ：使用 `DateComponents` 比较。如果黄金时刻在 23:30，日落在 00:15，时刻轴应横跨两天显示，日期标签自动更新为“明天”。

---

## 3. 用户体验与功能扩展 (UX & Expansion)

### 3.1 iOS 桌面小组件 (Widget) 规格

* **尺寸支持** ：Small (1x1), Medium (2x1)。
* **显示内容** ：
* **Small** ：大数字分数 + 渐变背景 + 倒计时短句。
* **Medium** ：包含 Small 的内容，并增加时刻轴（三个关键点的时间）。
* **更新频率** ：每 4 小时通过 `TimelineProvider` 刷新，或在日落前后 1 小时内每 15 分钟刷新。

### 3.2 个性化与季节偏移量

* **季节修正系数 (**$F_{season}$**)** ：
* 冬季（空气干燥）：湿度权重降低 10%。
* 夏季（对流旺盛）：云量碎裂度权重增加 15%。
* **地理修正** ：针对沿海用户（经纬度判断），自动调高对“反霞”的预测权重。

### 3.3 界面国际化 (i18n) 适配

* **布局策略** ：使用 SwiftUI 的 `ViewThatFits`。
* **长文案处理** ：德语或法文等较长单词，使用 `.minimumScaleFactor(0.5)` 确保文字不溢出屏幕边界。

---

## 4. 自动化反馈分析 (Feedback Loop)

### 4.1 CloudKit 反馈聚合

* **自动化流程** ：每周末 App 启动时，静默查询当前地区 (方圆 50km) 在 CloudKit 中的 `GlobalFeedback`。
* **本地权重调整** ：如果该地区过去 3 次反馈均为“低云挡住”，则本地 App 自动将算法中的低云惩罚权重 **$W_{low}$** 临时上调 10%。

---

## 5. 测试用例 (QA Suite)

| **模块**     | **测试场景**                                    | **预期行为**                                               |
| ------------------ | ----------------------------------------------------- | ---------------------------------------------------------------- |
| **电池**     | 开启 AR 模式并连续运行 10 分钟                        | 电池健康度监控中，CPU 占用率应低于 30%，无过热降频               |
| **异常天气** | 模拟 WeatherKit 返回 `Condition: Sandstorm`(沙尘暴) | 算法应识别到能见度骤降，分数封顶 20 分，文案提示“风沙遮蔽天空” |
| **弱网环境** | 模拟 3G 或高延迟网络                                  | 触发 API 重试机制，UI 保持 Loading 骨架屏状态，不卡死            |
| **UI 兼容**  | 在 iPhone SE (小屏) 和 iPhone 15 Pro Max (大屏) 运行  | 首页文字大小自适应，AR 罗盘不被底部横条遮挡                      |
