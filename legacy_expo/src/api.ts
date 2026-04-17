import type {
  DiscoveryInfo,
  SessionUser,
  SettingsRecord,
  WpCollection,
  WpComment,
  WpLink,
  WpLinkCategory,
  WpMedia,
  WpMoment,
  WpPost,
  WpTerm,
} from './types';

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  body?: BodyInit | Record<string, unknown>;
  query?: Record<string, unknown>;
  root?: 'v2' | 'root';
}

interface JsonErrorLike {
  message?: string;
  error?: string;
  code?: string;
}

export class CfblogApi {
  constructor(
    private readonly baseUrl: string,
    private readonly token?: string,
  ) {}

  withToken(token?: string) {
    return new CfblogApi(this.baseUrl, token);
  }

  get normalizedBaseUrl() {
    return this.baseUrl.replace(/\/+$/, '');
  }

  private buildUrl(path: string, query?: RequestOptions['query'], root: RequestOptions['root'] = 'v2') {
    const prefix =
      root === 'root'
        ? `${this.normalizedBaseUrl}/wp-json`
        : `${this.normalizedBaseUrl}/wp-json/wp/v2`;

    const url = new URL(`${prefix}${path.startsWith('/') ? path : `/${path}`}`);

    if (query) {
      Object.entries(query).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          url.searchParams.set(key, String(value));
        }
      });
    }

    return url.toString();
  }

  private async request<T>(path: string, options: RequestOptions = {}): Promise<{ data: T; headers: Headers }> {
    const isFormData =
      typeof FormData !== 'undefined' && options.body instanceof FormData;

    const headers = new Headers();
    headers.set('Accept', 'application/json');

    if (this.token) {
      headers.set('Authorization', `Bearer ${this.token}`);
    }

    let body: BodyInit | undefined;
    if (options.body && !isFormData && typeof options.body === 'object') {
      headers.set('Content-Type', 'application/json');
      body = JSON.stringify(options.body);
    } else {
      body = options.body as BodyInit | undefined;
    }

    const response = await fetch(this.buildUrl(path, options.query, options.root), {
      method: options.method ?? 'GET',
      headers,
      body,
    });

    const text = await response.text();
    let data: T | JsonErrorLike | undefined;

    try {
      data = text ? (JSON.parse(text) as T | JsonErrorLike) : undefined;
    } catch {
      data = undefined;
    }

    if (!response.ok) {
      const message =
        (data as JsonErrorLike | undefined)?.message ||
        (data as JsonErrorLike | undefined)?.error ||
        `Request failed with status ${response.status}`;
      throw new Error(message);
    }

    return { data: (data as T) ?? ({} as T), headers: response.headers };
  }

  private toCollection<T>(data: T[], headers: Headers): WpCollection<T> {
    return {
      items: data,
      total: Number(headers.get('x-wp-total') || data.length || 0),
      totalPages: Number(headers.get('x-wp-totalpages') || 1),
    };
  }

  async getDiscovery() {
    const { data } = await this.request<DiscoveryInfo>('/', { root: 'root' });
    return data;
  }

  async login(username: string, password: string) {
    const { data } = await this.request<{
      token: string;
      user: SessionUser;
    }>('/users/login', {
      method: 'POST',
      body: { username, password },
    });
    return data;
  }

  async register(username: string, email: string, password: string, displayName: string) {
    const { data } = await this.request<{
      token: string;
      user: SessionUser;
    }>('/users/register', {
      method: 'POST',
      body: {
        username,
        email,
        password,
        display_name: displayName,
      },
    });
    return data;
  }

  async getCurrentUser() {
    const { data } = await this.request<SessionUser>('/users/me');
    return data;
  }

  async listPosts(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpPost[]>('/posts', { query });
    return this.toCollection(data, headers);
  }

  async listPages(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpPost[]>('/pages', { query });
    return this.toCollection(data, headers);
  }

  async listMoments(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpMoment[]>('/moments', { query });
    return this.toCollection(data, headers);
  }

  async listComments(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpComment[]>('/comments', { query });
    return this.toCollection(data, headers);
  }

  async listMomentComments(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpComment[]>('/moments/comments/all', { query });
    return this.toCollection(data, headers);
  }

  async listMedia(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpMedia[]>('/media', { query });
    return this.toCollection(data, headers);
  }

  async listCategories(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpTerm[]>('/categories', { query });
    return this.toCollection(data, headers);
  }

  async listTags(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpTerm[]>('/tags', { query });
    return this.toCollection(data, headers);
  }

  async listLinks(query: Record<string, unknown>) {
    const { data, headers } = await this.request<WpLink[]>('/links', { query });
    return this.toCollection(data, headers);
  }

  async listLinkCategories() {
    const { data } = await this.request<WpLinkCategory[]>('/link-categories');
    return data;
  }

  async listUsers(query: Record<string, unknown>) {
    const { data, headers } = await this.request<SessionUser[]>('/users', { query });
    return this.toCollection(data, headers);
  }

  async getSettings(admin = true) {
    const route = admin ? '/settings/admin' : '/settings';
    const { data } = await this.request<SettingsRecord>(route);
    return data;
  }

  async updateSettings(payload: SettingsRecord) {
    const { data } = await this.request<{ success: boolean; message?: string }>('/settings', {
      method: 'PUT',
      body: payload,
    });
    return data;
  }

  async create(path: string, payload: Record<string, unknown>) {
    const { data } = await this.request(path, { method: 'POST', body: payload });
    return data;
  }

  async update(path: string, payload: Record<string, unknown>) {
    const { data } = await this.request(path, { method: 'PUT', body: payload });
    return data;
  }

  async remove(path: string, query?: Record<string, string | number | boolean | undefined>) {
    const { data } = await this.request(path, { method: 'DELETE', query });
    return data;
  }

  async uploadMedia(formData: FormData) {
    const { data } = await this.request<WpMedia>('/media', {
      method: 'POST',
      body: formData,
    });
    return data;
  }
}
