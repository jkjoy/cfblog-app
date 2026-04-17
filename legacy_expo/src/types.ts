import type { ReactNode } from 'react';

export type UserRole =
  | 'administrator'
  | 'editor'
  | 'author'
  | 'contributor'
  | 'subscriber';

export interface AppConfig {
  baseUrl: string;
}

export interface SelectOption {
  label: string;
  value: string;
  description?: string;
}

export interface SessionUser {
  id: number;
  name: string;
  slug: string;
  description?: string;
  email?: string;
  roles?: string[];
  role?: string;
  registered_date?: string;
  avatar_urls?: Record<string, string>;
}

export interface SessionState {
  token: string;
  user: SessionUser;
}

export interface DiscoveryInfo {
  name?: string;
  description?: string;
  url?: string;
  home?: string;
}

export interface WpCollection<T> {
  items: T[];
  total: number;
  totalPages: number;
}

export interface WpPost {
  id: number;
  date?: string;
  modified?: string;
  slug: string;
  status: string;
  type?: string;
  title: { rendered: string };
  content: { rendered: string; raw?: string };
  excerpt: { rendered: string };
  author: number;
  author_name?: string;
  featured_media?: number;
  featured_image_url?: string;
  comment_status?: string;
  parent?: number;
  sticky?: boolean;
  categories?: number[];
  tags?: number[];
  comment_count?: number;
  view_count?: number;
  link?: string;
}

export interface WpMoment {
  id: number;
  content: { rendered: string; raw?: string };
  author: number;
  author_name: string;
  author_avatar?: string;
  status: string;
  media_urls: string[];
  view_count?: number;
  like_count?: number;
  comment_count?: number;
  date?: string;
  modified?: string;
}

export interface WpComment {
  id: number;
  post?: number;
  moment?: number;
  post_title?: string;
  parent: number;
  author: number;
  author_name: string;
  author_email?: string;
  author_url?: string;
  author_ip?: string;
  date?: string;
  content: { rendered: string };
  link?: string;
  status: string;
  type: string;
}

export interface WpMedia {
  id: number;
  date?: string;
  modified?: string;
  slug: string;
  title: { rendered: string };
  description: { rendered: string };
  caption: { rendered: string };
  alt_text: string;
  media_type: string;
  mime_type: string;
  media_details?: {
    width: number;
    height: number;
    file: string;
    filesize: number;
  };
  source_url: string;
}

export interface WpTerm {
  id: number;
  count?: number;
  description?: string;
  name: string;
  slug: string;
  taxonomy?: string;
  parent?: number;
}

export interface WpLinkCategory {
  id: number;
  name: string;
  slug: string;
  description?: string;
  count?: number;
}

export interface WpLink {
  id: number;
  name: string;
  url: string;
  description?: string;
  avatar?: string;
  category?: {
    id: number;
    name?: string;
    slug?: string;
  };
  target?: string;
  visible?: string;
  rating?: number;
  sort_order?: number;
  created_at?: string;
  updated_at?: string;
}

export type SettingsRecord = Record<string, string>;

export type NavKey =
  | 'dashboard'
  | 'posts'
  | 'pages'
  | 'moments'
  | 'comments'
  | 'moment-comments'
  | 'media'
  | 'categories'
  | 'tags'
  | 'links'
  | 'link-categories'
  | 'users'
  | 'settings';

export type FieldType =
  | 'text'
  | 'textarea'
  | 'number'
  | 'boolean'
  | 'select'
  | 'multiselect'
  | 'email'
  | 'url'
  | 'password'
  | 'multiline';

export interface FormField {
  key: string;
  label: string;
  type: FieldType;
  placeholder?: string;
  helper?: string;
  required?: boolean;
  options?: SelectOption[];
}

export interface ReferenceData {
  categories: WpTerm[];
  tags: WpTerm[];
  linkCategories: WpLinkCategory[];
  users: SessionUser[];
}

export interface CrudFilterSpec {
  label: string;
  queryKey: string;
  value: string;
  options: SelectOption[];
}

export interface CrudListParams {
  page: number;
  perPage: number;
  search: string;
  filterValue: string;
}

export interface CrudScreenProps<TItem> {
  title: string;
  description: string;
  emptyText: string;
  fields: FormField[];
  createLabel?: string;
  searchPlaceholder?: string;
  filterSpec?: Omit<CrudFilterSpec, 'value'> & { initialValue: string };
  loadPage: (params: CrudListParams) => Promise<WpCollection<TItem>>;
  createItem: (payload: Record<string, unknown>) => Promise<unknown>;
  updateItem: (item: TItem, payload: Record<string, unknown>) => Promise<unknown>;
  deleteItem?: (item: TItem) => Promise<unknown>;
  defaultDraft: Record<string, unknown>;
  toDraft: (item: TItem) => Record<string, unknown>;
  toPayload: (draft: Record<string, unknown>, item?: TItem | null) => Record<string, unknown>;
  getId: (item: TItem) => number;
  getTitle: (item: TItem) => string;
  getSubtitle?: (item: TItem) => string | undefined;
  getBadges?: (item: TItem) => string[];
  renderDetails?: (item: TItem) => ReactNode;
  onMutated?: () => Promise<void> | void;
}
