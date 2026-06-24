import { fileIo, fileUri } from '@kit.CoreFileKit';
import { filePreview } from '@kit.PreviewKit';
import { bytesToText } from '../utils/FormatUtils';
import { AppContext } from './AppContext';

export interface PreviewFileInfo {
  name: string;
  path: string;
}

export class FilePreviewService {
  static toPreviewUri(path: string): string {
    if (path.startsWith('file://') || path.startsWith('datashare://')) {
      return path;
    }
    return fileUri.getUriFromPath(path);
  }

  static ext(name: string): string {
    const dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  static mimeType(name: string): string {
    const ext = FilePreviewService.ext(name);
    if (ext === 'pdf') {
      return 'application/pdf';
    }
    if (ext === 'png') {
      return 'image/png';
    }
    if (ext === 'jpg' || ext === 'jpeg') {
      return 'image/jpeg';
    }
    if (ext === 'webp') {
      return 'image/webp';
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
    const ext = FilePreviewService.ext(name);
    return ext === 'png' || ext === 'jpg' || ext === 'jpeg' || ext === 'webp';
  }

  static isPdf(name: string): boolean {
    return FilePreviewService.ext(name) === 'pdf';
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
