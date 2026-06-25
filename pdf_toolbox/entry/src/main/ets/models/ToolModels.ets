export type CategoryId = 'hot' | 'pdf' | 'toPdf' | 'fromPdf' | 'scan';
export type PickerMode = 'file' | 'image' | 'camera' | 'text';
export type SettingType = 'input' | 'password' | 'switch' | 'slider' | 'radio';
export type SettingValue = string | number | boolean;
export type ProcessorStatus = 'idle' | 'processing' | 'success' | 'error';
export type SettingMap = Map<string, SettingValue>;

export interface CategoryMeta {
  id: CategoryId;
  name: string;
}

export interface ToolMeta {
  id: string;
  name: string;
  desc: string;
  category: CategoryId;
  iconText: string;
  path: string;
  hot: boolean;
  acceptTypes: string[];
}

export interface ToolSetting {
  key: string;
  label: string;
  type: SettingType;
  placeholder?: string;
  hint?: string;
  dynamicHint?: string;
  value?: SettingValue;
  min?: number;
  max?: number;
  step?: number;
  options?: string[];
}

export interface ToolConfig {
  processor: string;
  pickMode: PickerMode;
  multiple: boolean;
  maxCount: number;
  resultExt: string;
  actionText: string;
  description: string;
  pickTitle?: string;
  pickDesc?: string;
  settings: ToolSetting[];
}

export interface PickedFile {
  id: string;
  name: string;
  uri: string;
  size: number;
  ext: string;
  type: string;
}

export interface ProcessorRequest {
  files: PickedFile[];
  settings: SettingMap;
  text: string;
}

export interface ProcessorResult {
  content: Uint8Array;
  ext: string;
  summary: string;
}

export interface SavedFile {
  name: string;
  path: string;
  size: number;
}

export interface ProcessResultView {
  name: string;
  path: string;
  size: number;
  duration: number;
  summary: string;
}

export interface PreviewSourceFile {
  id: string;
  name: string;
  uri: string;
  size: number;
  ext: string;
  type: string;
}

export interface FilePreviewRouteParams {
  name?: string;
  path?: string;
  size?: number;
  sizeText?: string;
  summary?: string;
  toolName?: string;
  sources?: PreviewSourceFile[];
  textPreview?: string;
  autoOpen?: boolean;
}

export interface HistoryRecord {
  id: string;
  toolName: string;
  toolType: string;
  sourceFileName: string;
  resultFileName: string;
  resultExt?: string;
  resultPath: string;
  fileSize: string;
  status: string;
  createTime: string;
}
