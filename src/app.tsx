import * as DocumentPicker from 'expo-document-picker';
import { useDeferredValue, useEffect, useRef, useState } from 'react';
import {
  Alert,
  Image,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { CfblogApi } from './api';
import { clearConfig, clearSession, loadConfig, loadSession, saveConfig, saveSession } from './storage';
import { palette } from './theme';
import type {
  AppConfig,
  CrudScreenProps,
  DiscoveryInfo,
  FormField,
  NavKey,
  ReferenceData,
  SelectOption,
  SessionState,
  SessionUser,
  SettingsRecord,
  UserRole,
  WpComment,
  WpLink,
  WpLinkCategory,
  WpMedia,
  WpMoment,
  WpPost,
  WpTerm,
} from './types';
import {
  Badge,
  Button,
  Card,
  EmptyState,
  FieldRenderer,
  InlineMessage,
  ScreenTitle,
  Sheet,
  StatBox,
  TextField,
  surfaceStyles,
} from './ui';

const emptyReferences: ReferenceData = {
  categories: [],
  tags: [],
  linkCategories: [],
  users: [],
};

const roleOptions: SelectOption[] = [
  { label: '管理员', value: 'administrator' },
  { label: '编辑', value: 'editor' },
  { label: '作者', value: 'author' },
  { label: '投稿者', value: 'contributor' },
  { label: '订阅者', value: 'subscriber' },
];

const postStatusOptions: SelectOption[] = [
  { label: '已发布', value: 'publish' },
  { label: '草稿', value: 'draft' },
  { label: '待审核', value: 'pending' },
  { label: '私密', value: 'private' },
  { label: '回收站', value: 'trash' },
];

const pageStatusOptions: SelectOption[] = [{ label: '全部', value: 'all' }, ...postStatusOptions];
const commentStatusOptions: SelectOption[] = [
  { label: '全部', value: 'all' },
  { label: '已通过', value: 'approved' },
  { label: '待审核', value: 'pending' },
  { label: '垃圾', value: 'spam' },
  { label: '回收站', value: 'trash' },
];

const momentStatusOptions: SelectOption[] = [
  { label: '全部', value: 'all' },
  { label: '发布', value: 'publish' },
  { label: '草稿', value: 'draft' },
  { label: '私密', value: 'private' },
  { label: '回收站', value: 'trash' },
];

const visibleOptions: SelectOption[] = [
  { label: '展示', value: 'yes' },
  { label: '隐藏', value: 'no' },
];

const navItems: { key: NavKey; label: string }[] = [
  { key: 'dashboard', label: '总览' },
  { key: 'posts', label: '文章' },
  { key: 'pages', label: '页面' },
  { key: 'moments', label: '动态' },
  { key: 'comments', label: '评论' },
  { key: 'moment-comments', label: '动态评论' },
  { key: 'media', label: '媒体' },
  { key: 'categories', label: '分类' },
  { key: 'tags', label: '标签' },
  { key: 'links', label: '友链' },
  { key: 'link-categories', label: '友链分类' },
  { key: 'users', label: '用户' },
  { key: 'settings', label: '设置' },
];

function stripHtml(input?: string) {
  return String(input || '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function formatDate(input?: string) {
  if (!input) {
    return '未设置';
  }
  const date = new Date(input);
  if (Number.isNaN(date.getTime())) {
    return input;
  }
  return date.toLocaleString();
}

function normalizeUrl(value: string) {
  return value.trim().replace(/\/+$/, '');
}

function toOptionalNumber(value: unknown) {
  const numeric = Number(String(value ?? '').trim());
  return Number.isFinite(numeric) && String(value ?? '').trim() !== '' ? numeric : undefined;
}

function toArrayNumber(values: unknown) {
  if (!Array.isArray(values)) {
    return [];
  }
  return values.map((item) => Number(item)).filter((item) => Number.isFinite(item) && item > 0);
}

function toMultilineArray(value: unknown) {
  return String(value || '')
    .split('\n')
    .map((item) => item.trim())
    .filter(Boolean);
}

function cloneDraft<T extends Record<string, unknown>>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

function getUserRole(user: SessionUser) {
  return (user.roles?.[0] || user.role || 'subscriber') as UserRole;
}

async function confirmAction(message: string) {
  if (Platform.OS === 'web' && typeof window !== 'undefined' && typeof window.confirm === 'function') {
    return window.confirm(message);
  }

  return new Promise<boolean>((resolve) => {
    Alert.alert('请确认', message, [
      { text: '取消', style: 'cancel', onPress: () => resolve(false) },
      { text: '继续', style: 'destructive', onPress: () => resolve(true) },
    ]);
  });
}

function selectFromTerms(items: WpTerm[]): SelectOption[] {
  return items.map((item) => ({ label: item.name, value: String(item.id) }));
}

function selectFromLinkCategories(items: WpLinkCategory[]): SelectOption[] {
  return items.map((item) => ({ label: item.name, value: String(item.id) }));
}

function cleanPayload(payload: Record<string, unknown>) {
  return Object.fromEntries(Object.entries(payload).filter(([, value]) => value !== undefined));
}

function CrudScreen<TItem>({
  title,
  description,
  emptyText,
  fields,
  createLabel = '新建',
  searchPlaceholder,
  filterSpec,
  loadPage,
  createItem,
  updateItem,
  deleteItem,
  defaultDraft,
  toDraft,
  toPayload,
  getId,
  getTitle,
  getSubtitle,
  getBadges,
  renderDetails,
  onMutated,
}: CrudScreenProps<TItem>) {
  const [items, setItems] = useState<TItem[]>([]);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterValue, setFilterValue] = useState(filterSpec?.initialValue || '');
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [sheetVisible, setSheetVisible] = useState(false);
  const [saving, setSaving] = useState(false);
  const [editingItem, setEditingItem] = useState<TItem | null>(null);
  const [draft, setDraft] = useState<Record<string, unknown>>(cloneDraft(defaultDraft));
  const [refreshToken, setRefreshToken] = useState(0);
  const deferredSearch = useDeferredValue(search.trim());
  const loadPageRef = useRef(loadPage);
  const createItemRef = useRef(createItem);
  const updateItemRef = useRef(updateItem);
  const deleteItemRef = useRef(deleteItem);
  const onMutatedRef = useRef(onMutated);

  loadPageRef.current = loadPage;
  createItemRef.current = createItem;
  updateItemRef.current = updateItem;
  deleteItemRef.current = deleteItem;
  onMutatedRef.current = onMutated;

  async function reload() {
    setLoading(true);
    setError(null);
    try {
      const result = await loadPageRef.current({
        page,
        perPage: 12,
        search: deferredSearch,
        filterValue,
      });
      setItems(result.items);
      setTotal(result.total);
      setTotalPages(result.totalPages || 1);
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : '加载失败');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    reload();
  }, [page, deferredSearch, filterValue, refreshToken]);

  function openCreate() {
    setEditingItem(null);
    setDraft(cloneDraft(defaultDraft));
    setNotice(null);
    setSheetVisible(true);
  }

  function openEdit(item: TItem) {
    setEditingItem(item);
    setDraft({ ...cloneDraft(defaultDraft), ...toDraft(item) });
    setNotice(null);
    setSheetVisible(true);
  }

  function updateDraftValue(key: string, value: unknown) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  async function submit() {
    const missingField = fields.find((field) => {
      if (!field.required) {
        return false;
      }
      const value = draft[field.key];
      if (field.type === 'multiselect') {
        return !Array.isArray(value) || value.length === 0;
      }
      if (field.type === 'boolean') {
        return false;
      }
      return String(value ?? '').trim() === '';
    });

    if (missingField) {
      setNotice(`请先填写：${missingField.label}`);
      return;
    }

    try {
      setSaving(true);
      const payload = cleanPayload(toPayload(draft, editingItem));
      if (editingItem) {
        await updateItemRef.current(editingItem, payload);
      } else {
        await createItemRef.current(payload);
      }
      setSheetVisible(false);
      setDraft(cloneDraft(defaultDraft));
      setNotice(editingItem ? '已更新' : '已创建');
      setRefreshToken((value) => value + 1);
      await onMutatedRef.current?.();
    } catch (submitError) {
      setNotice(submitError instanceof Error ? submitError.message : '保存失败');
    } finally {
      setSaving(false);
    }
  }

  async function remove(item: TItem) {
    if (!deleteItemRef.current) {
      return;
    }
    const confirmed = await confirmAction(`确定要处理「${getTitle(item)}」吗？`);
    if (!confirmed) {
      return;
    }
    try {
      await deleteItemRef.current(item);
      setNotice('操作已完成');
      setRefreshToken((value) => value + 1);
      await onMutatedRef.current?.();
    } catch (removeError) {
      setNotice(removeError instanceof Error ? removeError.message : '删除失败');
    }
  }

  return (
    <ScrollView contentContainerStyle={surfaceStyles.scrollContent}>
      <ScreenTitle
        title={title}
        description={description}
        extra={
          <View style={styles.rowWrap}>
            <Button label="刷新" variant="secondary" onPress={() => setRefreshToken((value) => value + 1)} />
            <Button label={createLabel} onPress={openCreate} />
          </View>
        }
      />
      <Card title="筛选与统计" subtitle={`当前共 ${total} 条`}>
        <View style={styles.grid}>
          {searchPlaceholder ? (
            <View style={styles.filterBlock}>
              <TextField
                label="搜索"
                value={search}
                onChangeText={(value) => {
                  setPage(1);
                  setSearch(value);
                }}
                placeholder={searchPlaceholder}
              />
            </View>
          ) : null}
          {filterSpec ? (
            <View style={styles.filterBlock}>
              <Text style={styles.filterLabel}>{filterSpec.label}</Text>
              <View style={styles.rowWrap}>
                {filterSpec.options.map((option) => {
                  const active = option.value === filterValue;
                  return (
                    <Pressable
                      key={option.value}
                      onPress={() => {
                        setPage(1);
                        setFilterValue(option.value);
                      }}
                      style={[styles.navChip, active && styles.navChipActive]}
                    >
                      <Text style={[styles.navChipText, active && styles.navChipTextActive]}>{option.label}</Text>
                    </Pressable>
                  );
                })}
              </View>
            </View>
          ) : null}
        </View>
      </Card>
      <InlineMessage kind={error ? 'danger' : 'success'} message={error || notice} />
      {loading ? (
        <Card title="正在加载" subtitle="正在同步远程数据，请稍候。" />
      ) : items.length === 0 ? (
        <EmptyState title={emptyText} />
      ) : (
        items.map((item) => (
          <Card
            key={getId(item)}
            title={getTitle(item)}
            subtitle={getSubtitle?.(item)}
            badges={getBadges?.(item) || []}
            actions={
              <View style={styles.rowWrap}>
                <Button label="编辑" variant="secondary" compact onPress={() => openEdit(item)} />
                {deleteItem ? <Button label="删除" variant="danger" compact onPress={() => remove(item)} /> : null}
              </View>
            }
          >
            {renderDetails?.(item)}
          </Card>
        ))
      )}
      <Card title="翻页" subtitle={`第 ${page} / ${Math.max(totalPages, 1)} 页`}>
        <View style={styles.rowWrap}>
          <Button label="上一页" variant="secondary" disabled={page <= 1} onPress={() => setPage((value) => Math.max(1, value - 1))} />
          <Button label="下一页" variant="secondary" disabled={page >= totalPages} onPress={() => setPage((value) => Math.min(totalPages, value + 1))} />
        </View>
      </Card>
      <Sheet
        visible={sheetVisible}
        title={editingItem ? `编辑${title}` : createLabel}
        description="表单字段与原始 CFBlog 后端接口保持一致。"
        onClose={() => setSheetVisible(false)}
        footer={
          <View style={styles.rowWrap}>
            <Button label="取消" variant="ghost" onPress={() => setSheetVisible(false)} />
            <Button label={saving ? '保存中...' : '保存'} onPress={submit} disabled={saving} />
          </View>
        }
      >
        <InlineMessage kind="danger" message={notice} />
        <View style={styles.formStack}>
          {fields.map((field) => (
            <FieldRenderer key={field.key} field={field} draft={draft} setValue={updateDraftValue} />
          ))}
        </View>
      </Sheet>
    </ScrollView>
  );
}

function DashboardScreen({
  client,
  references,
  siteName,
  onNavigate,
}: {
  client: CfblogApi;
  references: ReferenceData;
  siteName: string;
  onNavigate: (key: NavKey) => void;
}) {
  const [stats, setStats] = useState<Record<string, string>>({
    posts: '-',
    pages: '-',
    moments: '-',
    comments: '-',
    media: '-',
    users: String(references.users.length),
  });
  const [message, setMessage] = useState<string | null>(null);

  async function loadStats() {
    try {
      const [posts, pages, moments, comments, media] = await Promise.all([
        client.listPosts({ page: 1, per_page: 1, status: 'publish' }),
        client.listPages({ page: 1, per_page: 1, status: 'all' }),
        client.listMoments({ page: 1, per_page: 1, status: 'all' }),
        client.listComments({ page: 1, per_page: 1, status: 'all' }),
        client.listMedia({ page: 1, per_page: 1 }),
      ]);

      setStats({
        posts: String(posts.total),
        pages: String(pages.total),
        moments: String(moments.total),
        comments: String(comments.total),
        media: String(media.total),
        users: String(references.users.length),
      });
      setMessage(null);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '统计加载失败');
    }
  }

  useEffect(() => {
    loadStats();
  }, [references.users.length]);

  return (
    <ScrollView contentContainerStyle={surfaceStyles.scrollContent}>
      <ScreenTitle
        title={siteName || 'CFBlog Mobile'}
        description="跨平台移动工作台，适合手机和平板上的日常博客更新。"
        extra={<Button label="刷新统计" variant="secondary" onPress={loadStats} />}
      />
      <InlineMessage kind={message ? 'danger' : 'info'} message={message} />
      <View style={surfaceStyles.twoColumn}>
        <StatBox label="文章" value={stats.posts} />
        <StatBox label="页面" value={stats.pages} />
        <StatBox label="动态" value={stats.moments} />
        <StatBox label="评论" value={stats.comments} />
        <StatBox label="媒体" value={stats.media} />
        <StatBox label="用户" value={stats.users} />
      </View>
      <Card title="快捷操作" subtitle="直接进入高频更新入口。">
        <View style={styles.rowWrap}>
          <Button label="写文章" onPress={() => onNavigate('posts')} />
          <Button label="发动态" onPress={() => onNavigate('moments')} />
          <Button label="传媒体" variant="secondary" onPress={() => onNavigate('media')} />
          <Button label="审评论" variant="secondary" onPress={() => onNavigate('comments')} />
        </View>
      </Card>
      <Card title="资源概览" subtitle="引用数据用于快速定位。">
        <View style={styles.rowWrap}>
          {references.categories.slice(0, 6).map((item) => (
            <Badge key={`category-${item.id}`} label={`分类 ${item.name}`} />
          ))}
          {references.tags.slice(0, 6).map((item) => (
            <Badge key={`tag-${item.id}`} label={`标签 ${item.name}`} />
          ))}
        </View>
      </Card>
    </ScrollView>
  );
}

function MediaScreen({ client }: { client: CfblogApi }) {
  const [items, setItems] = useState<WpMedia[]>([]);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState<string | null>(null);
  const [sheetVisible, setSheetVisible] = useState(false);
  const [editing, setEditing] = useState<WpMedia | null>(null);
  const [uploading, setUploading] = useState(false);
  const [draft, setDraft] = useState<Record<string, unknown>>({
    title: '',
    alt_text: '',
    caption: '',
    description: '',
  });
  const [editDraft, setEditDraft] = useState<Record<string, unknown>>({
    title: '',
    alt_text: '',
    caption: '',
    description: '',
  });
  const [selectedFile, setSelectedFile] = useState<DocumentPicker.DocumentPickerAsset | null>(null);

  async function loadMedia() {
    setLoading(true);
    try {
      const result = await client.listMedia({ page, per_page: 12 });
      setItems(result.items);
      setTotalPages(result.totalPages);
      setMessage(null);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '媒体加载失败');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadMedia();
  }, [page]);

  async function chooseFile() {
    const result = await DocumentPicker.getDocumentAsync({
      multiple: false,
      copyToCacheDirectory: true,
    });

    if (!result.canceled) {
      setSelectedFile(result.assets[0]);
      setDraft((current) => ({
        ...current,
        title: current.title || result.assets[0].name,
      }));
    }
  }

  async function submitUpload() {
    if (!selectedFile) {
      setMessage('请先选择文件');
      return;
    }

    try {
      setUploading(true);
      const formData = new FormData();
      const assetWithFile = selectedFile as DocumentPicker.DocumentPickerAsset & { file?: Blob };

      if (Platform.OS === 'web' && assetWithFile.file) {
        formData.append('file', assetWithFile.file);
      } else {
        formData.append('file', {
          uri: selectedFile.uri,
          name: selectedFile.name,
          type: selectedFile.mimeType || 'application/octet-stream',
        } as unknown as Blob);
      }

      formData.append('title', String(draft.title || selectedFile.name));
      formData.append('alt_text', String(draft.alt_text || ''));
      formData.append('caption', String(draft.caption || ''));
      formData.append('description', String(draft.description || ''));

      await client.uploadMedia(formData);
      setDraft({ title: '', alt_text: '', caption: '', description: '' });
      setSelectedFile(null);
      setMessage('媒体上传成功');
      await loadMedia();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '上传失败');
    } finally {
      setUploading(false);
    }
  }

  function openEdit(item: WpMedia) {
    setEditing(item);
    setEditDraft({
      title: stripHtml(item.title.rendered),
      alt_text: item.alt_text || '',
      caption: stripHtml(item.caption.rendered),
      description: stripHtml(item.description.rendered),
    });
    setSheetVisible(true);
  }

  async function saveEdit() {
    if (!editing) {
      return;
    }

    try {
      await client.update(`/media/${editing.id}`, cleanPayload({
        title: String(editDraft.title || ''),
        alt_text: String(editDraft.alt_text || ''),
        caption: String(editDraft.caption || ''),
        description: String(editDraft.description || ''),
      }));
      setSheetVisible(false);
      setMessage('媒体信息已更新');
      await loadMedia();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '保存失败');
    }
  }

  async function remove(item: WpMedia) {
    const confirmed = await confirmAction(`确定要删除媒体「${stripHtml(item.title.rendered) || item.slug}」吗？`);
    if (!confirmed) {
      return;
    }

    try {
      await client.remove(`/media/${item.id}`, { force: true });
      setMessage('媒体已删除');
      await loadMedia();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '删除失败');
    }
  }

  return (
    <ScrollView contentContainerStyle={surfaceStyles.scrollContent}>
      <ScreenTitle
        title="媒体库"
        description="支持 R2 媒体上传、图片说明维护和移动端快速选图。"
        extra={<Button label="刷新" variant="secondary" onPress={loadMedia} />}
      />
      <InlineMessage kind="danger" message={message} />
      <Card title="上传新媒体" subtitle={selectedFile ? selectedFile.name : '支持图片、视频、PDF。'}>
        <View style={styles.formStack}>
          <View style={styles.rowWrap}>
            <Button label={selectedFile ? '重新选择' : '选择文件'} variant="secondary" onPress={chooseFile} />
            <Button label={uploading ? '上传中...' : '开始上传'} onPress={submitUpload} disabled={uploading} />
          </View>
          <FieldRenderer field={{ key: 'title', label: '标题', type: 'text' }} draft={draft} setValue={(key, value) => setDraft((current) => ({ ...current, [key]: value }))} />
          <FieldRenderer field={{ key: 'alt_text', label: '替代文本', type: 'text' }} draft={draft} setValue={(key, value) => setDraft((current) => ({ ...current, [key]: value }))} />
          <FieldRenderer field={{ key: 'caption', label: '说明', type: 'textarea' }} draft={draft} setValue={(key, value) => setDraft((current) => ({ ...current, [key]: value }))} />
          <FieldRenderer field={{ key: 'description', label: '描述', type: 'textarea' }} draft={draft} setValue={(key, value) => setDraft((current) => ({ ...current, [key]: value }))} />
        </View>
      </Card>
      {loading ? (
        <Card title="正在加载媒体" subtitle="请稍候。" />
      ) : items.length === 0 ? (
        <EmptyState title="媒体库还是空的。" />
      ) : (
        items.map((item) => (
          <Card
            key={item.id}
            title={stripHtml(item.title.rendered) || item.slug}
            subtitle={`${item.mime_type} · ${formatDate(item.date)}`}
            badges={[item.media_type]}
            actions={
              <View style={styles.rowWrap}>
                <Button label="编辑" compact variant="secondary" onPress={() => openEdit(item)} />
                <Button label="删除" compact variant="danger" onPress={() => remove(item)} />
              </View>
            }
          >
            <View style={styles.mediaCard}>
              {item.mime_type.startsWith('image/') ? (
                <Image source={{ uri: item.source_url }} style={styles.mediaPreview} />
              ) : (
                <View style={[styles.mediaPreview, styles.mediaPlaceholder]}>
                  <Text style={styles.mediaPlaceholderText}>非图片文件</Text>
                </View>
              )}
              <View style={{ flex: 1, gap: 8 }}>
                <Text style={styles.detailText}>ALT: {item.alt_text || '未填写'}</Text>
                <Text style={styles.detailText}>说明: {stripHtml(item.caption.rendered) || '未填写'}</Text>
                <Text style={styles.detailText}>链接: {item.source_url}</Text>
              </View>
            </View>
          </Card>
        ))
      )}
      <Card title="翻页" subtitle={`第 ${page} / ${Math.max(1, totalPages)} 页`}>
        <View style={styles.rowWrap}>
          <Button label="上一页" variant="secondary" disabled={page <= 1} onPress={() => setPage((value) => Math.max(1, value - 1))} />
          <Button label="下一页" variant="secondary" disabled={page >= totalPages} onPress={() => setPage((value) => Math.min(totalPages, value + 1))} />
        </View>
      </Card>
      <Sheet
        visible={sheetVisible}
        title="编辑媒体信息"
        onClose={() => setSheetVisible(false)}
        footer={
          <View style={styles.rowWrap}>
            <Button label="取消" variant="ghost" onPress={() => setSheetVisible(false)} />
            <Button label="保存" onPress={saveEdit} />
          </View>
        }
      >
        <View style={styles.formStack}>
          <FieldRenderer field={{ key: 'title', label: '标题', type: 'text' }} draft={editDraft} setValue={(key, value) => setEditDraft((current) => ({ ...current, [key]: value }))} />
          <FieldRenderer field={{ key: 'alt_text', label: '替代文本', type: 'text' }} draft={editDraft} setValue={(key, value) => setEditDraft((current) => ({ ...current, [key]: value }))} />
          <FieldRenderer field={{ key: 'caption', label: '说明', type: 'textarea' }} draft={editDraft} setValue={(key, value) => setEditDraft((current) => ({ ...current, [key]: value }))} />
          <FieldRenderer field={{ key: 'description', label: '描述', type: 'textarea' }} draft={editDraft} setValue={(key, value) => setEditDraft((current) => ({ ...current, [key]: value }))} />
        </View>
      </Sheet>
    </ScrollView>
  );
}

function SettingsScreen({ client, isAdmin }: { client: CfblogApi; isAdmin: boolean }) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [draft, setDraft] = useState<Record<string, unknown>>({});
  const sections: { title: string; fields: FormField[] }[] = [
    {
      title: '站点基础',
      fields: [
        { key: 'site_title', label: '站点标题', type: 'text' },
        { key: 'site_url', label: '站点 URL', type: 'url' },
        { key: 'admin_email', label: '管理员邮箱', type: 'email' },
        { key: 'site_description', label: '站点描述', type: 'textarea' },
        { key: 'site_keywords', label: '关键词', type: 'text' },
        { key: 'site_author', label: '作者', type: 'text' },
        { key: 'site_favicon', label: 'Favicon URL', type: 'url' },
        { key: 'site_logo', label: 'Logo URL', type: 'url' },
      ],
    },
    {
      title: '通知与邮件',
      fields: [
        { key: 'mail_from_name', label: '发件人名称', type: 'text' },
        { key: 'mail_from_email', label: '发件人邮箱', type: 'email' },
        { key: 'mail_notifications_enabled', label: '开启邮件通知', type: 'boolean' },
        { key: 'notify_admin_on_comment', label: '新评论通知管理员', type: 'boolean' },
        { key: 'notify_commenter_on_reply', label: '回复时通知评论者', type: 'boolean' },
      ],
    },
    {
      title: '前台展示',
      fields: [
        { key: 'site_notice', label: '站点公告', type: 'textarea' },
        { key: 'site_icp', label: '备案号', type: 'text' },
        { key: 'site_footer_text', label: '页脚文本', type: 'textarea' },
        { key: 'head_html', label: 'Head 自定义代码', type: 'multiline' },
      ],
    },
    {
      title: '社交与联系',
      fields: [
        { key: 'social_telegram', label: 'Telegram', type: 'text' },
        { key: 'social_x', label: 'X', type: 'text' },
        { key: 'social_mastodon', label: 'Mastodon', type: 'text' },
        { key: 'social_email', label: '联系邮箱', type: 'email' },
        { key: 'social_qq', label: 'QQ', type: 'text' },
      ],
    },
    {
      title: 'Webhook',
      fields: [
        { key: 'webhook_url', label: 'Webhook URL', type: 'url' },
        { key: 'webhook_secret', label: 'Webhook Secret', type: 'password' },
        { key: 'webhook_events', label: 'Webhook 事件', type: 'multiline', helper: '每行一个，或保持逗号分隔。常用：post.published、post.updated' },
      ],
    },
  ];

  async function loadSettings() {
    setLoading(true);
    try {
      const data = await client.getSettings(isAdmin);
      setDraft({
        ...data,
        mail_notifications_enabled: data.mail_notifications_enabled === '1',
        notify_admin_on_comment: data.notify_admin_on_comment !== '0',
        notify_commenter_on_reply: data.notify_commenter_on_reply !== '0',
        webhook_events: String(data.webhook_events || '').split(',').join('\n'),
      });
      setMessage(null);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '设置加载失败');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadSettings();
  }, [isAdmin]);

  async function submit() {
    if (!isAdmin) {
      setMessage('当前账号不是管理员，不能保存设置。');
      return;
    }
    try {
      setSaving(true);
      const payload: SettingsRecord = {};
      Object.entries(draft).forEach(([key, value]) => {
        if (typeof value === 'boolean') {
          payload[key] = value ? '1' : '0';
        } else if (key === 'webhook_events') {
          payload[key] = toMultilineArray(value).join(',');
        } else {
          payload[key] = String(value ?? '');
        }
      });
      await client.updateSettings(payload);
      setMessage('设置已保存');
      await loadSettings();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '保存失败');
    } finally {
      setSaving(false);
    }
  }

  return (
    <ScrollView contentContainerStyle={surfaceStyles.scrollContent}>
      <ScreenTitle
        title="系统设置"
        description="站点基础信息、通知、社交资料和 webhook 都可以在这里维护。"
        extra={
          <View style={styles.rowWrap}>
            <Button label="刷新" variant="secondary" onPress={loadSettings} />
            <Button label={saving ? '保存中...' : '保存设置'} onPress={submit} disabled={saving || !isAdmin} />
          </View>
        }
      />
      <InlineMessage kind={message?.includes('失败') || message?.includes('不能') ? 'danger' : 'success'} message={message} />
      {loading ? (
        <Card title="正在加载设置" subtitle="请稍候。" />
      ) : (
        sections.map((section) => (
          <Card key={section.title} title={section.title}>
            <View style={styles.formStack}>
              {section.fields.map((field) => (
                <FieldRenderer key={field.key} field={field} draft={draft} setValue={(key, value) => setDraft((current) => ({ ...current, [key]: value }))} />
              ))}
            </View>
          </Card>
        ))
      )}
    </ScrollView>
  );
}

function SetupScreen({
  initialUrl,
  onLogin,
  onRegister,
  onConnectOnly,
}: {
  initialUrl: string;
  onLogin: (url: string, username: string, password: string) => Promise<void>;
  onRegister: (url: string, username: string, email: string, password: string, displayName: string) => Promise<void>;
  onConnectOnly: (url: string) => Promise<DiscoveryInfo>;
}) {
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [baseUrl, setBaseUrl] = useState(initialUrl);
  const [discovery, setDiscovery] = useState<DiscoveryInfo | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [loginForm, setLoginForm] = useState({ username: '', password: '' });
  const [registerForm, setRegisterForm] = useState({ username: '', email: '', password: '', displayName: '' });

  async function connect() {
    try {
      setBusy(true);
      const info = await onConnectOnly(normalizeUrl(baseUrl));
      setDiscovery(info);
      setMessage('站点连接成功');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '连接失败');
    } finally {
      setBusy(false);
    }
  }

  async function submitLogin() {
    try {
      setBusy(true);
      await onLogin(normalizeUrl(baseUrl), loginForm.username, loginForm.password);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '登录失败');
    } finally {
      setBusy(false);
    }
  }

  async function submitRegister() {
    try {
      setBusy(true);
      await onRegister(normalizeUrl(baseUrl), registerForm.username, registerForm.email, registerForm.password, registerForm.displayName);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : '注册失败');
    } finally {
      setBusy(false);
    }
  }

  return (
    <ScrollView contentContainerStyle={[surfaceStyles.scrollContent, { paddingVertical: 32 }]}>
      <View style={styles.hero}>
        <Text style={styles.heroEyebrow}>CFBlog Mobile</Text>
        <Text style={styles.heroTitle}>把你的 Cloudflare 博客后台带到手机上</Text>
        <Text style={styles.heroText}>这个客户端直接连接现有 `cfblog` 的 WordPress 风格接口，适合写文、改稿、审评论、传媒体和更新设置。</Text>
      </View>
      <Card title="连接站点" subtitle="填写现有 CFBlog 部署地址，例如 https://blog.example.com">
        <View style={styles.formStack}>
          <TextField label="站点地址" value={baseUrl} onChangeText={setBaseUrl} placeholder="https://your-domain.com" keyboardType="url" />
          <View style={styles.rowWrap}>
            <Button label={busy ? '连接中...' : '测试连接'} variant="secondary" onPress={connect} disabled={busy} />
          </View>
          {discovery ? (
            <View style={styles.discoveryBox}>
              <Text style={styles.discoveryTitle}>{discovery.name || 'CFBlog'}</Text>
              <Text style={styles.discoveryText}>{discovery.description || '接口连接成功'}</Text>
              <Text style={styles.discoveryText}>{discovery.home || discovery.url}</Text>
            </View>
          ) : null}
        </View>
      </Card>
      <Card
        title={mode === 'login' ? '登录后台' : '注册首个账号'}
        subtitle={mode === 'login' ? '使用已存在账号进入移动工作台。' : '首个注册用户会自动成为管理员。'}
        actions={
          <View style={styles.rowWrap}>
            <Button label="登录" compact variant={mode === 'login' ? 'primary' : 'ghost'} onPress={() => setMode('login')} />
            <Button label="注册" compact variant={mode === 'register' ? 'primary' : 'ghost'} onPress={() => setMode('register')} />
          </View>
        }
      >
        <InlineMessage kind={message?.includes('成功') ? 'success' : 'danger'} message={message} />
        {mode === 'login' ? (
          <View style={styles.formStack}>
            <TextField label="用户名或邮箱" value={loginForm.username} onChangeText={(value) => setLoginForm((current) => ({ ...current, username: value }))} />
            <TextField label="密码" value={loginForm.password} onChangeText={(value) => setLoginForm((current) => ({ ...current, password: value }))} secureTextEntry />
            <Button label={busy ? '登录中...' : '进入客户端'} onPress={submitLogin} disabled={busy} />
          </View>
        ) : (
          <View style={styles.formStack}>
            <TextField label="用户名" value={registerForm.username} onChangeText={(value) => setRegisterForm((current) => ({ ...current, username: value }))} />
            <TextField label="显示名称" value={registerForm.displayName} onChangeText={(value) => setRegisterForm((current) => ({ ...current, displayName: value }))} />
            <TextField label="邮箱" value={registerForm.email} onChangeText={(value) => setRegisterForm((current) => ({ ...current, email: value }))} keyboardType="email-address" />
            <TextField label="密码" value={registerForm.password} onChangeText={(value) => setRegisterForm((current) => ({ ...current, password: value }))} secureTextEntry />
            <Button label={busy ? '注册中...' : '创建账号并进入'} onPress={submitRegister} disabled={busy} />
          </View>
        )}
      </Card>
    </ScrollView>
  );
}

function AdminShell(_: {
  config: AppConfig;
  session: SessionState;
  onLogout: () => Promise<void>;
  onResetSite: () => Promise<void>;
}) {
  const { config, session, onLogout, onResetSite } = _;
  const { width } = useWindowDimensions();
  const compact = width < 980;
  const [screen, setScreen] = useState<NavKey>('dashboard');
  const [references, setReferences] = useState<ReferenceData>(emptyReferences);
  const [refMessage, setRefMessage] = useState<string | null>(null);
  const client = new CfblogApi(config.baseUrl, session.token);
  const userRole = getUserRole(session.user);

  async function loadReferences() {
    try {
      const [categories, tags, linkCategories, users] = await Promise.all([
        client.listCategories({ page: 1, per_page: 100 }),
        client.listTags({ page: 1, per_page: 100 }),
        client.listLinkCategories(),
        client.listUsers({ page: 1, per_page: 100 }),
      ]);

      setReferences({
        categories: categories.items,
        tags: tags.items,
        linkCategories,
        users: users.items,
      });
      setRefMessage(null);
    } catch (error) {
      setRefMessage(error instanceof Error ? error.message : '引用数据加载失败');
    }
  }

  useEffect(() => {
    loadReferences();
  }, [config.baseUrl, session.token]);

  function renderScreen() {
    switch (screen) {
      case 'dashboard':
        return <DashboardScreen client={client} references={references} siteName={session.user.name} onNavigate={setScreen} />;
      case 'posts':
        return (
          <CrudScreen<WpPost>
            title="文章管理"
            description="支持草稿、发布、置顶、分类标签和封面字段。"
            emptyText="还没有文章。"
            createLabel="写文章"
            searchPlaceholder="搜索标题或正文"
            filterSpec={{ label: '文章状态', queryKey: 'status', initialValue: 'publish', options: postStatusOptions }}
            fields={[
              { key: 'title', label: '标题', type: 'text', required: true },
              { key: 'slug', label: 'Slug', type: 'text' },
              { key: 'status', label: '状态', type: 'select', options: postStatusOptions.filter((item) => item.value !== 'trash') },
              { key: 'sticky', label: '置顶', type: 'boolean' },
              { key: 'date', label: '发布时间', type: 'text', placeholder: '2026-04-12T09:00:00Z' },
              { key: 'featured_media', label: '封面媒体 ID', type: 'number' },
              { key: 'featured_image_url', label: '封面图片 URL', type: 'url' },
              { key: 'categories', label: '分类', type: 'multiselect', options: selectFromTerms(references.categories) },
              { key: 'tags', label: '标签', type: 'multiselect', options: selectFromTerms(references.tags) },
              { key: 'excerpt', label: '摘要', type: 'textarea' },
              { key: 'content', label: '正文', type: 'multiline', required: true },
            ]}
            loadPage={({ page, perPage, search, filterValue }) => client.listPosts({ page, per_page: perPage, search, status: filterValue || 'publish' })}
            createItem={(payload) => client.create('/posts', payload)}
            updateItem={(item, payload) => client.update(`/posts/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/posts/${item.id}`)}
            defaultDraft={{ title: '', slug: '', status: 'draft', sticky: false, date: '', featured_media: '', featured_image_url: '', categories: [], tags: [], excerpt: '', content: '' }}
            toDraft={(item) => ({
              title: stripHtml(item.title.rendered),
              slug: item.slug,
              status: item.status,
              sticky: Boolean(item.sticky),
              date: item.date || '',
              featured_media: item.featured_media ? String(item.featured_media) : '',
              featured_image_url: item.featured_image_url || '',
              categories: (item.categories || []).map(String),
              tags: (item.tags || []).map(String),
              excerpt: stripHtml(item.excerpt.rendered),
              content: item.content.raw || stripHtml(item.content.rendered),
            })}
            toPayload={(draft) => ({
              title: String(draft.title || ''),
              slug: String(draft.slug || '') || undefined,
              status: String(draft.status || 'draft'),
              sticky: Boolean(draft.sticky),
              date: String(draft.date || '') || undefined,
              featured_media: toOptionalNumber(draft.featured_media),
              featured_image_url: String(draft.featured_image_url || '') || undefined,
              categories: toArrayNumber(draft.categories),
              tags: toArrayNumber(draft.tags),
              excerpt: String(draft.excerpt || ''),
              content: String(draft.content || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => stripHtml(item.title.rendered)}
            getSubtitle={(item) => `/${item.slug} · ${formatDate(item.modified || item.date)}`}
            getBadges={(item) => [item.status, item.sticky ? '置顶' : '', `${item.comment_count || 0} 评论`, `${item.view_count || 0} 浏览`].filter(Boolean)}
            renderDetails={(item) => <Text style={styles.detailText}>{stripHtml(item.excerpt.rendered) || '暂无摘要'}</Text>}
          />
        );
      case 'pages':
        return (
          <CrudScreen<WpPost>
            title="页面管理"
            description="维护 About、归档、友链等固定页面。"
            emptyText="还没有页面。"
            createLabel="新建页面"
            filterSpec={{ label: '页面状态', queryKey: 'status', initialValue: 'all', options: pageStatusOptions }}
            fields={[
              { key: 'title', label: '标题', type: 'text', required: true },
              { key: 'slug', label: 'Slug', type: 'text' },
              { key: 'status', label: '状态', type: 'select', options: postStatusOptions.filter((item) => item.value !== 'trash') },
              { key: 'parent', label: '父页面 ID', type: 'number' },
              { key: 'comment_status', label: '评论状态', type: 'select', options: [{ label: '开放', value: 'open' }, { label: '关闭', value: 'closed' }] },
              { key: 'excerpt', label: '摘要', type: 'textarea' },
              { key: 'content', label: '正文', type: 'multiline', required: true },
            ]}
            loadPage={({ page, perPage, filterValue }) => client.listPages({ page, per_page: perPage, status: filterValue || 'all' })}
            createItem={(payload) => client.create('/pages', payload)}
            updateItem={(item, payload) => client.update(`/pages/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/pages/${item.id}`)}
            defaultDraft={{ title: '', slug: '', status: 'draft', parent: '', comment_status: 'open', excerpt: '', content: '' }}
            toDraft={(item) => ({
              title: stripHtml(item.title.rendered),
              slug: item.slug,
              status: item.status,
              parent: item.parent ? String(item.parent) : '',
              comment_status: item.comment_status || 'open',
              excerpt: stripHtml(item.excerpt.rendered),
              content: item.content.raw || stripHtml(item.content.rendered),
            })}
            toPayload={(draft) => ({
              title: String(draft.title || ''),
              slug: String(draft.slug || '') || undefined,
              status: String(draft.status || 'draft'),
              parent: toOptionalNumber(draft.parent),
              comment_status: String(draft.comment_status || 'open'),
              excerpt: String(draft.excerpt || ''),
              content: String(draft.content || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => stripHtml(item.title.rendered)}
            getSubtitle={(item) => `/${item.slug} · ${formatDate(item.modified || item.date)}`}
            getBadges={(item) => [item.status, item.comment_status || 'open']}
            renderDetails={(item) => <Text style={styles.detailText}>{stripHtml(item.excerpt.rendered) || '暂无摘要'}</Text>}
          />
        );
      case 'moments':
        return (
          <CrudScreen<WpMoment>
            title="动态管理"
            description="适合手机快速发布短内容，也能挂接媒体 URL。"
            emptyText="还没有动态。"
            createLabel="发动态"
            filterSpec={{ label: '动态状态', queryKey: 'status', initialValue: 'all', options: momentStatusOptions }}
            fields={[
              { key: 'status', label: '状态', type: 'select', options: momentStatusOptions.filter((item) => item.value !== 'all') },
              { key: 'content', label: '内容', type: 'multiline', required: true },
              { key: 'media_urls', label: '媒体 URL', type: 'multiline', helper: '每行一个 URL，可直接引用 R2 媒体地址。' },
            ]}
            loadPage={({ page, perPage, filterValue }) => client.listMoments({ page, per_page: perPage, status: filterValue || 'all' })}
            createItem={(payload) => client.create('/moments', payload)}
            updateItem={(item, payload) => client.update(`/moments/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/moments/${item.id}`)}
            defaultDraft={{ status: 'publish', content: '', media_urls: '' }}
            toDraft={(item) => ({
              status: item.status,
              content: item.content.raw || stripHtml(item.content.rendered),
              media_urls: (item.media_urls || []).join('\n'),
            })}
            toPayload={(draft) => ({
              status: String(draft.status || 'publish'),
              content: String(draft.content || ''),
              media_urls: toMultilineArray(draft.media_urls),
            })}
            getId={(item) => item.id}
            getTitle={(item) => stripHtml(item.content.rendered).slice(0, 26) || `动态 #${item.id}`}
            getSubtitle={(item) => `${item.author_name} · ${formatDate(item.modified || item.date)}`}
            getBadges={(item) => [item.status, `${item.like_count || 0} 赞`, `${item.comment_count || 0} 评论`]}
            renderDetails={(item) => (
              <View style={styles.formStack}>
                <Text style={styles.detailText}>{stripHtml(item.content.rendered)}</Text>
                {item.media_urls?.length ? <Text style={styles.detailText}>媒体：{item.media_urls.length} 个</Text> : null}
              </View>
            )}
          />
        );
      case 'comments':
        return (
          <CrudScreen<WpComment>
            title="评论管理"
            description="审核、回复或手工补录文章评论。"
            emptyText="暂无评论。"
            createLabel="补录评论"
            filterSpec={{ label: '评论状态', queryKey: 'status', initialValue: 'all', options: commentStatusOptions }}
            fields={[
              { key: 'post', label: '文章 ID', type: 'number', required: true },
              { key: 'parent', label: '父评论 ID', type: 'number' },
              { key: 'status', label: '状态', type: 'select', options: commentStatusOptions.filter((item) => item.value !== 'all') },
              { key: 'author_name', label: '作者名', type: 'text', required: true },
              { key: 'author_email', label: '作者邮箱', type: 'email', required: true },
              { key: 'author_url', label: '作者网址', type: 'url' },
              { key: 'author_ip', label: '作者 IP', type: 'text' },
              { key: 'content', label: '评论内容', type: 'multiline', required: true },
            ]}
            loadPage={({ page, perPage, filterValue }) => client.listComments({ page, per_page: perPage, status: filterValue || 'all' })}
            createItem={(payload) => client.create('/comments', payload)}
            updateItem={(item, payload) => client.update(`/comments/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/comments/${item.id}`)}
            defaultDraft={{ post: '', parent: '', status: 'approved', author_name: '', author_email: '', author_url: '', author_ip: '', content: '' }}
            toDraft={(item) => ({
              post: item.post ? String(item.post) : '',
              parent: item.parent ? String(item.parent) : '',
              status: item.status,
              author_name: item.author_name,
              author_email: item.author_email || '',
              author_url: item.author_url || '',
              author_ip: item.author_ip || '',
              content: stripHtml(item.content.rendered),
            })}
            toPayload={(draft) => ({
              post: toOptionalNumber(draft.post),
              parent: toOptionalNumber(draft.parent),
              status: String(draft.status || 'approved'),
              author_name: String(draft.author_name || ''),
              author_email: String(draft.author_email || ''),
              author_url: String(draft.author_url || ''),
              author_ip: String(draft.author_ip || ''),
              content: String(draft.content || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.author_name}
            getSubtitle={(item) => `${item.post_title || `文章 #${item.post || '-'}`} · ${formatDate(item.date)}`}
            getBadges={(item) => [item.status, item.parent ? `回复 ${item.parent}` : '顶级评论']}
            renderDetails={(item) => <Text style={styles.detailText}>{stripHtml(item.content.rendered)}</Text>}
          />
        );
      case 'moment-comments':
        return (
          <CrudScreen<WpComment>
            title="动态评论"
            description="集中审核动态下的评论。"
            emptyText="暂无动态评论。"
            createLabel="补录动态评论"
            filterSpec={{ label: '评论状态', queryKey: 'status', initialValue: 'all', options: commentStatusOptions }}
            fields={[
              { key: 'moment', label: '动态 ID', type: 'number', required: true },
              { key: 'parent', label: '父评论 ID', type: 'number' },
              { key: 'status', label: '状态', type: 'select', options: commentStatusOptions.filter((item) => item.value !== 'all') },
              { key: 'author_name', label: '作者名', type: 'text', required: true },
              { key: 'author_email', label: '作者邮箱', type: 'email', required: true },
              { key: 'author_url', label: '作者网址', type: 'url' },
              { key: 'author_ip', label: '作者 IP', type: 'text' },
              { key: 'content', label: '评论内容', type: 'multiline', required: true },
            ]}
            loadPage={({ page, perPage, filterValue }) => client.listMomentComments({ page, per_page: perPage, status: filterValue || 'all' })}
            createItem={(payload) => client.create(`/moments/${payload.moment}/comments`, payload)}
            updateItem={(item, payload) => client.update(`/moments/${item.moment}/comments/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/moments/${item.moment}/comments/${item.id}`)}
            defaultDraft={{ moment: '', parent: '', status: 'approved', author_name: '', author_email: '', author_url: '', author_ip: '', content: '' }}
            toDraft={(item) => ({
              moment: item.moment ? String(item.moment) : '',
              parent: item.parent ? String(item.parent) : '',
              status: item.status,
              author_name: item.author_name,
              author_email: item.author_email || '',
              author_url: item.author_url || '',
              author_ip: item.author_ip || '',
              content: stripHtml(item.content.rendered),
            })}
            toPayload={(draft) => ({
              moment: toOptionalNumber(draft.moment),
              parent: toOptionalNumber(draft.parent),
              status: String(draft.status || 'approved'),
              author_name: String(draft.author_name || ''),
              author_email: String(draft.author_email || ''),
              author_url: String(draft.author_url || ''),
              author_ip: String(draft.author_ip || ''),
              content: String(draft.content || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.author_name}
            getSubtitle={(item) => `${item.post_title || `动态 #${item.moment || '-'}`} · ${formatDate(item.date)}`}
            getBadges={(item) => [item.status, item.parent ? `回复 ${item.parent}` : '顶级评论']}
            renderDetails={(item) => <Text style={styles.detailText}>{stripHtml(item.content.rendered)}</Text>}
          />
        );
      case 'categories':
        return (
          <CrudScreen<WpTerm>
            title="分类管理"
            description="支持父分类、描述和 slug 维护。"
            emptyText="暂无分类。"
            createLabel="新建分类"
            searchPlaceholder="按分类名搜索"
            fields={[
              { key: 'name', label: '名称', type: 'text', required: true },
              { key: 'slug', label: 'Slug', type: 'text' },
              { key: 'parent', label: '父分类 ID', type: 'number' },
              { key: 'description', label: '描述', type: 'textarea' },
            ]}
            loadPage={({ page, perPage, search }) => client.listCategories({ page, per_page: perPage, search })}
            createItem={(payload) => client.create('/categories', payload)}
            updateItem={(item, payload) => client.update(`/categories/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/categories/${item.id}`, { force: true })}
            defaultDraft={{ name: '', slug: '', parent: '', description: '' }}
            toDraft={(item) => ({ name: item.name, slug: item.slug, parent: item.parent ? String(item.parent) : '', description: item.description || '' })}
            toPayload={(draft) => ({
              name: String(draft.name || ''),
              slug: String(draft.slug || '') || undefined,
              parent: toOptionalNumber(draft.parent),
              description: String(draft.description || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.name}
            getSubtitle={(item) => `/${item.slug}`}
            getBadges={(item) => [`${item.count || 0} 篇`, item.parent ? `父级 ${item.parent}` : '顶级']}
            renderDetails={(item) => <Text style={styles.detailText}>{item.description || '无描述'}</Text>}
            onMutated={loadReferences}
          />
        );
      case 'tags':
        return (
          <CrudScreen<WpTerm>
            title="标签管理"
            description="管理文章标签与 slug。"
            emptyText="暂无标签。"
            createLabel="新建标签"
            searchPlaceholder="按标签名搜索"
            fields={[
              { key: 'name', label: '名称', type: 'text', required: true },
              { key: 'slug', label: 'Slug', type: 'text' },
              { key: 'description', label: '描述', type: 'textarea' },
            ]}
            loadPage={({ page, perPage, search }) => client.listTags({ page, per_page: perPage, search })}
            createItem={(payload) => client.create('/tags', payload)}
            updateItem={(item, payload) => client.update(`/tags/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/tags/${item.id}`, { force: true })}
            defaultDraft={{ name: '', slug: '', description: '' }}
            toDraft={(item) => ({ name: item.name, slug: item.slug, description: item.description || '' })}
            toPayload={(draft) => ({
              name: String(draft.name || ''),
              slug: String(draft.slug || '') || undefined,
              description: String(draft.description || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.name}
            getSubtitle={(item) => `/${item.slug}`}
            getBadges={(item) => [`${item.count || 0} 篇文章`]}
            renderDetails={(item) => <Text style={styles.detailText}>{item.description || '无描述'}</Text>}
            onMutated={loadReferences}
          />
        );
      case 'links':
        return (
          <CrudScreen<WpLink>
            title="友链管理"
            description="适合移动端维护友链名称、头像、可见性和排序。"
            emptyText="暂无友链。"
            createLabel="新建友链"
            filterSpec={{ label: '展示状态', queryKey: 'visible', initialValue: 'yes', options: visibleOptions }}
            fields={[
              { key: 'name', label: '名称', type: 'text', required: true },
              { key: 'url', label: '链接地址', type: 'url', required: true },
              { key: 'avatar', label: '头像 URL', type: 'url' },
              { key: 'category_id', label: '所属分类', type: 'select', options: selectFromLinkCategories(references.linkCategories) },
              { key: 'target', label: '打开方式', type: 'select', options: [{ label: '新窗口', value: '_blank' }, { label: '当前窗口', value: '_self' }] },
              { key: 'visible', label: '是否展示', type: 'select', options: visibleOptions },
              { key: 'rating', label: '评分', type: 'number' },
              { key: 'sort_order', label: '排序', type: 'number' },
              { key: 'description', label: '描述', type: 'textarea' },
            ]}
            loadPage={({ page, perPage, filterValue }) => client.listLinks({ page, per_page: perPage, visible: filterValue || 'yes' })}
            createItem={(payload) => client.create('/links', payload)}
            updateItem={(item, payload) => client.update(`/links/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/links/${item.id}`)}
            defaultDraft={{
              name: '',
              url: '',
              avatar: '',
              category_id: references.linkCategories[0] ? String(references.linkCategories[0].id) : '1',
              target: '_blank',
              visible: 'yes',
              rating: '0',
              sort_order: '0',
              description: '',
            }}
            toDraft={(item) => ({
              name: item.name,
              url: item.url,
              avatar: item.avatar || '',
              category_id: item.category?.id ? String(item.category.id) : '1',
              target: item.target || '_blank',
              visible: item.visible || 'yes',
              rating: item.rating ? String(item.rating) : '0',
              sort_order: item.sort_order ? String(item.sort_order) : '0',
              description: item.description || '',
            })}
            toPayload={(draft) => ({
              name: String(draft.name || ''),
              url: String(draft.url || ''),
              avatar: String(draft.avatar || ''),
              category_id: toOptionalNumber(draft.category_id) || 1,
              target: String(draft.target || '_blank'),
              visible: String(draft.visible || 'yes'),
              rating: toOptionalNumber(draft.rating) || 0,
              sort_order: toOptionalNumber(draft.sort_order) || 0,
              description: String(draft.description || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.name}
            getSubtitle={(item) => item.url}
            getBadges={(item) => [item.visible || 'yes', item.category?.name || '未分类', `排序 ${item.sort_order || 0}`]}
            renderDetails={(item) => <Text style={styles.detailText}>{item.description || '无描述'}</Text>}
          />
        );
      case 'link-categories':
        return (
          <CrudScreen<WpLinkCategory>
            title="友链分类"
            description="维护友情链接分类。"
            emptyText="暂无友链分类。"
            createLabel="新建友链分类"
            fields={[
              { key: 'name', label: '名称', type: 'text', required: true },
              { key: 'slug', label: 'Slug', type: 'text' },
              { key: 'description', label: '描述', type: 'textarea' },
            ]}
            loadPage={async ({ page, perPage }) => {
              const items = await client.listLinkCategories();
              const start = (page - 1) * perPage;
              return { items: items.slice(start, start + perPage), total: items.length, totalPages: Math.max(1, Math.ceil(items.length / perPage)) };
            }}
            createItem={(payload) => client.create('/link-categories', payload)}
            updateItem={(item, payload) => client.update(`/link-categories/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/link-categories/${item.id}`)}
            defaultDraft={{ name: '', slug: '', description: '' }}
            toDraft={(item) => ({ name: item.name, slug: item.slug, description: item.description || '' })}
            toPayload={(draft) => ({
              name: String(draft.name || ''),
              slug: String(draft.slug || '') || undefined,
              description: String(draft.description || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.name}
            getSubtitle={(item) => `/${item.slug}`}
            getBadges={(item) => [`${item.count || 0} 条友链`]}
            renderDetails={(item) => <Text style={styles.detailText}>{item.description || '无描述'}</Text>}
            onMutated={loadReferences}
          />
        );
      case 'users':
        return (
          <CrudScreen<SessionUser>
            title="用户管理"
            description="支持新增、角色调整、资料更新和停用。"
            emptyText="暂无用户。"
            createLabel="新建用户"
            filterSpec={{ label: '角色筛选', queryKey: 'role', initialValue: '', options: [{ label: '全部', value: '' }, ...roleOptions] }}
            searchPlaceholder="搜索用户名、邮箱或显示名"
            fields={[
              { key: 'username', label: '用户名', type: 'text', required: true },
              { key: 'email', label: '邮箱', type: 'email', required: true },
              { key: 'password', label: '密码', type: 'password' },
              { key: 'display_name', label: '显示名', type: 'text' },
              { key: 'role', label: '角色', type: 'select', options: roleOptions },
              { key: 'avatar_url', label: '头像 URL', type: 'url' },
              { key: 'bio', label: '简介', type: 'textarea' },
            ]}
            loadPage={({ page, perPage, search, filterValue }) => client.listUsers({ page, per_page: perPage, search, role: filterValue || undefined })}
            createItem={(payload) => client.create('/users', payload)}
            updateItem={(item, payload) => client.update(`/users/${item.id}`, payload)}
            deleteItem={(item) => client.remove(`/users/${item.id}`)}
            defaultDraft={{ username: '', email: '', password: '', display_name: '', role: 'subscriber', avatar_url: '', bio: '' }}
            toDraft={(item) => ({
              username: item.slug,
              email: item.email || '',
              password: '',
              display_name: item.name,
              role: getUserRole(item),
              avatar_url: item.avatar_urls?.['96'] || '',
              bio: item.description || '',
            })}
            toPayload={(draft) => ({
              username: String(draft.username || ''),
              email: String(draft.email || ''),
              password: String(draft.password || '') || undefined,
              display_name: String(draft.display_name || ''),
              role: String(draft.role || 'subscriber'),
              avatar_url: String(draft.avatar_url || ''),
              bio: String(draft.bio || ''),
            })}
            getId={(item) => item.id}
            getTitle={(item) => item.name}
            getSubtitle={(item) => item.email || item.slug}
            getBadges={(item) => [getUserRole(item), item.registered_date ? formatDate(item.registered_date) : '']}
            renderDetails={(item) => <Text style={styles.detailText}>{item.description || '暂无简介'}</Text>}
            onMutated={loadReferences}
          />
        );
      case 'media':
        return <MediaScreen client={client} />;
      case 'settings':
        return <SettingsScreen client={client} isAdmin={userRole === 'administrator'} />;
      default:
        return <DashboardScreen client={client} references={references} siteName={session.user.name} onNavigate={setScreen} />;
    }
  }

  return (
    <View style={styles.shell}>
      {compact ? (
        <View style={styles.mobileTopNav}>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.mobileNavScroll}>
            {navItems.map((item) => {
              const active = item.key === screen;
              return (
                <Pressable key={item.key} onPress={() => setScreen(item.key)} style={[styles.navChip, active && styles.navChipActive]}>
                  <Text style={[styles.navChipText, active && styles.navChipTextActive]}>{item.label}</Text>
                </Pressable>
              );
            })}
          </ScrollView>
        </View>
      ) : (
        <View style={styles.sidebar}>
          <Text style={styles.sidebarBrand}>CFBlog Mobile</Text>
          <Text style={styles.sidebarMeta}>{config.baseUrl}</Text>
          <View style={styles.sidebarList}>
            {navItems.map((item) => {
              const active = item.key === screen;
              return (
                <Pressable key={item.key} onPress={() => setScreen(item.key)} style={[styles.sidebarItem, active && styles.sidebarItemActive]}>
                  <Text style={[styles.sidebarItemText, active && styles.sidebarItemTextActive]}>{item.label}</Text>
                </Pressable>
              );
            })}
          </View>
          <View style={styles.sidebarFooter}>
            <Text style={styles.sidebarMeta}>{session.user.name}</Text>
            <Text style={styles.sidebarMeta}>{getUserRole(session.user)}</Text>
          </View>
        </View>
      )}

      <View style={styles.main}>
        <View style={styles.topBar}>
          <View style={{ flex: 1 }}>
            <Text style={styles.topBarTitle}>{session.user.name}</Text>
            <Text style={styles.topBarMeta}>{config.baseUrl}</Text>
            {refMessage ? <Text style={[styles.topBarMeta, { color: palette.danger }]}>{refMessage}</Text> : null}
          </View>
          <View style={styles.rowWrap}>
            <Button label="刷新引用" variant="secondary" compact onPress={loadReferences} />
            <Button label="退出登录" variant="ghost" compact onPress={() => void onLogout()} />
            <Button label="切换站点" variant="ghost" compact onPress={() => void onResetSite()} />
          </View>
        </View>
        {renderScreen()}
      </View>
    </View>
  );
}

export function AppRoot() {
  const [booting, setBooting] = useState(true);
  const [config, setConfig] = useState<AppConfig>({ baseUrl: '' });
  const [session, setSession] = useState<SessionState | null>(null);

  useEffect(() => {
    async function bootstrap() {
      try {
        const [savedConfig, savedSession] = await Promise.all([loadConfig(), loadSession()]);

        if (savedConfig?.baseUrl) {
          setConfig(savedConfig);
        }

        if (savedConfig?.baseUrl && savedSession?.token) {
          try {
            const api = new CfblogApi(savedConfig.baseUrl, savedSession.token);
            const user = await api.getCurrentUser();
            const nextSession = { token: savedSession.token, user };
            setSession(nextSession);
            await saveSession(nextSession);
          } catch {
            await clearSession();
          }
        }
      } finally {
        setBooting(false);
      }
    }

    bootstrap();
  }, []);

  async function persistConfig(baseUrl: string) {
    const nextConfig = { baseUrl };
    setConfig(nextConfig);
    await saveConfig(nextConfig);
    const api = new CfblogApi(baseUrl);
    return api.getDiscovery();
  }

  async function handleLogin(baseUrl: string, username: string, password: string) {
    await persistConfig(baseUrl);
    const api = new CfblogApi(baseUrl);
    const data = await api.login(username, password);
    const nextSession = { token: data.token, user: data.user };
    setSession(nextSession);
    await saveSession(nextSession);
  }

  async function handleRegister(baseUrl: string, username: string, email: string, password: string, displayName: string) {
    await persistConfig(baseUrl);
    const api = new CfblogApi(baseUrl);
    const data = await api.register(username, email, password, displayName || username);
    const nextSession = { token: data.token, user: data.user };
    setSession(nextSession);
    await saveSession(nextSession);
  }

  async function handleLogout() {
    setSession(null);
    await clearSession();
  }

  async function handleResetSite() {
    const confirmed = await confirmAction('确定清空当前站点配置并返回连接页吗？');
    if (!confirmed) {
      return;
    }

    setSession(null);
    setConfig({ baseUrl: '' });
    await Promise.all([clearSession(), clearConfig()]);
  }

  if (booting) {
    return (
      <View style={styles.boot}>
        <Text style={styles.heroTitle}>正在启动客户端</Text>
        <Text style={styles.heroText}>检查本地配置与登录状态。</Text>
      </View>
    );
  }

  if (!config.baseUrl || !session) {
    return (
      <View style={styles.root}>
        <SetupScreen initialUrl={config.baseUrl} onConnectOnly={persistConfig} onLogin={handleLogin} onRegister={handleRegister} />
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <AdminShell config={config} session={session} onLogout={handleLogout} onResetSite={handleResetSite} />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: palette.background,
  },
  boot: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: palette.background,
    padding: 24,
    gap: 12,
  },
  hero: {
    backgroundColor: palette.shell,
    borderRadius: 30,
    padding: 28,
    gap: 12,
  },
  heroEyebrow: {
    color: '#BED6CC',
    textTransform: 'uppercase',
    letterSpacing: 1.2,
    fontWeight: '800',
  },
  heroTitle: {
    color: palette.white,
    fontSize: 34,
    lineHeight: 40,
    fontWeight: '900',
  },
  heroText: {
    color: '#E2EFE9',
    lineHeight: 22,
  },
  discoveryBox: {
    borderRadius: 18,
    backgroundColor: palette.surfaceAlt,
    padding: 14,
    gap: 6,
  },
  discoveryTitle: {
    color: palette.text,
    fontWeight: '800',
  },
  discoveryText: {
    color: palette.muted,
    lineHeight: 19,
  },
  shell: {
    flex: 1,
    flexDirection: 'row',
    backgroundColor: palette.background,
  },
  sidebar: {
    width: 244,
    backgroundColor: palette.shell,
    paddingTop: 28,
    paddingHorizontal: 18,
    paddingBottom: 18,
    gap: 18,
  },
  sidebarBrand: {
    color: palette.white,
    fontSize: 24,
    fontWeight: '900',
  },
  sidebarMeta: {
    color: '#B8CDC4',
    lineHeight: 19,
  },
  sidebarList: {
    gap: 10,
    flex: 1,
  },
  sidebarItem: {
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  sidebarItemActive: {
    backgroundColor: palette.shellSoft,
  },
  sidebarItemText: {
    color: '#D6E3DD',
    fontWeight: '700',
  },
  sidebarItemTextActive: {
    color: palette.white,
  },
  sidebarFooter: {
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.12)',
    paddingTop: 16,
    gap: 4,
  },
  main: {
    flex: 1,
  },
  topBar: {
    paddingHorizontal: 18,
    paddingTop: 16,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: palette.border,
    backgroundColor: 'rgba(255, 249, 242, 0.9)',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
  },
  topBarTitle: {
    color: palette.text,
    fontSize: 20,
    fontWeight: '800',
  },
  topBarMeta: {
    color: palette.muted,
    lineHeight: 19,
    marginTop: 4,
  },
  mobileTopNav: {
    borderBottomWidth: 1,
    borderBottomColor: palette.border,
    backgroundColor: palette.surface,
  },
  mobileNavScroll: {
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 10,
  },
  navChip: {
    borderRadius: 999,
    borderWidth: 1,
    borderColor: palette.border,
    backgroundColor: palette.surfaceAlt,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  navChipActive: {
    backgroundColor: palette.shell,
    borderColor: palette.shell,
  },
  navChipText: {
    color: palette.text,
    fontWeight: '700',
  },
  navChipTextActive: {
    color: palette.white,
  },
  rowWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  grid: {
    gap: 16,
  },
  filterBlock: {
    gap: 10,
  },
  filterLabel: {
    color: palette.text,
    fontWeight: '800',
  },
  formStack: {
    gap: 16,
  },
  detailText: {
    color: palette.text,
    lineHeight: 21,
  },
  mediaCard: {
    flexDirection: 'row',
    gap: 14,
    alignItems: 'flex-start',
  },
  mediaPreview: {
    width: 92,
    height: 92,
    borderRadius: 18,
    backgroundColor: palette.surfaceAlt,
  },
  mediaPlaceholder: {
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: palette.border,
  },
  mediaPlaceholderText: {
    color: palette.muted,
    textAlign: 'center',
    paddingHorizontal: 10,
  },
});
