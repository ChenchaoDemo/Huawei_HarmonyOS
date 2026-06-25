export interface ImageFormatTarget {
  label: string;
  ext: string;
  mime: string;
  aliasExts?: string[];
  mimeAliases?: string[];
  qualitySensitive: boolean;
  hint: string;
}

export const IMAGE_FORMAT_TARGETS: ImageFormatTarget[] = [
  { label: 'PNG', ext: 'png', mime: 'image/png', qualitySensitive: false, hint: 'PNG 适合保留透明背景、截图和图形边缘，通常接近无损，文件体积往往比 JPG 更大。' },
  { label: 'JPG', ext: 'jpg', mime: 'image/jpeg', aliasExts: ['jpeg'], qualitySensitive: true, hint: 'JPG 适合照片和日常分享，不支持透明背景，质量越高越清晰，体积也会更大。' },
  { label: 'WEBP', ext: 'webp', mime: 'image/webp', qualitySensitive: true, hint: 'WEBP 适合网页和轻量分享，通常能在保持清晰的同时得到更小体积。' },
  { label: 'BMP', ext: 'bmp', mime: 'image/bmp', mimeAliases: ['image/x-ms-bmp'], qualitySensitive: false, hint: 'BMP 编码直接、兼容性好，但文件通常较大，适合少量本地交换。' },
  { label: 'GIF', ext: 'gif', mime: 'image/gif', qualitySensitive: false, hint: 'GIF 更适合简单图形和少色彩图片，静态图片也可导出，但色彩表现会受限。' },
  { label: 'TIFF', ext: 'tiff', mime: 'image/tiff', aliasExts: ['tif'], qualitySensitive: false, hint: 'TIFF 更偏向高保真存档和印刷流程，通常保留更多细节，但体积较大。' },
  { label: 'ICO', ext: 'ico', mime: 'image/x-icon', mimeAliases: ['image/vnd.microsoft.icon', 'image/ico'], qualitySensitive: false, hint: 'ICO 适合图标文件导出，常用于应用或网页图标，不适合普通照片长期保存。' },
  { label: 'HEIC', ext: 'heic', mime: 'image/heic', qualitySensitive: true, hint: 'HEIC 压缩效率高，适合移动设备存储，同等清晰度下通常比 JPG 更省空间。' },
  { label: 'HEIF', ext: 'heif', mime: 'image/heif', qualitySensitive: true, hint: 'HEIF 与 HEIC 类似，适合高压缩存储场景，但部分旧设备或旧软件兼容性一般。' },
  { label: 'AVIF', ext: 'avif', mime: 'image/avif', qualitySensitive: true, hint: 'AVIF 压缩率很高，适合追求更小体积的场景，但兼容性通常弱于 JPG 和 PNG。' }
];

function uniqueStrings(values: string[]): string[] {
  const result: string[] = [];
  values.forEach((value: string) => {
    const normalized = value.toLowerCase();
    if (!result.includes(normalized)) {
      result.push(normalized);
    }
  });
  return result;
}

export const IMAGE_FORMAT_OPTION_LABELS: string[] = IMAGE_FORMAT_TARGETS.map((item: ImageFormatTarget) => item.label);

export const IMAGE_CONVERT_ACCEPT_TYPES: string[] = uniqueStrings(IMAGE_FORMAT_TARGETS.reduce((types: string[], item: ImageFormatTarget) => {
  types.push(item.ext);
  (item.aliasExts || []).forEach((alias: string) => types.push(alias));
  return types;
}, []));

export function findImageFormatTarget(raw: string): ImageFormatTarget | undefined {
  const key = (raw || '').trim().toLowerCase();
  return IMAGE_FORMAT_TARGETS.find((item: ImageFormatTarget) => {
    return item.label.toLowerCase() === key
      || item.ext === key
      || (item.aliasExts || []).includes(key);
  });
}

export function imageFormatExt(raw: string, fallback: string = 'png'): string {
  return findImageFormatTarget(raw)?.ext || fallback;
}

export function isImageExt(raw: string): boolean {
  return findImageFormatTarget(raw) !== undefined;
}

export function matchesImageFormatMime(target: ImageFormatTarget, rawMime: string): boolean {
  const mime = (rawMime || '').trim().toLowerCase();
  return target.mime.toLowerCase() === mime || (target.mimeAliases || []).includes(mime);
}

export function imageFormatHint(raw: string): string {
  return findImageFormatTarget(raw)?.hint || '请选择适合用途的目标格式，系统仅会在当前设备支持时完成导出。';
}
