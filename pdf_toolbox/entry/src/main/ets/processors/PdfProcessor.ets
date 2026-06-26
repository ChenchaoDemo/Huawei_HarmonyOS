import { PickedFile, ProcessorRequest, ProcessorResult } from '../models/ToolModels';
import { bytesToText } from '../utils/FormatUtils';
import { FileService } from '../services/FileService';
import { PdfDocumentData, countPdfPages, mergePdfDocuments, selectPdfPages, watermarkPdfDocument } from './BasicPdfManipulator';

function readPdf(file: PickedFile): PdfDocumentData {
  return new PdfDocumentData(file.name, FileService.readFile(file));
}

function value(request: ProcessorRequest, key: string, fallback: string | number | boolean): string | number | boolean {
  const item = request.settings.get(key);
  return item === undefined ? fallback : item;
}

function parseRanges(input: string, pageCount: number): number[] {
  const ranges = String(input || '1').split(',').map((item: string) => item.trim()).filter((item: string) => item.length > 0);
  const pages: number[] = [];
  ranges.forEach((range: string) => {
    if (range.includes('-')) {
      const parts = range.split('-');
      const start = Number(parts[0]);
      const end = Number(parts[1]);
      if (!start || !end || start > end || end > pageCount) {
        throw new Error('页码输入错误');
      }
      for (let i = start; i <= end; i += 1) {
        pages.push(i);
      }
    } else {
      const page = Number(range);
      if (!page || page > pageCount) {
        throw new Error('页码输入错误');
      }
      pages.push(page);
    }
  });
  return Array.from(new Set<number>(pages));
}

function parsePageOrder(input: string, pageCount: number): number[] {
  const pages = String(input || '').split(',').map((item: string) => Number(item.trim()));
  if (pages.length !== pageCount || pages.some((page: number) => !Number.isInteger(page) || page < 1 || page > pageCount)) {
    throw new Error('新顺序必须包含全部页面且不重复');
  }
  if (new Set<number>(pages).size !== pageCount) {
    throw new Error('新顺序必须包含全部页面且不重复');
  }
  return pages;
}

export async function mergePdf(request: ProcessorRequest): Promise<ProcessorResult> {
  if (request.files.length < 2) {
    throw new Error('请至少选择两个 PDF 文件');
  }
  const result = mergePdfDocuments(request.files.map((file: PickedFile) => readPdf(file)));
  return {
    content: result.content,
    ext: 'pdf',
    summary: `已合并 ${request.files.length} 个 PDF，共 ${result.pageCount} 页`
  };
}

export async function splitPdf(request: ProcessorRequest): Promise<ProcessorResult> {
  const file = request.files[0];
  if (!file) {
    throw new Error('请选择 PDF 文件');
  }
  if (value(request, 'splitEveryPage', false) === true) {
    throw new Error('每页独立拆分需要 zip 打包能力，当前原生版先支持页码范围导出');
  }
  const document = readPdf(file);
  const pageCount = countPdfPages(document);
  const pages = parseRanges(String(value(request, 'ranges', '1')), pageCount);
  const result = selectPdfPages(document, pages);
  return {
    content: result.content,
    ext: 'pdf',
    summary: `已导出 ${pages.length} 页`
  };
}

export async function deletePdfPages(request: ProcessorRequest): Promise<ProcessorResult> {
  const file = request.files[0];
  if (!file) {
    throw new Error('请选择 PDF 文件');
  }
  if (!String(value(request, 'pages', '')).trim()) {
    throw new Error('请输入需要删除的页码');
  }
  const document = readPdf(file);
  const pageCount = countPdfPages(document);
  const deleted = parseRanges(String(value(request, 'pages', '')), pageCount);
  if (deleted.length >= pageCount) {
    throw new Error('不能删除所有页面');
  }
  const kept = Array.from({ length: pageCount }, (_: undefined, index: number) => index + 1).filter((page: number) => !deleted.includes(page));
  const result = selectPdfPages(document, kept);
  return {
    content: result.content,
    ext: 'pdf',
    summary: `已删除 ${deleted.length} 页，保留 ${kept.length} 页`
  };
}

export async function reorderPdfPages(request: ProcessorRequest): Promise<ProcessorResult> {
  const file = request.files[0];
  if (!file) {
    throw new Error('请选择 PDF 文件');
  }
  if (!String(value(request, 'order', '')).trim()) {
    throw new Error('请输入新的页码顺序');
  }
  const document = readPdf(file);
  const pageCount = countPdfPages(document);
  const order = parsePageOrder(String(value(request, 'order', '')), pageCount);
  const result = selectPdfPages(document, order);
  return {
    content: result.content,
    ext: 'pdf',
    summary: `已按 ${order.join(', ')} 重排`
  };
}

export async function watermarkPdf(request: ProcessorRequest): Promise<ProcessorResult> {
  const file = request.files[0];
  if (!file) {
    throw new Error('请选择 PDF 文件');
  }
  const text = String(value(request, 'text', '文件处理工具箱')).trim();
  if (!text) {
    throw new Error('请输入水印文字');
  }
  const document = readPdf(file);
  const result = watermarkPdfDocument(document, {
    text: text.slice(0, 64),
    opacity: Number(value(request, 'opacity', 35)),
    fontSize: Number(value(request, 'fontSize', 32)),
    angle: Number(value(request, 'angle', -30)),
    position: String(value(request, 'position', '居中')),
    color: '#8A93A8'
  });
  return {
    content: result.content,
    ext: 'pdf',
    summary: `已为 ${result.pageCount} 页添加文字水印`
  };
}

export function estimatePageCountFromBytes(bytes: Uint8Array): number {
  const text = bytesToText(bytes);
  const matches = text.match(/\/Type\s*\/Page\b/g);
  return matches ? matches.length : 1;
}
