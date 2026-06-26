import { concatBytes } from '../utils/FormatUtils';

class PdfObject {
  name: string;
  id: number;
  gen: number;
  key: string;
  body: string;

  constructor(id: number, gen: number, body: string) {
    this.name = '';
    this.id = id;
    this.gen = gen;
    this.key = `${id} ${gen}`;
    this.body = body;
  }
}

export class PdfDocumentData {
  name: string;
  data: Uint8Array;

  constructor(name: string, data: Uint8Array) {
    this.name = name;
    this.data = data;
  }
}

class ParsedPdfDocument extends PdfDocumentData {
  objects: PdfObject[];
  objectMap: Map<string, PdfObject>;
  pages: PdfObject[];
  mapping: Map<string, number>;

  constructor(document: PdfDocumentData, objects: PdfObject[], objectMap: Map<string, PdfObject>, pages: PdfObject[]) {
    super(document.name, document.data);
    this.objects = objects;
    this.objectMap = objectMap;
    this.pages = pages;
    this.mapping = new Map<string, number>();
  }
}

export class PdfBuildResult {
  content: Uint8Array;
  pageCount: number;

  constructor(content: Uint8Array, pageCount: number) {
    this.content = content;
    this.pageCount = pageCount;
  }
}

export interface PdfWatermarkOptions {
  text: string;
  opacity: number;
  fontSize: number;
  angle: number;
  position: string;
  color?: string;
}

function bytesToBinaryString(bytes: Uint8Array): string {
  const chunks: string[] = [];
  const chunkSize = 8192;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    let chunk = '';
    const end = Math.min(i + chunkSize, bytes.length);
    for (let j = i; j < end; j += 1) {
      chunk += String.fromCharCode(bytes[j]);
    }
    chunks.push(chunk);
  }
  return chunks.join('');
}

function binaryStringToBytes(text: string): Uint8Array {
  const out = new Uint8Array(text.length);
  for (let i = 0; i < text.length; i += 1) {
    out[i] = text.charCodeAt(i) & 0xff;
  }
  return out;
}

function readBalancedValue(text: string, start: number, openToken: string, closeToken: string): number {
  let depth = 0;
  let i = start;
  while (i < text.length) {
    if (text.startsWith(openToken, i)) {
      depth += 1;
      i += openToken.length;
      continue;
    }
    if (text.startsWith(closeToken, i)) {
      depth -= 1;
      i += closeToken.length;
      if (depth === 0) {
        return i;
      }
      continue;
    }
    i += 1;
  }
  return i;
}

function valueEnd(text: string, start: number): number {
  let i = start;
  while (i < text.length && /\s/.test(text[i])) {
    i += 1;
  }
  if (text.startsWith('<<', i)) {
    return readBalancedValue(text, i, '<<', '>>');
  }
  if (text[i] === '[') {
    return readBalancedValue(text, i, '[', ']');
  }
  const ref = /^(\d+\s+\d+\s+R)\b/.exec(text.slice(i));
  if (ref) {
    return i + ref[1].length;
  }
  const literal = /^\((?:\\.|[^\\)])*\)/.exec(text.slice(i));
  if (literal) {
    return i + literal[0].length;
  }
  const name = /^\/[^\s<>\[\]()\/]+/.exec(text.slice(i));
  if (name) {
    return i + name[0].length;
  }
  const simple = /^[^\s<>\[\]()\/]+/.exec(text.slice(i));
  if (simple) {
    return i + simple[0].length;
  }
  return i;
}

function extractEntry(body: string, name: string): string {
  const match = new RegExp(`/${name}\\b`).exec(body);
  if (!match) {
    return '';
  }
  const valueStart = match.index + name.length + 1;
  return body.slice(match.index, valueEnd(body, valueStart));
}

function hasEntry(body: string, name: string): boolean {
  return new RegExp(`/${name}\\b`).test(body);
}

function getRef(body: string, name: string): string {
  const match = new RegExp(`/${name}\\s+(\\d+)\\s+(\\d+)\\s+R\\b`).exec(body);
  return match ? `${match[1]} ${match[2]}` : '';
}

function appendEntries(body: string, entries: string[]): string {
  const insert = entries.filter((item: string) => item.length > 0).join(' ');
  if (!insert) {
    return body;
  }
  const index = body.lastIndexOf('>>');
  if (index < 0) {
    return body;
  }
  return `${body.slice(0, index)} ${insert} ${body.slice(index)}`;
}

function setEntry(body: string, name: string, entry: string): string {
  const match = new RegExp(`/${name}\\b`).exec(body);
  if (!match) {
    return appendEntries(body, [entry]);
  }
  const valueStart = match.index + name.length + 1;
  return `${body.slice(0, match.index)}${entry}${body.slice(valueEnd(body, valueStart))}`;
}

function entryValue(entry: string, name: string): string {
  return entry.replace(new RegExp(`^/${name}\\b\\s*`), '').trim();
}

function removeEntry(body: string, name: string): string {
  const match = new RegExp(`/${name}\\b`).exec(body);
  if (!match) {
    return body;
  }
  const valueStart = match.index + name.length + 1;
  return `${body.slice(0, match.index)}${body.slice(valueEnd(body, valueStart))}`;
}

function collectRefs(body: string): string[] {
  const refs: string[] = [];
  const seen = new Set<string>();
  body.replace(/\b(\d+)\s+(\d+)\s+R\b/g, (raw: string, id: string, gen: string): string => {
    const key = `${id} ${gen}`;
    if (!seen.has(key)) {
      seen.add(key);
      refs.push(key);
    }
    return raw;
  });
  return refs;
}

function utf16Hex(text: string): string {
  let hex = 'FEFF';
  for (let i = 0; i < text.length; i += 1) {
    hex += text.charCodeAt(i).toString(16).padStart(4, '0').toUpperCase();
  }
  return `<${hex}>`;
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function normalizeOpacity(value: number): number {
  if (value !== value) {
    return 0.35;
  }
  return clamp(value / 100, 0.08, 0.9);
}

function normalizeFontSize(value: number): number {
  if (value !== value) {
    return 32;
  }
  return clamp(value, 12, 96);
}

function normalizeHexColor(color: string | undefined): number[] {
  let value = String(color || '#8A93A8').trim().replace(/^#/, '');
  if (/^[0-9a-fA-F]{3}$/.test(value)) {
    value = value.split('').map((item: string) => item + item).join('');
  }
  if (!/^[0-9a-fA-F]{6}$/.test(value)) {
    value = '8A93A8';
  }
  return [0, 2, 4].map((index: number) => parseInt(value.slice(index, index + 2), 16) / 255);
}

function parsePageBox(pageBody: string): number[] {
  const entry = extractEntry(pageBody, 'CropBox') || extractEntry(pageBody, 'MediaBox');
  if (!entry) {
    return [0, 0, 595, 842];
  }
  const match = /\[([^\]]+)\]/.exec(entry);
  if (!match) {
    return [0, 0, 595, 842];
  }
  const numbers = match[1].split(/\s+/)
    .map((item: string) => Number(item))
    .filter((item: number) => item === item);
  if (numbers.length < 4 || numbers[2] === numbers[0] || numbers[3] === numbers[1]) {
    return [0, 0, 595, 842];
  }
  return numbers.slice(0, 4);
}

function estimateTextWidth(text: string, fontSize: number): number {
  return Math.max(fontSize, text.length * fontSize * 0.62);
}

function watermarkPoint(box: number[], text: string, fontSize: number, position: string): number[] {
  const left = Math.min(box[0], box[2]);
  const right = Math.max(box[0], box[2]);
  const bottom = Math.min(box[1], box[3]);
  const top = Math.max(box[1], box[3]);
  const width = right - left;
  const height = top - bottom;
  const margin = Math.min(54, Math.max(24, Math.min(width, height) * 0.08));
  const textWidth = estimateTextWidth(text, fontSize);
  const points: Record<string, number[]> = {
    '左上': [left + margin, top - margin - fontSize],
    '右上': [right - margin - textWidth, top - margin - fontSize],
    '左下': [left + margin, bottom + margin],
    '右下': [right - margin - textWidth, bottom + margin],
    '居中': [left + (width - textWidth) / 2, bottom + (height - fontSize) / 2]
  };
  const point = points[position] || points['居中'];
  return [
    clamp(point[0], left + 12, Math.max(left + 12, right - 12)),
    clamp(point[1], bottom + 12, Math.max(bottom + 12, top - 12))
  ];
}

function textMatrix(x: number, y: number, angle: number): string {
  const radians = angle * Math.PI / 180;
  const cos = Math.cos(radians);
  const sin = Math.sin(radians);
  return `${cos.toFixed(4)} ${sin.toFixed(4)} ${(-sin).toFixed(4)} ${cos.toFixed(4)} ${x.toFixed(2)} ${y.toFixed(2)} Tm`;
}

function watermarkTextCommand(text: string, fontSize: number, x: number, y: number, angle: number): string {
  return [
    'BT',
    `/PTBWMF1 ${fontSize.toFixed(1)} Tf`,
    textMatrix(x, y, angle),
    `${utf16Hex(text)} Tj`,
    'ET'
  ].join('\n');
}

function watermarkCommands(options: PdfWatermarkOptions, pageBody: string): string {
  const text = options.text.trim();
  if (!text) {
    return '';
  }
  const box = parsePageBox(pageBody);
  const left = Math.min(box[0], box[2]);
  const right = Math.max(box[0], box[2]);
  const bottom = Math.min(box[1], box[3]);
  const top = Math.max(box[1], box[3]);
  const fontSize = normalizeFontSize(options.fontSize);
  const angle = clamp(Number(options.angle || 0), -75, 75);
  const rgb = normalizeHexColor(options.color);
  const commands: string[] = [
    'q',
    '/PTBWMGS1 gs',
    `${rgb[0].toFixed(3)} ${rgb[1].toFixed(3)} ${rgb[2].toFixed(3)} rg`
  ];

  if (options.position === '平铺') {
    const textWidth = estimateTextWidth(text, fontSize);
    const spacingX = Math.max(180, textWidth + 96);
    const spacingY = Math.max(120, fontSize * 4.2);
    let count = 0;
    for (let y = bottom + 36; y < top; y += spacingY) {
      for (let x = left + 24; x < right; x += spacingX) {
        commands.push(watermarkTextCommand(text, fontSize, x, y, angle));
        count += 1;
        if (count >= 120) {
          break;
        }
      }
      if (count >= 120) {
        break;
      }
    }
  } else {
    const point = watermarkPoint(box, text, fontSize, options.position || '居中');
    commands.push(watermarkTextCommand(text, fontSize, point[0], point[1], angle));
  }

  commands.push('Q');
  return commands.join('\n');
}

function appendNameToDictionary(dictionary: string, name: string, ref: string): string {
  if (new RegExp(`/${name}\\b`).test(dictionary)) {
    return dictionary;
  }
  return appendEntries(dictionary, [`/${name} ${ref}`]);
}

function ensureNestedResource(resourcesBody: string, typeName: string, name: string, ref: string, objects: string[]): string {
  const entry = extractEntry(resourcesBody, typeName);
  if (!entry) {
    return appendEntries(resourcesBody, [`/${typeName} << /${name} ${ref} >>`]);
  }

  const value = entryValue(entry, typeName);
  if (value.startsWith('<<')) {
    return setEntry(resourcesBody, typeName, `/${typeName} ${appendNameToDictionary(value, name, ref)}`);
  }

  const refMatch = /^(\d+)\s+0\s+R\b/.exec(value);
  if (refMatch) {
    const objectId = Number(refMatch[1]);
    if (!objectId || objectId > objects.length) {
      throw new Error('PDF 页面资源引用异常，暂不支持端侧加水印');
    }
    objects[objectId - 1] = appendNameToDictionary(objects[objectId - 1], name, ref);
    return resourcesBody;
  }

  throw new Error('PDF 页面资源结构暂不支持端侧加水印');
}

function ensureWatermarkResources(resourcesBody: string, fontId: number, stateId: number, objects: string[]): string {
  let next = ensureNestedResource(resourcesBody, 'Font', 'PTBWMF1', `${fontId} 0 R`, objects);
  next = ensureNestedResource(next, 'ExtGState', 'PTBWMGS1', `${stateId} 0 R`, objects);
  return next;
}

function appendContentRef(pageBody: string, contentId: number): string {
  const entry = extractEntry(pageBody, 'Contents');
  const ref = `${contentId} 0 R`;
  if (!entry) {
    return appendEntries(pageBody, [`/Contents ${ref}`]);
  }

  const value = entryValue(entry, 'Contents');
  if (/^\d+\s+0\s+R\b/.test(value)) {
    return setEntry(pageBody, 'Contents', `/Contents [${value} ${ref}]`);
  }
  if (value.startsWith('[')) {
    const inner = value.slice(1, value.lastIndexOf(']')).trim();
    return setEntry(pageBody, 'Contents', `/Contents [${inner}${inner ? ' ' : ''}${ref}]`);
  }
  throw new Error('PDF 页面内容结构暂不支持端侧加水印');
}

function parseObjects(source: string): PdfObject[] {
  const objects: PdfObject[] = [];
  const pattern = /(?:^|[\r\n])(\d+)\s+(\d+)\s+obj\b/g;
  let match: RegExpExecArray | null = pattern.exec(source);
  while (match) {
    const bodyStart = pattern.lastIndex;
    const end = source.indexOf('endobj', bodyStart);
    if (end < 0) {
      break;
    }
    const id = Number(match[1]);
    const gen = Number(match[2]);
    objects.push(new PdfObject(id, gen, source.slice(bodyStart, end).trim()));
    pattern.lastIndex = end + 6;
    match = pattern.exec(source);
  }
  return objects;
}

function inheritedEntries(page: PdfObject, objectMap: Map<string, PdfObject>): Record<string, string> {
  const result: Record<string, string> = {};
  let parentKey = getRef(page.body, 'Parent');
  const seen = new Set<string>();
  while (parentKey && !seen.has(parentKey)) {
    seen.add(parentKey);
    const parent = objectMap.get(parentKey);
    if (!parent) {
      break;
    }
    ['MediaBox', 'CropBox', 'Resources', 'Rotate'].forEach((name: string) => {
      if (!result[name]) {
        result[name] = extractEntry(parent.body, name);
      }
    });
    parentKey = getRef(parent.body, 'Parent');
  }
  return result;
}

function parseDocument(document: PdfDocumentData): ParsedPdfDocument {
  const source = bytesToBinaryString(document.data);
  if (/\/Encrypt\b/.test(source)) {
    throw new Error(`${document.name} 是加密 PDF，暂不支持轻量处理`);
  }
  if (/\/ObjStm\b/.test(source)) {
    throw new Error(`${document.name} 使用了压缩对象流，当前轻量处理暂不支持`);
  }
  const objects = parseObjects(source);
  const objectMap = new Map<string, PdfObject>();
  objects.forEach((object: PdfObject) => objectMap.set(object.key, object));
  const pages = objects.filter((object: PdfObject) => /\/Type\s*\/Page\b/.test(object.body));
  if (!pages.length) {
    throw new Error(`${document.name} 没有解析到页面`);
  }
  return new ParsedPdfDocument(document, objects, objectMap, pages);
}

function replaceRefs(body: string, mapping: Map<string, number>): string {
  return body.replace(/\b(\d+)\s+(\d+)\s+R\b/g, (raw: string, id: string, gen: string): string => {
    const mapped = mapping.get(`${id} ${gen}`);
    return mapped ? `${mapped} 0 R` : raw;
  });
}

function buildPdf(objects: string[], catalogId: number): Uint8Array {
  const chunks: Uint8Array[] = [];
  const offsets: number[] = [0];
  let length = 0;
  const push = (text: string | Uint8Array): void => {
    const bytes = typeof text === 'string' ? binaryStringToBytes(text) : text;
    chunks.push(bytes);
    length += bytes.length;
  };

  push('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
  objects.forEach((body: string, index: number) => {
    offsets.push(length);
    push(`${index + 1} 0 obj\n${body}\nendobj\n`);
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

class SelectedPdfBuilder {
  objects: string[] = ['placeholder', 'placeholder'];
  catalogId: number = 1;
  pagesId: number = 2;
  pageIds: number[] = [];
  watermarkFontId: number = 0;
  watermarkStateId: number = 0;

  addObject(body: string): number {
    this.objects.push(body);
    return this.objects.length;
  }

  copyObject(document: ParsedPdfDocument, object: PdfObject, bodyOverride: string = ''): number {
    const mapped = document.mapping.get(object.key);
    if (mapped) {
      return mapped;
    }

    const objectId = this.addObject('');
    document.mapping.set(object.key, objectId);
    const body = bodyOverride.length > 0 ? bodyOverride : object.body;
    const bodyForRefs = removeEntry(removeEntry(removeEntry(body, 'Parent'), 'Kids'), 'Pages');
    collectRefs(bodyForRefs).forEach((key: string) => {
      const refObject = document.objectMap.get(key);
      if (refObject) {
        this.copyObject(document, refObject);
      }
    });
    this.objects[objectId - 1] = replaceRefs(body, document.mapping);
    return objectId;
  }

  private ensureWatermarkObjects(options: PdfWatermarkOptions): void {
    if (!this.watermarkFontId) {
      const fontDescId = this.addObject('<< /Type /Font /Subtype /CIDFontType0 /BaseFont /STSong-Light /CIDSystemInfo << /Registry (Adobe) /Ordering (GB1) /Supplement 2 >> /DW 1000 >>');
      this.watermarkFontId = this.addObject(`<< /Type /Font /Subtype /Type0 /BaseFont /STSong-Light /Encoding /UniGB-UCS2-H /DescendantFonts [${fontDescId} 0 R] >>`);
    }
    if (!this.watermarkStateId) {
      const opacity = normalizeOpacity(options.opacity);
      this.watermarkStateId = this.addObject(`<< /Type /ExtGState /ca ${opacity.toFixed(2)} /CA ${opacity.toFixed(2)} >>`);
    }
  }

  private addWatermarkResourcesToPage(pageId: number): void {
    let pageBody = this.objects[pageId - 1];
    const resources = extractEntry(pageBody, 'Resources');
    if (!resources) {
      this.objects[pageId - 1] = appendEntries(pageBody, [`/Resources << /Font << /PTBWMF1 ${this.watermarkFontId} 0 R >> /ExtGState << /PTBWMGS1 ${this.watermarkStateId} 0 R >> >>`]);
      return;
    }

    const value = entryValue(resources, 'Resources');
    const refMatch = /^(\d+)\s+0\s+R\b/.exec(value);
    if (refMatch) {
      const objectId = Number(refMatch[1]);
      if (!objectId || objectId > this.objects.length) {
        throw new Error('PDF 页面资源引用异常，暂不支持端侧加水印');
      }
      this.objects[objectId - 1] = ensureWatermarkResources(this.objects[objectId - 1], this.watermarkFontId, this.watermarkStateId, this.objects);
      return;
    }

    if (value.startsWith('<<')) {
      pageBody = setEntry(pageBody, 'Resources', `/Resources ${ensureWatermarkResources(value, this.watermarkFontId, this.watermarkStateId, this.objects)}`);
      this.objects[pageId - 1] = pageBody;
      return;
    }

    throw new Error('PDF 页面资源结构暂不支持端侧加水印');
  }

  private addWatermarkContentToPage(pageId: number, content: string): void {
    const contentId = this.addObject(`<< /Length ${content.length} >>\nstream\n${content}\nendstream`);
    this.objects[pageId - 1] = appendContentRef(this.objects[pageId - 1], contentId);
  }

  addPage(document: ParsedPdfDocument, page: PdfObject): void {
    const inherited = inheritedEntries(page, document.objectMap);
    const missingEntries = ['MediaBox', 'CropBox', 'Resources', 'Rotate']
      .filter((name: string) => !hasEntry(page.body, name))
      .map((name: string) => inherited[name] || '');
    const body = removeEntry(appendEntries(page.body, missingEntries), 'Parent');
    const pageId = this.copyObject(document, page, body);
    this.objects[pageId - 1] = appendEntries(this.objects[pageId - 1], [`/Parent ${this.pagesId} 0 R`]);
    this.pageIds.push(pageId);
  }

  addWatermarkedPage(document: ParsedPdfDocument, page: PdfObject, options: PdfWatermarkOptions): void {
    const inherited = inheritedEntries(page, document.objectMap);
    const missingEntries = ['MediaBox', 'CropBox', 'Resources', 'Rotate']
      .filter((name: string) => !hasEntry(page.body, name))
      .map((name: string) => inherited[name] || '');
    const body = removeEntry(appendEntries(page.body, missingEntries), 'Parent');
    const content = watermarkCommands(options, body);
    const pageId = this.copyObject(document, page, body);
    this.objects[pageId - 1] = appendEntries(this.objects[pageId - 1], [`/Parent ${this.pagesId} 0 R`]);
    if (content.length > 0) {
      this.ensureWatermarkObjects(options);
      this.addWatermarkResourcesToPage(pageId);
      this.addWatermarkContentToPage(pageId, content);
    }
    this.pageIds.push(pageId);
  }

  build(): PdfBuildResult {
    this.objects[this.catalogId - 1] = `<< /Type /Catalog /Pages ${this.pagesId} 0 R >>`;
    this.objects[this.pagesId - 1] = `<< /Type /Pages /Kids [${this.pageIds.map((id: number) => `${id} 0 R`).join(' ')}] /Count ${this.pageIds.length} >>`;
    return new PdfBuildResult(buildPdf(this.objects, this.catalogId), this.pageIds.length);
  }
}

function buildSelectedPdf(parsed: ParsedPdfDocument[], pageSelector: (document: ParsedPdfDocument) => PdfObject[]): PdfBuildResult {
  const builder = new SelectedPdfBuilder();
  parsed.forEach((document: ParsedPdfDocument) => {
    const pages = pageSelector(document);
    pages.forEach((page: PdfObject) => {
      builder.addPage(document, page);
    });
  });
  return builder.build();
}

export function mergePdfDocuments(documents: PdfDocumentData[]): PdfBuildResult {
  const parsed = documents.map((document: PdfDocumentData) => parseDocument(document));
  return buildSelectedPdf(parsed, (document: ParsedPdfDocument) => document.pages);
}

export function selectPdfPages(document: PdfDocumentData, pageNumbers: number[]): PdfBuildResult {
  const parsed = parseDocument(document);
  const pages = pageNumbers.map((pageNumber: number) => {
    const page = parsed.pages[pageNumber - 1];
    if (!page) {
      throw new Error(`页码 ${pageNumber} 超出范围`);
    }
    return page;
  });
  return buildSelectedPdf([parsed], () => pages);
}

export function watermarkPdfDocument(document: PdfDocumentData, options: PdfWatermarkOptions): PdfBuildResult {
  const source = bytesToBinaryString(document.data);
  if (/\/ByteRange\b|\/Type\s*\/Sig\b/.test(source)) {
    throw new Error(`${document.name} 可能包含数字签名，本地重建会导致签名失效，暂不支持端侧加水印`);
  }
  const parsed = parseDocument(document);
  const builder = new SelectedPdfBuilder();
  parsed.pages.forEach((page: PdfObject) => {
    builder.addWatermarkedPage(parsed, page, options);
  });
  return builder.build();
}

export function countPdfPages(document: PdfDocumentData): number {
  return parseDocument(document).pages.length;
}
