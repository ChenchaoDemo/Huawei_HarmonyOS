import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { findImageFormatTarget, ImageFormatTarget, matchesImageFormatMime } from '../constants/ImageFormatConstants';
import { PickedFile, ProcessorRequest, ProcessorResult } from '../models/ToolModels';
import { AppContext } from '../services/AppContext';
import { FileService } from '../services/FileService';
import { fileStem, generateId } from '../utils/FormatUtils';
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

function targetFormat(request: ProcessorRequest): ImageFormatTarget {
  const raw = String(value(request, 'format', 'PNG')).toUpperCase();
  const target = findImageFormatTarget(raw);
  if (!target) {
    throw new Error(`暂不支持转换为 ${raw}`);
  }
  return target;
}

function qualityValue(request: ProcessorRequest): number {
  const parsed = Number(value(request, 'quality', 92));
  if (parsed !== parsed) {
    return 92;
  }
  return Math.max(1, Math.min(100, Math.round(parsed)));
}

function ensureConvertTempDir(): string {
  const context = AppContext.getContext();
  const dir = `${context.cacheDir}/image_format_convert`;
  try {
    fileIo.mkdirSync(dir);
  } catch (_) {
  }
  return dir;
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

export async function convertImageFormat(request: ProcessorRequest): Promise<ProcessorResult> {
  if (request.files.length !== 1) {
    throw new Error('图片格式转换每次只能选择 1 张图片');
  }

  const file = request.files[0];
  const target = targetFormat(request);
  const quality = qualityValue(request);
  const sourceBytes = FileService.readFile(file);
  const source = image.createImageSource(sourceBytes.buffer);
  const packer = image.createImagePacker();
  const tempDir = ensureConvertTempDir();
  const tempName = `${fileStem(file.name) || 'image'}_${generateId('convert')}.${target.ext}`;
  const tempPath = `${tempDir}/${tempName}`;
  let opened: fileIo.File | undefined = undefined;

  try {
    const supportedFormats = packer.supportedFormats.map((format: string) => format.toLowerCase());
    if (supportedFormats.length > 0 && !supportedFormats.some((format: string) => matchesImageFormatMime(target, format))) {
      throw new Error(`当前系统暂不支持导出 ${target.label} 格式`);
    }

    opened = fileIo.openSync(tempPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.READ_WRITE);
    await packer.packToFile(source, opened.fd, {
      format: target.mime,
      quality
    });
    const packedBytes = FileService.readFile({ id: generateId('convert'), name: tempName, uri: tempPath, size: 0, ext: target.ext, type: target.label });
    const sourceExt = file.ext ? file.ext.toUpperCase() : '图片';
    return {
      content: packedBytes,
      ext: target.ext,
      summary: `已将 ${sourceExt} 转换为 ${target.label}${target.qualitySensitive ? `，质量 ${quality}` : ''}`
    };
  } finally {
    if (opened) {
      try {
        fileIo.closeSync(opened);
      } catch (_) {
      }
    }
    try {
      fileIo.unlinkSync(tempPath);
    } catch (_) {
    }
    try {
      await source.release();
    } catch (_) {
    }
    try {
      await packer.release();
    } catch (_) {
    }
  }
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
