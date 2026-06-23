const INVALID_FILE_CHARS: RegExp = /[\\/:*?"<>|\u0000-\u001F]/g;

export function formatFileSize(size: number): string {
  if (!size || size < 0) {
    return '0 B';
  }
  if (size < 1024) {
    return `${size} B`;
  }
  if (size < 1024 * 1024) {
    return `${(size / 1024).toFixed(1)} KB`;
  }
  return `${(size / 1024 / 1024).toFixed(2)} MB`;
}

export function getExt(name: string): string {
  const clean = (name || '').split('?')[0];
  if (!clean.includes('.')) {
    return '';
  }
  const parts = clean.split('.');
  return parts[parts.length - 1].toLowerCase();
}

export function generateId(prefix: string = 'id'): string {
  return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
}

function pad(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function generateFileName(prefix: string, ext: string): string {
  const now = new Date();
  const stamp = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}${pad(now.getHours())}${pad(now.getMinutes())}`;
  return `${prefix}_${stamp}.${ext}`;
}

export function normalizeOutputFileName(name: string, fallbackPrefix: string, ext: string): string {
  const cleanExt = (ext || 'pdf').replace(/^\./, '').toLowerCase();
  const base = (name || '')
    .trim()
    .replace(INVALID_FILE_CHARS, '_')
    .replace(/\s+/g, ' ')
    .replace(/^\.+/, '')
    .replace(/[. ]+$/, '')
    .slice(0, 80);

  if (!base) {
    return generateFileName(fallbackPrefix || '文件处理工具箱', cleanExt);
  }

  const suffix = `.${cleanExt}`;
  if (base.toLowerCase().endsWith(suffix)) {
    return base;
  }
  return `${base.replace(/\.[^.]+$/, '')}${suffix}`;
}

export function nowText(): string {
  const now = new Date();
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
}

export function bytesToText(bytes: Uint8Array): string {
  let result = '';
  const chunkSize = 8192;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const end = Math.min(i + chunkSize, bytes.length);
    let chunk = '';
    for (let j = i; j < end; j += 1) {
      chunk += String.fromCharCode(bytes[j]);
    }
    result += chunk;
  }
  try {
    return decodeURIComponent(escape(result));
  } catch (_) {
    return result;
  }
}

export function textToBytes(text: string): Uint8Array {
  const encoded = unescape(encodeURIComponent(text));
  const bytes = new Uint8Array(encoded.length);
  for (let i = 0; i < encoded.length; i += 1) {
    bytes[i] = encoded.charCodeAt(i);
  }
  return bytes;
}

export function concatBytes(chunks: Uint8Array[]): Uint8Array {
  const total = chunks.reduce((sum: number, chunk: Uint8Array) => sum + chunk.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  chunks.forEach((chunk: Uint8Array) => {
    out.set(chunk, offset);
    offset += chunk.length;
  });
  return out;
}
