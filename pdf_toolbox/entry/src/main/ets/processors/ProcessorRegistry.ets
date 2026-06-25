import { ProcessorRequest, ProcessorResult } from '../models/ToolModels';
import { textToPdf } from './TextProcessor';
import { convertImageFormat, documentScan, imagesToPdf, scanImage } from './ImageProcessor';
import { deletePdfPages, mergePdf, reorderPdfPages, splitPdf, watermarkPdf } from './PdfProcessor';
import { remoteOffice, remotePdf } from './RemoteProcessor';

export type Processor = (request: ProcessorRequest) => Promise<ProcessorResult>;

const PROCESSORS: Map<string, Processor> = new Map<string, Processor>([
  ['textToPdf', textToPdf],
  ['imagesToPdf', imagesToPdf],
  ['convertImageFormat', convertImageFormat],
  ['scanImage', scanImage],
  ['documentScan', documentScan],
  ['mergePdf', mergePdf],
  ['splitPdf', splitPdf],
  ['deletePdfPages', deletePdfPages],
  ['reorderPdfPages', reorderPdfPages],
  ['watermarkPdf', watermarkPdf],
  ['remoteOffice', remoteOffice],
  ['remotePdf', remotePdf]
]);

export class ProcessorRegistry {
  static getProcessor(name: string): Processor {
    const processor = PROCESSORS.get(name);
    if (!processor) {
      throw new Error(`未找到处理器：${name}`);
    }
    return processor;
  }
}
