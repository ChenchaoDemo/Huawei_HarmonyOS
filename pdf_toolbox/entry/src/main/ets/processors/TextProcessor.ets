import { ProcessorRequest, ProcessorResult } from '../models/ToolModels';
import { FileService } from '../services/FileService';
import { createPdfFromText } from './SimplePdfWriter';

function value(request: ProcessorRequest, key: string, fallback: string | number | boolean): string | number | boolean {
  const item = request.settings.get(key);
  return item === undefined ? fallback : item;
}

export async function textToPdf(request: ProcessorRequest): Promise<ProcessorResult> {
  let contentText = request.text || '';
  if (!contentText.trim() && request.files.length > 0) {
    contentText = FileService.readText(request.files[0]);
  }
  if (!contentText.trim()) {
    throw new Error('文本内容为空');
  }
  const fontSize = Number(value(request, 'fontSize', 16));
  const lineHeight = Number(value(request, 'lineHeight', 1.6));
  return {
    content: createPdfFromText(contentText, {
      title: String(value(request, 'title', '文本文件')),
      fontSize,
      lineHeight: fontSize * lineHeight,
      pageSize: String(value(request, 'pageSize', 'A4'))
    }),
    ext: 'pdf',
    summary: `已生成 ${contentText.length} 字文本 PDF`
  };
}
