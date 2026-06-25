import { fileIo, fileUri } from '@kit.CoreFileKit';
import { filePreview } from '@kit.PreviewKit';
import { findImageFormatTarget, isImageExt } from '../constants/ImageFormatConstants';
import { bytesToText, fileStem, generateId } from '../utils/FormatUtils';
import { AppContext } from './AppContext';

export interface PreviewFileInfo {
  name: string;
  path: string;
}

const PDF_PREVIEW_CACHE_DIR = 'pdf_preview';

export class FilePreviewService {
  static toPreviewUri(path: string): string {
    if (path.startsWith('file://') || path.startsWith('datashare://')) {
      return path;
    }
    return fileUri.getUriFromPath(path);
  }

  static ext(name: string): string {
    const clean = (name || '').split('?')[0];
    const dot = clean.lastIndexOf('.');
    return dot >= 0 ? clean.substring(dot + 1).toLowerCase() : '';
  }

  static mimeType(name: string): string {
    const ext = FilePreviewService.ext(name);
    const imageFormat = findImageFormatTarget(ext);
    if (imageFormat) {
      return imageFormat.mime;
    }
    if (ext === 'pdf') {
      return 'application/pdf';
    }
    if (ext === 'txt') {
      return 'text/plain';
    }
    if (ext === 'doc') {
      return 'application/msword';
    }
    if (ext === 'docx') {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (ext === 'xls') {
      return 'application/vnd.ms-excel';
    }
    if (ext === 'xlsx') {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (ext === 'ppt') {
      return 'application/vnd.ms-powerpoint';
    }
    if (ext === 'pptx') {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    return 'application/octet-stream';
  }

  static isImage(name: string): boolean {
    return isImageExt(FilePreviewService.ext(name));
  }

  static isPdf(name: string): boolean {
    return FilePreviewService.ext(name) === 'pdf';
  }

  static isPdfFile(name: string, path: string = ''): boolean {
    return FilePreviewService.isPdf(name) || FilePreviewService.ext(path) === 'pdf';
  }

  static isText(name: string): boolean {
    const ext = FilePreviewService.ext(name);
    return ext === 'txt' || ext === 'md' || ext === 'csv' || ext === 'log';
  }

  static isOffice(name: string): boolean {
    const ext = FilePreviewService.ext(name);
    return ext === 'doc' || ext === 'docx' || ext === 'xls' || ext === 'xlsx' || ext === 'ppt' || ext === 'pptx';
  }

  static displayType(name: string): string {
    if (FilePreviewService.isPdf(name)) {
      return 'PDF 文档';
    }
    if (FilePreviewService.isImage(name)) {
      return '图片文件';
    }
    if (FilePreviewService.isText(name)) {
      return '文本文件';
    }
    if (FilePreviewService.isOffice(name)) {
      return 'Office 文档';
    }
    const ext = FilePreviewService.ext(name);
    return ext.length ? `${ext.toUpperCase()} 文件` : '文件';
  }

  static readBytes(path: string): Uint8Array {
    const opened = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(opened.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(opened.fd, buffer);
      return new Uint8Array(buffer);
    } finally {
      fileIo.closeSync(opened);
    }
  }

  static readTextPreview(path: string, maxLength: number = 3000): string {
    const text = bytesToText(FilePreviewService.readBytes(path));
    return text.length > maxLength ? `${text.substring(0, maxLength)}\n...` : text;
  }

  static estimatePdfPageCount(path: string): number {
    try {
      const text = bytesToText(FilePreviewService.readBytes(path));
      const matches = text.match(/\/Type\s*\/Page\b/g);
      return matches && matches.length > 0 ? matches.length : 1;
    } catch (_) {
      return 0;
    }
  }

  private static previewCacheDir(): string {
    const context = AppContext.getContext();
    const dir = `${context.cacheDir}/${PDF_PREVIEW_CACHE_DIR}`;
    try {
      fileIo.mkdirSync(dir);
    } catch (_) {
    }
    return dir;
  }

  static preparePdfReaderPath(info: PreviewFileInfo): string {
    if (!info.path.length) {
      return '';
    }
    if (!info.path.includes('://')) {
      return info.path;
    }

    const ext = FilePreviewService.ext(info.name) || FilePreviewService.ext(info.path) || 'pdf';
    const stem = fileStem(info.name) || 'preview';
    const targetPath = `${FilePreviewService.previewCacheDir()}/${stem}_${generateId('pdf')}.${ext}`;
    const bytes = FilePreviewService.readBytes(info.path);
    const opened = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.READ_WRITE);
    try {
      fileIo.writeSync(opened.fd, bytes.buffer);
    } finally {
      fileIo.closeSync(opened);
    }
    return targetPath;
  }

  static cleanupPreparedPdfPath(path: string): void {
    if (!path.length) {
      return;
    }
    const dir = FilePreviewService.previewCacheDir();
    if (!path.startsWith(`${dir}/`)) {
      return;
    }
    try {
      fileIo.unlinkSync(path);
    } catch (_) {
    }
  }

  static async canPreview(info: PreviewFileInfo): Promise<boolean> {
    const context = AppContext.getContext();
    return await filePreview.canPreview(context, FilePreviewService.toPreviewUri(info.path));
  }

  static async openPreview(info: PreviewFileInfo): Promise<void> {
    const context = AppContext.getContext();
    await filePreview.openPreview(context, {
      title: info.name,
      uri: FilePreviewService.toPreviewUri(info.path),
      mimeType: FilePreviewService.mimeType(info.name)
    });
  }
}
