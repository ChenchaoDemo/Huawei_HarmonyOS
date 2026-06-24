# HarmonyOS NEXT 原生版说明

本仓库当前已经是 DevEco Studio 可打开的 HarmonyOS Stage 模型工程，原生实现位于 `entry/src/main/ets`，未修改或删除参考 uni-app 项目文件。

## 参考小程序结构总结

- `pages.json`：定义首页、工具、记录、我的四个 Tab，以及 PDF、转 PDF、PDF 转其他、扫描类详情页路由。
- `manifest.json`：uni-app 应用配置，包含小程序 appid、Vue 3、移动端权限和发布配置。
- `App.vue`：全局浅灰背景、白色卡片、主色按钮、危险按钮等基础视觉风格。
- `utils/constants.js`：核心工具分类、工具清单、每个工具的 `ToolConfig`、处理器名称、选择模式、结果扩展名和参数设置。
- `utils/processorRegistry.js`：把 PDF、图片、Office、文本处理器汇总后按名称查找。
- `utils/pdfProcessor.js`：PDF 合并、拆分、删除、重排等轻量处理，复杂渲染/提取用降级结果；加密依赖三方库。
- `utils/imageProcessor.js`：图片转 PDF、证件扫描、文件扫描 PDF 生成。
- `utils/officeProcessor.js`：Office 文档解析和基础转换；Word 原样转换明确停止并要求服务端能力。
- `utils/fileHelper.js`：文件选择、图片选择、类型/大小校验、临时保存、打开、分享、历史存储。
- `utils/historyManager.js`：封装处理记录的保存、读取、删除、清空。
- `components/ToolRunner.vue`：通用工具详情流程，覆盖文件选择、参数设置、处理进度、错误、结果、历史。
- `ToolCard.vue`、`CategorySection.vue`：工具卡片和分类网格。
- `FilePicker.vue`、`ResultPanel.vue`、`ProcessPanel.vue`、`SettingRow.vue`：选择文件、结果操作、参数容器、动态设置控件。
- `pages/index`：品牌区、搜索、分类筛选、最近使用、热门工具、全部分类工具。
- `pages/history`：处理历史，支持预览、分享、删除、清空。
- `pages/mine`：工具/记录统计、说明、隐私、反馈、清理、关于。
- `pages/scan/document-scan.vue`：特殊扫描体验，含拍照/相册、多图排序删除、PDF 设置、水印设置和生成扫描 PDF。

## 原生工程结构

- `entry/src/main/ets/models`：`ToolMeta`、`ToolConfig`、`ProcessorResult`、历史记录等模型。
- `entry/src/main/ets/constants`：工具分类、工具清单、参数配置和主题色。
- `entry/src/main/ets/components`：ArkUI 工具卡片、分类区、文件选择、设置行、结果面板。
- `entry/src/main/ets/pages/main`：首页、记录页、我的页、通用工具详情页、文件扫描页。
- `entry/src/main/ets/services`：`FileService`、`HistoryService`、`AppContext`。
- `entry/src/main/ets/processors`：文本、图片、PDF 轻量处理器、远程转换占位适配器。
- `entry/src/main/ets/pages/Index.ets`：`Navigation + Tabs` 单入口，三 Tab 和工具详情切换。

## 已完成能力

- 底部三 Tab：首页、记录、我的。
- 首页品牌区、搜索、分类筛选、最近使用、热门工具、全部分类工具。
- 首页整合全部工具入口，覆盖需求中的 21 个工具。
- 通用工具详情页：文件/图片/TXT 选择、输出文件名、动态参数、开始处理、进度、错误、成功结果、保存、分享占位、历史记录。
- 记录页：读取历史、保存到系统文件位置、打开路径提示、分享占位、删除、清空。
- 我的页：工具数量、记录数量、使用说明、隐私说明、意见反馈占位、文件清理、关于。
- 文件扫描页：拍照/相册入口、多图预览、排序、删除、清空、PDF 方向/边距、水印文字/位置/颜色/字号/透明度、生成扫描 PDF。
- 本地闭环处理：
  - 文本转 PDF。
  - 图片转 PDF，支持 JPG 和常见无透明 PNG。
  - 文件扫描生成 PDF。
  - 证件扫描生成 PDF。
  - PDF 合并、PDF 拆分、PDF 删除页面、PDF 页面排序，支持未加密、未使用压缩对象流的普通 PDF。

## 明确限制

- Word/PPT/Excel 原样转 PDF、PDF 转 Word/Excel/PPT、PDF 转图片、PDF 转长图、PDF 提取图片、真实 PDF 压缩、PDF 加密、复杂 PDF 水印均需要接入服务端转换或成熟本地库。当前实现会在 UI 错误态明确提示“需接入服务端转换能力”，不会生成假文件。
- 当前未引入第三方 HAR/ohpm/PDF 依赖。若后续接入 PDF/Office/OCR 库，需要先评估许可证、包体积、系统能力和服务端替代方案。
- Harmony `PhotoViewPicker` 用于图片选择；不同系统版本是否直接展示相机入口取决于系统 picker 能力。
- 预览和分享当前为路径/占位提示；保存已通过 `DocumentViewPicker.save` 写出到用户选择位置。

## 打开和构建

1. 用 DevEco Studio 打开仓库根目录：`E:\github\HuaWei\Huawei_HarmonyOS\pdf_toolbox`。
2. 选择 `entry` 模块和 `default` product。
3. 若命令行环境没有正确设置 SDK，可临时设置：

```powershell
$env:DEVECO_SDK_HOME='D:\DevEco Studio\sdk'
& "D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat" --no-daemon --mode module -p module=entry@default -p product=default assembleHap --analyze=normal --parallel --incremental
```

本次已使用上述命令构建通过，生成 `entry-default-signed.hap`。构建仍有若干 ArkTS 警告，主要是系统 API 抛异常提示和 `promptAction.showToast` 废弃提示，不影响 HAP 生成。
