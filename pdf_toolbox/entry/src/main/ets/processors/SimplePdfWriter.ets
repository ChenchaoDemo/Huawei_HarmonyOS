import { concatBytes, textToBytes } from '../utils/FormatUtils';

type PdfChunk = string | Uint8Array;
type PdfBody = string | PdfChunk[];

interface ParsedImage {
  name: string;
  width: number;
  height: number;
  bits: number;
  colorSpace: string;
  data: Uint8Array;
  extra: string;
}

interface PdfImageInput {
  name: string;
  data: Uint8Array;
}

interface WatermarkOptions {
  enabled: boolean;
  text: string;
  position: string;
  fontSize: number;
  color: string;
  opacity: number;
}

interface ImagePdfOptions {
  pageSize?: string;
  direction?: string;
  margin?: string;
  watermark?: WatermarkOptions;
}

interface TextPdfOptions {
  title?: string;
  fontSize?: number;
  lineHeight?: number;
  pageSize?: string;
  direction?: string;
}

const PAGE_SIZES: Record<string, number[]> = {
  'A4': [595, 842],
  'A5': [420, 595]
};

function utf16Hex(text: string): string {
  let hex = 'FEFF';
  for (let i = 0; i < text.length; i += 1) {
    hex += text.charCodeAt(i).toString(16).padStart(4, '0').toUpperCase();
  }
  return `<${hex}>`;
}

function wrapText(text: string, maxChars: number): string[] {
  const lines: string[] = [];
  const normalized = (text || '').replace(/\r/g, '').split('\n');
  normalized.forEach((line: string) => {
    if (!line) {
      lines.push('');
      return;
    }
    for (let i = 0; i < line.length; i += maxChars) {
      lines.push(line.slice(i, i + maxChars));
    }
  });
  return lines.length ? lines : [''];
}

function paginate(lines: string[], linesPerPage: number): string[][] {
  const pages: string[][] = [];
  for (let i = 0; i < lines.length; i += linesPerPage) {
    pages.push(lines.slice(i, i + linesPerPage));
  }
  return pages.length ? pages : [['']];
}

function byteLength(body: PdfBody): number {
  if (typeof body === 'string') {
    return textToBytes(body).length;
  }
  return body.reduce((sum: number, chunk: PdfChunk) => {
    return sum + (typeof chunk === 'string' ? textToBytes(chunk).length : chunk.length);
  }, 0);
}

function normalizeChunk(chunk: PdfChunk): Uint8Array {
  return typeof chunk === 'string' ? textToBytes(chunk) : chunk;
}

function buildPdf(objects: PdfBody[], catalogId: number): Uint8Array {
  const chunks: Uint8Array[] = [];
  const offsets: number[] = [0];
  let length = 0;
  const push = (chunk: PdfChunk): void => {
    const bytes = normalizeChunk(chunk);
    chunks.push(bytes);
    length += bytes.length;
  };

  push('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
  objects.forEach((body: PdfBody, index: number) => {
    offsets.push(length);
    push(`${index + 1} 0 obj\n`);
    if (typeof body === 'string') {
      push(body);
    } else {
      body.forEach((chunk: PdfChunk) => push(chunk));
    }
    push('\nendobj\n');
  });

  const xrefOffset = length;
  push(`xref\n0 ${objects.length + 1}\n`);
  push('0000000000 65535 f \n');
  offsets.slice(1).forEach((offset: number) => {
    push(`${String(offset).padStart(10, '0')} 00000 n \n`);
  });
  push(`trailer\n<< /Size ${objects.length + 1} /Root ${catalogId} 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`);
  return concatBytes(chunks);
}

function readUint32(bytes: Uint8Array, offset: number): number {
  return ((bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3]) >>> 0;
}

function bytesToHex(bytes: Uint8Array): string {
  let hex = '';
  for (let i = 0; i < bytes.length; i += 1) {
    hex += bytes[i].toString(16).padStart(2, '0').toUpperCase();
  }
  return hex;
}

function parseJpeg(bytes: Uint8Array): ParsedImage | undefined {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) {
    return undefined;
  }
  let offset = 2;
  while (offset < bytes.length) {
    while (bytes[offset] === 0xff) {
      offset += 1;
    }
    const marker = bytes[offset];
    offset += 1;
    if (marker === 0xd9 || marker === 0xda) {
      break;
    }
    const length = (bytes[offset] << 8) | bytes[offset + 1];
    if (length < 2) {
      break;
    }
    if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) {
      const bits = bytes[offset + 2];
      const height = (bytes[offset + 3] << 8) | bytes[offset + 4];
      const width = (bytes[offset + 5] << 8) | bytes[offset + 6];
      const components = bytes[offset + 7];
      const colorSpace = components === 1 ? '/DeviceGray' : components === 4 ? '/DeviceCMYK' : '/DeviceRGB';
      const decode = components === 4 ? ' /Decode [1 0 1 0 1 0 1 0]' : '';
      return { name: '', width, height, bits, colorSpace, data: bytes, extra: `/Filter /DCTDecode${decode}` };
    }
    offset += length;
  }
  throw new Error('无法识别 JPG 图片尺寸');
}

function parsePng(bytes: Uint8Array): ParsedImage | undefined {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 12 || !signature.every((value: number, index: number) => bytes[index] === value)) {
    return undefined;
  }
  let offset = 8;
  let width = 0;
  let height = 0;
  let bits = 8;
  let colorType = 2;
  let interlace = 0;
  let palette: Uint8Array | undefined = undefined;
  const idat: Uint8Array[] = [];

  while (offset < bytes.length) {
    const length = readUint32(bytes, offset);
    const type = String.fromCharCode(bytes[offset + 4], bytes[offset + 5], bytes[offset + 6], bytes[offset + 7]);
    const start = offset + 8;
    const end = start + length;
    const data = bytes.slice(start, end);

    if (type === 'IHDR') {
      width = readUint32(data, 0);
      height = readUint32(data, 4);
      bits = data[8];
      colorType = data[9];
      interlace = data[12];
    } else if (type === 'PLTE') {
      palette = data;
    } else if (type === 'IDAT') {
      idat.push(data);
    } else if (type === 'IEND') {
      break;
    }
    offset = end + 4;
  }

  if (!width || !height || idat.length === 0) {
    throw new Error('无法识别 PNG 图片内容');
  }
  if (interlace) {
    throw new Error('暂不支持隔行 PNG，请换成普通 PNG 或 JPG');
  }
  if (![0, 2, 3].includes(colorType)) {
    throw new Error('暂不支持透明 PNG，请先转为 JPG 或无透明 PNG');
  }

  const colors = colorType === 2 ? 3 : 1;
  let colorSpace = colorType === 2 ? '/DeviceRGB' : '/DeviceGray';
  if (colorType === 3) {
    if (!palette) {
      throw new Error('PNG 调色板缺失');
    }
    colorSpace = `[/Indexed /DeviceRGB ${Math.floor(palette.length / 3) - 1} <${bytesToHex(palette)}>]`;
  }

  return {
    name: '',
    width,
    height,
    bits,
    colorSpace,
    data: concatBytes(idat),
    extra: `/Filter /FlateDecode /DecodeParms << /Predictor 15 /Colors ${colors} /BitsPerComponent ${bits} /Columns ${width} >>`
  };
}

function parseImage(image: PdfImageInput): ParsedImage {
  const parsed = parseJpeg(image.data) || parsePng(image.data);
  if (!parsed) {
    throw new Error(`${image.name || '图片'} 格式暂不支持，请使用 JPG 或 PNG`);
  }
  parsed.name = image.name;
  return parsed;
}

function pageSizeForImage(image: ParsedImage, options: ImagePdfOptions): number[] {
  if (options.pageSize === '原图尺寸') {
    return [image.width, image.height];
  }
  const base = PAGE_SIZES[options.pageSize || 'A4'] || PAGE_SIZES.A4;
  return options.direction === '横向' ? [base[1], base[0]] : base;
}

function marginSize(name: string | undefined): number {
  if (name === '无边距') {
    return 0;
  }
  if (name === '窄边距') {
    return 24;
  }
  return 40;
}

function normalizeHexColor(color: string = '#8A93A8'): number[] {
  let value = String(color || '').trim().replace(/^#/, '');
  if (/^[0-9a-fA-F]{3}$/.test(value)) {
    value = value.split('').map((item: string) => item + item).join('');
  }
  if (!/^[0-9a-fA-F]{6}$/.test(value)) {
    value = '8A93A8';
  }
  return [0, 2, 4].map((index: number) => parseInt(value.slice(index, index + 2), 16) / 255);
}

function watermarkPoint(width: number, height: number, text: string, fontSize: number, position: string): number[] {
  const margin = 54;
  const textWidth = text.length * fontSize * 0.62;
  const points: Record<string, number[]> = {
    '左上': [margin, height - margin - fontSize],
    '右上': [width - margin - textWidth, height - margin - fontSize],
    '左下': [margin, margin],
    '右下': [width - margin - textWidth, margin],
    '居中': [(width - textWidth) / 2, (height - fontSize) / 2]
  };
  return points[position] || points['居中'];
}

function watermarkCommands(watermark: WatermarkOptions | undefined, width: number, height: number): string {
  if (!watermark || !watermark.enabled || !watermark.text.trim()) {
    return '';
  }
  const text = watermark.text.trim();
  const fontSize = Math.max(12, Math.min(96, Number(watermark.fontSize || 36)));
  const rgb = normalizeHexColor(watermark.color);
  const point = watermarkPoint(width, height, text, fontSize, watermark.position || '居中');
  return [
    'q',
    '/wm gs',
    `${rgb[0].toFixed(3)} ${rgb[1].toFixed(3)} ${rgb[2].toFixed(3)} rg`,
    'BT',
    `/F1 ${fontSize} Tf`,
    `1 0 0 1 ${Math.max(24, point[0]).toFixed(2)} ${Math.max(24, point[1]).toFixed(2)} Tm`,
    `${utf16Hex(text)} Tj`,
    'ET',
    'Q'
  ].join('\n');
}

export function createPdfFromImages(images: PdfImageInput[], options: ImagePdfOptions = {}): Uint8Array {
  const parsedImages = images.map((image: PdfImageInput) => parseImage(image));
  const objects: PdfBody[] = [];
  const add = (body: PdfBody): number => {
    objects.push(body);
    return objects.length;
  };

  const catalogId = add('placeholder');
  const pagesId = add('placeholder');
  const hasWatermark = !!options.watermark?.enabled;
  const fontDescId = hasWatermark ? add('<< /Type /Font /Subtype /CIDFontType0 /BaseFont /STSong-Light /CIDSystemInfo << /Registry (Adobe) /Ordering (GB1) /Supplement 2 >> /DW 1000 >>') : 0;
  const fontId = hasWatermark ? add(`<< /Type /Font /Subtype /Type0 /BaseFont /STSong-Light /Encoding /UniGB-UCS2-H /DescendantFonts [${fontDescId} 0 R] >>`) : 0;
  const opacity = Math.max(0.08, Math.min(0.9, Number(options.watermark?.opacity || 32) / 100));
  const stateId = hasWatermark ? add(`<< /Type /ExtGState /ca ${opacity.toFixed(2)} /CA ${opacity.toFixed(2)} >>`) : 0;
  const pageIds: number[] = [];

  parsedImages.forEach((image: ParsedImage, index: number) => {
    const pageSize = pageSizeForImage(image, options);
    const pageWidth = pageSize[0];
    const pageHeight = pageSize[1];
    const margin = marginSize(options.margin);
    const usableWidth = Math.max(1, pageWidth - margin * 2);
    const usableHeight = Math.max(1, pageHeight - margin * 2);
    const scale = Math.min(usableWidth / image.width, usableHeight / image.height);
    const drawWidth = image.width * scale;
    const drawHeight = image.height * scale;
    const x = (pageWidth - drawWidth) / 2;
    const y = (pageHeight - drawHeight) / 2;
    const imageName = `Im${index + 1}`;
    const imageId = add([
      `<< /Type /XObject /Subtype /Image /Width ${image.width} /Height ${image.height} /ColorSpace ${image.colorSpace} /BitsPerComponent ${image.bits} ${image.extra} /Length ${image.data.length} >>\nstream\n`,
      image.data,
      '\nendstream'
    ]);
    const content = [
      `q\n${drawWidth.toFixed(2)} 0 0 ${drawHeight.toFixed(2)} ${x.toFixed(2)} ${y.toFixed(2)} cm\n/${imageName} Do\nQ`,
      watermarkCommands(options.watermark, pageWidth, pageHeight)
    ].filter((item: string) => item.length > 0).join('\n');
    const contentId = add(`<< /Length ${byteLength(content)} >>\nstream\n${content}\nendstream`);
    const fontResource = fontId ? `/Font << /F1 ${fontId} 0 R >> ` : '';
    const stateResource = stateId ? `/ExtGState << /wm ${stateId} 0 R >> ` : '';
    const pageId = add(`<< /Type /Page /Parent ${pagesId} 0 R /MediaBox [0 0 ${pageWidth} ${pageHeight}] /Resources << ${fontResource}${stateResource}/XObject << /${imageName} ${imageId} 0 R >> >> /Contents ${contentId} 0 R >>`);
    pageIds.push(pageId);
  });

  objects[catalogId - 1] = `<< /Type /Catalog /Pages ${pagesId} 0 R >>`;
  objects[pagesId - 1] = `<< /Type /Pages /Kids [${pageIds.map((id: number) => `${id} 0 R`).join(' ')}] /Count ${pageIds.length} >>`;
  return buildPdf(objects, catalogId);
}

function buildTextContent(lines: string[], width: number, height: number, options: TextPdfOptions): string {
  const fontSize = Number(options.fontSize || 15);
  const lineHeight = Number(options.lineHeight || 24);
  const commands: string[] = [];
  commands.push('BT');
  commands.push('/F1 16 Tf');
  commands.push(`50 ${height - 54} Td`);
  if (options.title) {
    commands.push(`${utf16Hex(options.title)} Tj`);
  }
  commands.push('ET');
  commands.push('BT');
  commands.push(`/F1 ${fontSize} Tf`);
  commands.push(`${lineHeight} TL`);
  commands.push(`50 ${height - 90} Td`);
  lines.forEach((line: string, index: number) => {
    if (index > 0) {
      commands.push('T*');
    }
    commands.push(`${utf16Hex(line)} Tj`);
  });
  commands.push('ET');
  return commands.join('\n');
}

export function createPdfFromPages(pages: string[][], options: TextPdfOptions = {}): Uint8Array {
  const size = PAGE_SIZES[options.pageSize || 'A4'] || PAGE_SIZES.A4;
  const width = options.direction === '横向' ? size[1] : size[0];
  const height = options.direction === '横向' ? size[0] : size[1];
  const objects: PdfBody[] = [];
  const add = (body: PdfBody): number => {
    objects.push(body);
    return objects.length;
  };

  const catalogId = add('placeholder');
  const pagesId = add('placeholder');
  const fontDescId = add('<< /Type /Font /Subtype /CIDFontType0 /BaseFont /STSong-Light /CIDSystemInfo << /Registry (Adobe) /Ordering (GB1) /Supplement 2 >> /DW 1000 >>');
  const fontId = add(`<< /Type /Font /Subtype /Type0 /BaseFont /STSong-Light /Encoding /UniGB-UCS2-H /DescendantFonts [${fontDescId} 0 R] >>`);
  const pageIds: number[] = [];

  pages.forEach((pageLines: string[]) => {
    const content = buildTextContent(pageLines, width, height, options);
    const contentId = add(`<< /Length ${byteLength(content)} >>\nstream\n${content}\nendstream`);
    const pageId = add(`<< /Type /Page /Parent ${pagesId} 0 R /MediaBox [0 0 ${width} ${height}] /Resources << /Font << /F1 ${fontId} 0 R >> >> /Contents ${contentId} 0 R >>`);
    pageIds.push(pageId);
  });

  objects[catalogId - 1] = `<< /Type /Catalog /Pages ${pagesId} 0 R >>`;
  objects[pagesId - 1] = `<< /Type /Pages /Kids [${pageIds.map((id: number) => `${id} 0 R`).join(' ')}] /Count ${pageIds.length} >>`;
  return buildPdf(objects, catalogId);
}

export function createPdfFromText(text: string, options: TextPdfOptions = {}): Uint8Array {
  const maxChars = options.direction === '横向' ? 48 : 34;
  const lines = wrapText(text, maxChars);
  const pages = paginate(lines, options.pageSize === 'A5' ? 25 : 34);
  return createPdfFromPages(pages, options);
}

export function createReportPdf(title: string, lines: string[]): Uint8Array {
  return createPdfFromText(lines.join('\n'), { title, pageSize: 'A4', fontSize: 14, lineHeight: 22 });
}

export function createIdScanPdf(images: PdfImageInput[], options: ImagePdfOptions = {}): Uint8Array {
  return createPdfFromImages(images, {
    pageSize: options.pageSize || 'A4',
    direction: options.direction || '竖向',
    margin: options.margin || '窄边距'
  });
}

export function estimatePdfPageCount(text: string): number {
  const matches = text.match(/\/Type\s*\/Page\b/g);
  return matches ? matches.length : 1;
}
