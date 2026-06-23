import { PickedFile, ProcessorRequest, ProcessorResult } from '../models/ToolModels';
import { FileService } from '../services/FileService';
import { createIdScanPdf, createPdfFromImages } from './SimplePdfWriter';

interface ImagePayload {
  name: string;
  data: Uint8Array;
}

function readImages(files: PickedFile[]): ImagePayload[] {
  if (!files.length) {
    throw new Error('请选择图片');
  }
  return files.map((file: PickedFile): ImagePayload => {
    const payload: ImagePayload = {
      name: file.name,
      data: FileService.readFile(file)
    };
    return payload;
  });
}

function value(request: ProcessorRequest, key: string, fallback: string | number | boolean): string | number | boolean {
  const item = request.settings.get(key);
  return item === undefined ? fallback : item;
}

export async function imagesToPdf(request: ProcessorRequest): Promise<ProcessorResult> {
  const images = readImages(request.files);
  return {
    content: createPdfFromImages(images, {
      pageSize: String(value(request, 'pageSize', 'A4')),
      direction: String(value(request, 'direction', '竖向')),
      margin: String(value(request, 'margin', '普通边距'))
    }),
    ext: 'pdf',
    summary: `已将 ${images.length} 张图片整理为 PDF`
  };
}

export async function scanImage(request: ProcessorRequest): Promise<ProcessorResult> {
  if (request.files.length > 2) {
    throw new Error('证件扫描最多支持 2 张图片');
  }
  const images = readImages(request.files);
  return {
    content: createIdScanPdf(images, {
      pageSize: 'A4',
      direction: '竖向',
      margin: value(request, 'layout', '1页PDF') === '2页PDF' ? '普通边距' : '窄边距'
    }),
    ext: 'pdf',
    summary: `已生成 ${images.length} 张证件图片的扫描件`
  };
}

export async function documentScan(request: ProcessorRequest): Promise<ProcessorResult> {
  const images = readImages(request.files);
  const watermarkEnabled = value(request, 'watermarkEnabled', false) === true && String(value(request, 'watermarkText', '')).trim().length > 0;
  return {
    content: createPdfFromImages(images, {
      pageSize: 'A4',
      direction: String(value(request, 'direction', '竖向')),
      margin: String(value(request, 'margin', '窄边距')),
      watermark: {
        enabled: watermarkEnabled,
        text: String(value(request, 'watermarkText', '文件处理工具箱')),
        position: String(value(request, 'watermarkPosition', '居中')),
        fontSize: Number(value(request, 'watermarkFontSize', 36)),
        color: String(value(request, 'watermarkColor', '#8A93A8')),
        opacity: Number(value(request, 'watermarkOpacity', 32))
      }
    }),
    ext: 'pdf',
    summary: `已将 ${images.length} 张扫描图片生成 PDF${watermarkEnabled ? '，并添加水印' : ''}`
  };
}
