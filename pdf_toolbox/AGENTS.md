# AGENTS.md

本项目是 HarmonyOS NEXT 原生 ArkTS / ArkUI 应用，目标是把 uni-app 版“文件处理工具箱”迁移为符合鸿蒙原生体验的 Stage 模型 App。

## 项目约束

- 不修改、删除或覆盖参考 uni-app 项目代码；当前原生实现位于本仓库 `entry/src/main/ets`。
- 使用 ArkTS + ArkUI 声明式 UI，优先使用 `@Entry`、`@Component`、`@State`、`@Builder`、`ForEach`、`Tabs`、`Navigation`、`Search`、`List/Grid/Scroll`。
- 使用 vp/fp 语义尺寸，不照搬 rpx。
- 文件选择使用 `@kit.CoreFileKit` 的 `picker.DocumentViewPicker`。
- 图片选择使用 `@kit.MediaLibraryKit` 的 `photoAccessHelper.PhotoViewPicker`。
- 保存结果使用 `DocumentViewPicker.save` 或系统可用保存能力。
- 历史记录使用 `Preferences`，统一通过 `HistoryService` 访问。
- 临时文件写入应用沙箱目录，统一通过 `FileService` 访问。
- 保持 `ToolMeta`、`ToolConfig`、`ProcessorResult`、`ProcessorRegistry` 的注册式设计。
- 不随意引入网络依赖、HAR、ohpm 包或第三方 PDF/Office 库；确需引入时先说明许可证、包体积、替代方案和风险。

## HarmonyOS UX 标准

- 页面必须像原生鸿蒙 App：使用系统导航、底部 Tab、系统 picker、系统保存入口和 ArkUI 原生控件，不保留小程序交互痕迹。
- 顶部内容要考虑状态栏/安全区，禁止标题、返回按钮、搜索框贴近屏幕边缘。
- 常用触控目标不小于 40vp；列表内操作按钮尽量保持 36vp 以上，并留出清晰间距。
- 文字使用层级清楚的 fp 尺寸，正文和说明文字保持可读，不使用过小字体承载关键操作。
- 工具型页面保持紧凑办公风格：浅灰背景、白色卡片、主色 `#2667FF`、辅助紫 `#8A4DFF`，避免营销式大段说明。
- 卡片只用于独立信息块、工具项、结果面板；不要把页面区块层层套卡片。
- 处理流程必须覆盖空态、加载态、禁用态、错误态、成功态。
- 正式图标不使用 emoji；没有图标资源时使用统一文字色块、系统符号或后续 `resources/media` 图标。
- 重型转换能力不得伪造结果。Word/PPT/Excel 原样转换、复杂 PDF 渲染/OCR/压缩/加密等必须明确提示需接入服务端或成熟库。
- 所有中文文案必须保持 UTF-8，禁止提交乱码。

## 构建验证

命令行构建可使用：

```powershell
$env:DEVECO_SDK_HOME='D:\DevEco Studio\sdk'
& "D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat" --no-daemon --mode module -p module=entry@default -p product=default assembleHap --analyze=normal --parallel --incremental
```

如 `DEVECO_SDK_HOME` 或 hvigor 路径与本机不一致，应先在 DevEco Studio 中确认 SDK 与 hvigor 安装目录。

## 代码分层

- `models`：工具、参数、处理结果、历史记录等类型。
- `constants`：工具清单、分类、工具配置和主题常量。
- `components`：可复用 ArkUI 组件。
- `pages/main`：四个 Tab 页面、工具详情页、文件扫描页。
- `services`：文件、历史、应用上下文等平台服务。
- `processors`：本地轻量处理器和远程转换占位适配器。
- `utils`：格式化、文件名、字节转换等纯工具函数。
