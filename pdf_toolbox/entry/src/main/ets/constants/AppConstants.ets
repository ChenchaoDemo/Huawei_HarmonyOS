import { CategoryMeta, ToolConfig, ToolMeta } from '../models/ToolModels';

export const APP_NAME: string = '文件处理工具箱';
export const PRIMARY_COLOR: string = '#2667FF';
export const PURPLE_COLOR: string = '#8A4DFF';
export const PAGE_BG: string = '#F6F8FC';
export const TEXT_PRIMARY: string = '#17213D';
export const TEXT_SECONDARY: string = '#677089';
export const TEXT_MUTED: string = '#8390A7';

export const CATEGORIES: CategoryMeta[] = [
  { id: 'hot', name: '热门工具' },
  { id: 'pdf', name: 'PDF处理' },
  { id: 'toPdf', name: '转为PDF' },
  { id: 'fromPdf', name: 'PDF转其他' },
  { id: 'scan', name: '图片/扫描件工具' }
];

export const TOOLS: ToolMeta[] = [
  { id: 'pdf-merge', name: 'PDF合并', desc: '多个 PDF 按顺序合成一个文件', category: 'pdf', iconText: 'PDF', path: 'pdf/merge', hot: true, acceptTypes: ['pdf'] },
  { id: 'pdf-split', name: 'PDF拆分', desc: '按页码范围导出新 PDF', category: 'pdf', iconText: 'CUT', path: 'pdf/split', hot: true, acceptTypes: ['pdf'] },
  { id: 'pdf-compress', name: 'PDF压缩', desc: '需接入可靠压缩能力后支持', category: 'pdf', iconText: 'ZIP', path: 'pdf/compress', hot: true, acceptTypes: ['pdf'] },
  { id: 'pdf-watermark', name: 'PDF加水印', desc: '为 PDF 页面添加文字水印', category: 'pdf', iconText: 'WM', path: 'pdf/watermark', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-encrypt', name: 'PDF加密', desc: '需接入成熟 PDF 加密能力', category: 'pdf', iconText: 'KEY', path: 'pdf/encrypt', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-delete-pages', name: 'PDF删除页面', desc: '删除指定页码并导出新文件', category: 'pdf', iconText: 'DEL', path: 'pdf/delete-pages', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-reorder', name: 'PDF页面排序', desc: '按新的页码顺序重排 PDF', category: 'pdf', iconText: 'ORD', path: 'pdf/reorder', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-to-long-image', name: 'PDF转长图', desc: '需接入 PDF 渲染能力后支持', category: 'pdf', iconText: 'IMG', path: 'pdf/to-long-image', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-extract-images', name: 'PDF提取图片', desc: '需接入资源解析或渲染能力', category: 'pdf', iconText: 'EXT', path: 'pdf/extract-images', hot: false, acceptTypes: ['pdf'] },
  { id: 'image-to-pdf', name: '图片转PDF', desc: '多张图片按顺序生成 PDF', category: 'toPdf', iconText: 'IMG', path: 'convert/image-to-pdf', hot: true, acceptTypes: ['jpg', 'jpeg', 'png'] },
  { id: 'word-to-pdf', name: 'Word转PDF', desc: '需接入服务端转换能力', category: 'toPdf', iconText: 'DOC', path: 'convert/word-to-pdf', hot: false, acceptTypes: ['doc', 'docx'] },
  { id: 'excel-to-pdf', name: 'Excel转PDF', desc: '需接入服务端转换能力', category: 'toPdf', iconText: 'XLS', path: 'convert/excel-to-pdf', hot: false, acceptTypes: ['xls', 'xlsx', 'csv'] },
  { id: 'ppt-to-pdf', name: 'PPT转PDF', desc: '需接入服务端转换能力', category: 'toPdf', iconText: 'PPT', path: 'convert/ppt-to-pdf', hot: false, acceptTypes: ['ppt', 'pptx'] },
  { id: 'text-to-pdf', name: '文本转PDF', desc: '文本内容自动分页生成 PDF', category: 'toPdf', iconText: 'TXT', path: 'convert/text-to-pdf', hot: false, acceptTypes: ['txt'] },
  { id: 'pdf-to-word', name: 'PDF转Word', desc: '需接入服务端转换能力', category: 'fromPdf', iconText: 'DOC', path: 'pdf-to/word', hot: true, acceptTypes: ['pdf'] },
  { id: 'pdf-to-excel', name: 'PDF转Excel', desc: '需接入服务端转换能力', category: 'fromPdf', iconText: 'XLS', path: 'pdf-to/excel', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-to-ppt', name: 'PDF转PPT', desc: '需接入服务端转换能力', category: 'fromPdf', iconText: 'PPT', path: 'pdf-to/ppt', hot: false, acceptTypes: ['pdf'] },
  { id: 'pdf-to-images', name: 'PDF转图片', desc: '需接入 PDF 渲染能力后支持', category: 'fromPdf', iconText: 'PNG', path: 'pdf-to/images', hot: true, acceptTypes: ['pdf'] },
  { id: 'camera-to-pdf', name: '拍照生成PDF', desc: '连续拍照整理成扫描 PDF', category: 'scan', iconText: 'CAM', path: 'scan/camera-to-pdf', hot: true, acceptTypes: ['jpg', 'jpeg', 'png'] },
  { id: 'document-scan', name: '文件扫描', desc: '逐张拍照预览，添加水印生成 PDF', category: 'scan', iconText: 'SCAN', path: 'scan/document-scan', hot: true, acceptTypes: ['jpg', 'jpeg', 'png'] },
  { id: 'id-scan', name: '证件扫描', desc: '身份证、驾驶证、护照快速生成 PDF', category: 'scan', iconText: 'ID', path: 'scan/id-scan', hot: false, acceptTypes: ['jpg', 'jpeg', 'png'] }
];

export const TOOL_CONFIGS: Record<string, ToolConfig> = {
  'pdf-merge': { processor: 'mergePdf', pickMode: 'file', multiple: true, maxCount: 9, resultExt: 'pdf', actionText: '开始合并', description: '选择多个 PDF 后，可通过上移下移调整合并顺序。', settings: [] },
  'pdf-split': { processor: 'splitPdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '开始拆分', description: '输入页码范围，例如 1-3,5,8-10。', settings: [{ key: 'ranges', label: '页码范围', type: 'input', placeholder: '1-3,5', hint: '支持单页和区间，例如 1-3,5 表示导出第 1 到 3 页和第 5 页。' }, { key: 'splitEveryPage', label: '每页独立拆分', type: 'switch', value: false, hint: '当前原生版先导出选中页，批量 zip 将在后续版本接入。' }] },
  'pdf-compress': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '开始压缩', description: '真实压缩需要可靠 PDF 重写/图像重采样能力，当前版本需接入服务端转换能力。', settings: [{ key: 'level', label: '压缩等级', type: 'radio', options: ['轻度压缩', '中度压缩', '强力压缩'], value: '中度压缩' }] },
  'pdf-watermark': { processor: 'watermarkPdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '添加水印', description: '为每页追加文字水印。', settings: [{ key: 'text', label: '水印文字', type: 'input', value: '文件处理工具箱' }, { key: 'opacity', label: '透明度', type: 'slider', value: 35, min: 10, max: 90 }, { key: 'fontSize', label: '字号', type: 'slider', value: 32, min: 16, max: 72 }, { key: 'angle', label: '角度', type: 'slider', value: -30, min: -60, max: 60 }, { key: 'position', label: '位置', type: 'radio', options: ['居中', '左上', '右上', '左下', '右下', '平铺'], value: '居中' }] },
  'pdf-encrypt': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '开始加密', description: '成熟 PDF 加密能力需要接入专用库或服务端转换能力。', settings: [{ key: 'password', label: '打开密码', type: 'password', placeholder: '请输入 1-32 位数字或字母' }, { key: 'confirmPassword', label: '确认密码', type: 'password', placeholder: '请再次输入打开密码' }] },
  'pdf-delete-pages': { processor: 'deletePdfPages', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '删除页面', description: '输入需要删除的页码，例如 2,4,6-8。', settings: [{ key: 'pages', label: '删除页码', type: 'input', placeholder: '2,4,6-8' }] },
  'pdf-reorder': { processor: 'reorderPdfPages', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '重排页面', description: '输入新顺序，例如 3,1,2,4。', settings: [{ key: 'order', label: '新页码顺序', type: 'input', placeholder: '3,1,2,4' }] },
  'pdf-to-long-image': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'png', actionText: '生成长图', description: 'PDF 渲染和长图拼接需接入服务端转换能力。', settings: [{ key: 'quality', label: '清晰度', type: 'radio', options: ['普通', '高清', '超清'], value: '高清' }] },
  'pdf-extract-images': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'png', actionText: '提取图片', description: '复杂 PDF 图片资源提取需接入服务端转换能力。', settings: [] },
  'image-to-pdf': { processor: 'imagesToPdf', pickMode: 'image', multiple: true, maxCount: 50, resultExt: 'pdf', actionText: '生成PDF', description: '选择图片后按顺序生成 PDF，最多支持 50 张。', settings: [{ key: 'pageSize', label: '页面尺寸', type: 'radio', options: ['A4', 'A5', '原图尺寸'], value: 'A4' }, { key: 'direction', label: '方向', type: 'radio', options: ['竖向', '横向'], value: '竖向' }, { key: 'margin', label: '边距', type: 'radio', options: ['无边距', '窄边距', '普通边距'], value: '普通边距' }] },
  'word-to-pdf': { processor: 'remoteOffice', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '转换为PDF', description: 'Word 原样转 PDF 需要 Office 渲染或服务端转换能力；当前版本不会生成内容或样式错误的 PDF。', settings: [] },
  'excel-to-pdf': { processor: 'remoteOffice', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '转换为PDF', description: 'Excel 原样转 PDF 需要服务端转换能力；当前原生版仅保留入口和参数流程。', settings: [{ key: 'direction', label: '方向', type: 'radio', options: ['竖向', '横向'], value: '横向' }] },
  'ppt-to-pdf': { processor: 'remoteOffice', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '转换为PDF', description: 'PPT 原样转 PDF 需要服务端转换能力；当前原生版仅保留入口和参数流程。', settings: [] },
  'text-to-pdf': { processor: 'textToPdf', pickMode: 'text', multiple: false, maxCount: 1, resultExt: 'pdf', actionText: '生成PDF', description: '输入或读取 txt 内容，自动分页。', settings: [{ key: 'title', label: '标题', type: 'input', value: '文本文件' }, { key: 'fontSize', label: '字号', type: 'slider', value: 16, min: 12, max: 28 }, { key: 'lineHeight', label: '行距', type: 'slider', value: 1.6, min: 1.2, max: 2.4, step: 0.1 }, { key: 'pageSize', label: '页面尺寸', type: 'radio', options: ['A4', 'A5'], value: 'A4' }] },
  'pdf-to-word': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'docx', actionText: '转换为Word', description: 'PDF 转 Word 需要文本结构恢复和版式重建能力，当前版本需接入服务端转换能力。', settings: [] },
  'pdf-to-excel': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'xlsx', actionText: '转换为Excel', description: 'PDF 转 Excel 需要表格识别能力，当前版本需接入服务端转换能力。', settings: [] },
  'pdf-to-ppt': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'pptx', actionText: '转换为PPT', description: 'PDF 转 PPT 需要页面渲染和结构重建能力，当前版本需接入服务端转换能力。', settings: [{ key: 'mode', label: '转换模式', type: 'radio', options: ['图片模式', '文本模式'], value: '图片模式' }] },
  'pdf-to-images': { processor: 'remotePdf', pickMode: 'file', multiple: false, maxCount: 1, resultExt: 'png', actionText: '导出图片', description: 'PDF 转图片需要渲染引擎，当前版本需接入服务端转换能力。', settings: [{ key: 'format', label: '导出格式', type: 'radio', options: ['PNG', 'JPG'], value: 'PNG' }, { key: 'quality', label: '清晰度', type: 'radio', options: ['普通', '高清', '超清'], value: '高清' }] },
  'camera-to-pdf': { processor: 'imagesToPdf', pickMode: 'camera', multiple: true, maxCount: 50, resultExt: 'pdf', actionText: '生成扫描PDF', description: '拍照后可排序并生成 PDF，最多支持 50 张。', settings: [{ key: 'pageSize', label: '页面尺寸', type: 'radio', options: ['A4', 'A5'], value: 'A4' }, { key: 'margin', label: '边距', type: 'radio', options: ['无边距', '窄边距', '普通边距'], value: '窄边距' }] },
  'document-scan': { processor: 'documentScan', pickMode: 'camera', multiple: true, maxCount: 50, resultExt: 'pdf', actionText: '生成扫描PDF', description: '拍照或从相册选择，排序后生成带水印的扫描 PDF，最多支持 50 张。', settings: [] },
  'id-scan': { processor: 'scanImage', pickMode: 'camera', multiple: true, maxCount: 2, resultExt: 'pdf', actionText: '生成证件PDF', pickTitle: '拍照或选择证件图片', pickDesc: '适用于身份证、驾驶证、护照等证件，最多选择 2 张图片。', description: '快速扫描证件生成 PDF，可用于保存、分享或打印。', settings: [{ key: 'layout', label: 'PDF排版', type: 'radio', options: ['1页PDF', '2页PDF'], value: '1页PDF', hint: '1页PDF 会把两张证件图排在同一页；2页PDF 会把每张图片单独放到一页。' }, { key: 'effect', label: '增强效果', type: 'radio', options: ['增强', '原图'], value: '增强', hint: '增强会轻微提升证件图对比度，适合打印和查看。' }] }
};

export function getToolById(id: string): ToolMeta | undefined {
  return TOOLS.find((tool: ToolMeta) => tool.id === id);
}

export function getConfigByToolId(id: string): ToolConfig {
  return TOOL_CONFIGS[id];
}

export function getToolsByCategory(category: CategoryMeta | string): ToolMeta[] {
  const id = typeof category === 'string' ? category : category.id;
  if (id === 'hot') {
    return TOOLS.filter((tool: ToolMeta) => tool.hot);
  }
  return TOOLS.filter((tool: ToolMeta) => tool.category === id);
}
