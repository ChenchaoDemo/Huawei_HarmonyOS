import { ProcessorRequest, ProcessorResult } from '../models/ToolModels';

export class ServerConversionAdapter {
  static async run(_: ProcessorRequest): Promise<ProcessorResult> {
    throw new Error('需接入服务端转换能力。当前原生版已保留入口、参数和历史流程，但不会生成可能错误的结果文件。');
  }
}

export async function remoteOffice(request: ProcessorRequest): Promise<ProcessorResult> {
  return ServerConversionAdapter.run(request);
}

export async function remotePdf(request: ProcessorRequest): Promise<ProcessorResult> {
  return ServerConversionAdapter.run(request);
}
