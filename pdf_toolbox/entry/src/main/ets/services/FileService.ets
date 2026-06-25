import { picker } from '@kit.CoreFileKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { PickedFile, SavedFile } from '../models/ToolModels';
import { isImageExt } from '../constants/ImageFormatConstants';
import { concatBytes, fileStem, getExt, generateId, textToBytes } from '../utils/FormatUtils';
import { AppContext } from './AppContext';
import { PermissionService } from './PermissionService';

const TEMP_DIR_NAME = 'pdf_toolbox';
const MAX_FILE_SIZE = 80 * 1024 * 1024;

function normalizeName(uri: string, index: number, fallbackExt: string = ''): string {
  const clean = uri.split('?')[0];
  const slashParts = clean.split('/');
  const raw = slashParts[slashParts.length - 1] || `文件${index + 1}`;
  let name = raw;
  try {
    name = decodeURIComponent(raw);
  } catch (_) {
  }
  if (fallbackExt.length > 0 && getExt(name).length === 0) {
    return `${name}.${fallbackExt}`;
  }
  return name;
}

function normalizeFile(uri: string, index: number, fallbackExt: string = ''): PickedFile {
  const name = normalizeName(uri, index, fallbackExt);
  let size = 0;
  try {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const stat = fileIo.statSync(file.fd);
    size = stat.size;
    fileIo.closeSync(file);
  } catch (_) {
    size = 0;
  }
  const ext = getExt(name) || fallbackExt;
  return {
    id: generateId('file'),
    name: name || `文件${index + 1}`,
    uri,
    size,
    ext,
    type: ext ? ext.toUpperCase() : 'FILE'
  };
}

function validate(files: PickedFile[], acceptTypes: string[]): void {
  if (acceptTypes.length > 0) {
    const normalizedTypes = acceptTypes.map((item: string) => item.toLowerCase());
    const invalid = files.find((file: PickedFile) => file.ext.length > 0 && !normalizedTypes.includes(file.ext));
    if (invalid) {
      throw new Error(`文件格式不支持：${invalid.name}`);
    }
  }
  const oversize = files.find((file: PickedFile) => file.size > MAX_FILE_SIZE);
  if (oversize) {
    throw new Error(`文件过大：${oversize.name}`);
  }
}

function tempDir(): string {
  const context = AppContext.getContext();
  return `${context.filesDir}/${TEMP_DIR_NAME}`;
}

function ensureTempDir(): string {
  const dir = tempDir();
  try {
    fileIo.mkdirSync(dir);
  } catch (_) {
  }
  return dir;
}

export class FileService {
  static async pickDocuments(count: number, acceptTypes: string[]): Promise<PickedFile[]> {
    await PermissionService.ensureDocumentReadPermission();
    const documentPicker = new picker.DocumentViewPicker();
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = count;
    if (acceptTypes.length > 0) {
      options.fileSuffixFilters = acceptTypes.map((item: string) => `.${item}`);
    }
    const uris = await documentPicker.select(options);
    const fallbackExt = acceptTypes.length === 1 ? acceptTypes[0].toLowerCase() : '';
    const files = uris.map((uri: string, index: number) => normalizeFile(uri, index, fallbackExt));
    validate(files, acceptTypes);
    return files;
  }

  static async pickImages(count: number, acceptTypes: string[] = ['jpg', 'jpeg', 'png']): Promise<PickedFile[]> {
    await PermissionService.ensureImageReadPermission();
    const photoPicker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = count;
    const result = await photoPicker.select(options);
    const fallbackExt = acceptTypes.includes('jpg') ? 'jpg' : (acceptTypes[0] || 'jpg');
    const files = result.photoUris.map((uri: string, index: number) => normalizeFile(uri, index, fallbackExt));
    validate(files, acceptTypes);
    return files;
  }

  static readFile(file: PickedFile): Uint8Array {
    const opened = fileIo.openSync(file.uri, fileIo.OpenMode.READ_ONLY);
    try {
      const stat = fileIo.statSync(opened.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(opened.fd, buffer);
      return new Uint8Array(buffer);
    } finally {
      fileIo.closeSync(opened);
    }
  }

  static readText(file: PickedFile): string {
    const bytes = FileService.readFile(file);
    let text = '';
    for (let i = 0; i < bytes.length; i += 1) {
      text += String.fromCharCode(bytes[i]);
    }
    try {
      return decodeURIComponent(escape(text));
    } catch (_) {
      return text;
    }
  }

  static saveTempFile(content: Uint8Array | string, fileName: string): SavedFile {
    const dir = ensureTempDir();
    const path = `${dir}/${fileName}`;
    const bytes = typeof content === 'string' ? textToBytes(content) : content;
    const opened = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.READ_WRITE);
    try {
      fileIo.writeSync(opened.fd, bytes.buffer);
    } finally {
      fileIo.closeSync(opened);
    }
    return { name: fileName, path, size: bytes.length };
  }

  static async saveToPicker(path: string, fileName: string): Promise<boolean> {
    const documentPicker = new picker.DocumentViewPicker();
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    const targetUris = await documentPicker.save(options);
    if (!targetUris.length) {
      return false;
    }
    const bytes = FileService.readFile({ id: 'saved', name: fileName, uri: path, size: 0, ext: getExt(fileName), type: 'FILE' });
    const opened = fileIo.openSync(targetUris[0], fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.READ_WRITE);
    try {
      fileIo.writeSync(opened.fd, bytes.buffer);
    } finally {
      fileIo.closeSync(opened);
    }
    return true;
  }

  static async saveImageToAlbum(path: string, fileName: string): Promise<boolean> {
    const helper = photoAccessHelper.getPhotoAccessHelper(AppContext.getContext());
    const sourceUri = fileUri.getUriFromPath(path);
    const ext = getExt(fileName) || 'jpg';
    const title = fileStem(fileName) || 'image';
    const created = await helper.showAssetsCreationDialog([sourceUri], [{
      title,
      fileNameExtension: ext,
      photoType: photoAccessHelper.PhotoType.IMAGE
    }]);
    return created.length > 0;
  }

  static async saveOutput(path: string, fileName: string): Promise<'album' | 'document' | ''> {
    if (isImageExt(getExt(fileName))) {
      try {
        const savedToAlbum = await FileService.saveImageToAlbum(path, fileName);
        if (savedToAlbum) {
          return 'album';
        }
        return '';
      } catch (_) {
        const savedToPicker = await FileService.saveToPicker(path, fileName);
        return savedToPicker ? 'document' : '';
      }
    }
    const savedToPicker = await FileService.saveToPicker(path, fileName);
    return savedToPicker ? 'document' : '';
  }

  static clearTempFiles(): void {
    const dir = ensureTempDir();
    try {
      const names = fileIo.listFileSync(dir);
      names.forEach((name: string) => {
        try {
          fileIo.unlinkSync(`${dir}/${name}`);
        } catch (_) {
        }
      });
    } catch (_) {
    }
  }

  static mergeBytesWithSeparator(chunks: Uint8Array[]): Uint8Array {
    const separator = textToBytes('\n');
    const out: Uint8Array[] = [];
    chunks.forEach((chunk: Uint8Array, index: number) => {
      if (index > 0) {
        out.push(separator);
      }
      out.push(chunk);
    });
    return concatBytes(out);
  }
}
