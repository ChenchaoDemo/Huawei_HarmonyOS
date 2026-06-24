import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { APP_NAME } from '../constants/AppConstants';
import { AppContext } from './AppContext';
import { FilePreviewService } from './FilePreviewService';

export interface ShareFileInfo {
  name: string;
  path: string;
  summary?: string;
}

export class ShareService {
  private static utd(name: string): string {
    const ext = FilePreviewService.ext(name);
    if (ext === 'pdf') {
      return uniformTypeDescriptor.UniformDataType.PDF;
    }
    if (ext === 'jpg' || ext === 'jpeg') {
      return uniformTypeDescriptor.UniformDataType.JPEG;
    }
    if (ext === 'png') {
      return uniformTypeDescriptor.UniformDataType.PNG;
    }
    if (ext === 'txt' || ext === 'md' || ext === 'csv' || ext === 'log') {
      return uniformTypeDescriptor.UniformDataType.PLAIN_TEXT;
    }
    if (ext === 'doc') {
      return uniformTypeDescriptor.UniformDataType.WORD_DOC;
    }
    if (ext === 'docx') {
      return uniformTypeDescriptor.UniformDataType.WORDPROCESSINGML_DOCUMENT;
    }
    if (ext === 'xls') {
      return uniformTypeDescriptor.UniformDataType.EXCEL;
    }
    if (ext === 'xlsx') {
      return uniformTypeDescriptor.UniformDataType.SPREADSHEETML_SHEET;
    }
    if (ext === 'ppt') {
      return uniformTypeDescriptor.UniformDataType.PPT;
    }
    if (ext === 'pptx') {
      return uniformTypeDescriptor.UniformDataType.PRESENTATIONML_PRESENTATION;
    }
    return uniformTypeDescriptor.UniformDataType.FILE;
  }

  static async shareFile(info: ShareFileInfo): Promise<void> {
    if (!info.path.length) {
      throw new Error('没有可分享的文件');
    }
    const record: systemShare.SharedRecord = {
      utd: ShareService.utd(info.name),
      uri: FilePreviewService.toPreviewUri(info.path),
      title: info.name,
      label: APP_NAME,
      description: info.summary || `${APP_NAME} 处理结果`
    };
    const data = new systemShare.SharedData(record);
    const controller = new systemShare.ShareController(data);
    await controller.show(AppContext.getContext(), {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    });
  }
}
