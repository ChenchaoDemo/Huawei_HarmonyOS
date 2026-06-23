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

export function countPdfPages(document: PdfDocumentData): number {
  return parseDocument(document).pages.length;
}
