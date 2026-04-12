import type { ReactNode } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { palette } from './theme';
import type { FormField, SelectOption } from './types';

export function Button({
  label,
  onPress,
  variant = 'primary',
  compact = false,
  disabled = false,
}: {
  label: string;
  onPress?: () => void;
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  compact?: boolean;
  disabled?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        compact && styles.buttonCompact,
        variant === 'primary' && styles.buttonPrimary,
        variant === 'secondary' && styles.buttonSecondary,
        variant === 'ghost' && styles.buttonGhost,
        variant === 'danger' && styles.buttonDanger,
        disabled && styles.buttonDisabled,
        pressed && !disabled && styles.buttonPressed,
      ]}
    >
      <Text
        style={[
          styles.buttonLabel,
          variant === 'ghost' && styles.buttonLabelGhost,
          variant === 'secondary' && styles.buttonLabelSecondary,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

export function Card({
  title,
  subtitle,
  badges = [],
  children,
  actions,
}: {
  title: string;
  subtitle?: string;
  badges?: string[];
  children?: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <View style={styles.card}>
      <View style={styles.cardTop}>
        <View style={{ flex: 1 }}>
          <Text style={styles.cardTitle}>{title}</Text>
          {subtitle ? <Text style={styles.cardSubtitle}>{subtitle}</Text> : null}
          {badges.length ? (
            <View style={styles.badgeRow}>
              {badges.map((badge) => (
                <Badge key={badge} label={badge} />
              ))}
            </View>
          ) : null}
        </View>
        {actions ? <View style={styles.actionRow}>{actions}</View> : null}
      </View>
      {children ? <View style={styles.cardBody}>{children}</View> : null}
    </View>
  );
}

export function Badge({ label }: { label: string }) {
  return (
    <View style={styles.badge}>
      <Text style={styles.badgeText}>{label}</Text>
    </View>
  );
}

export function ScreenTitle({
  title,
  description,
  extra,
}: {
  title: string;
  description: string;
  extra?: ReactNode;
}) {
  return (
    <View style={styles.screenTitle}>
      <View style={{ flex: 1 }}>
        <Text style={styles.screenHeading}>{title}</Text>
        <Text style={styles.screenDescription}>{description}</Text>
      </View>
      {extra ? <View style={styles.actionRow}>{extra}</View> : null}
    </View>
  );
}

export function InlineMessage({
  kind = 'info',
  message,
}: {
  kind?: 'info' | 'success' | 'danger';
  message?: string | null;
}) {
  if (!message) {
    return null;
  }

  return (
    <View
      style={[
        styles.message,
        kind === 'success' && styles.messageSuccess,
        kind === 'danger' && styles.messageDanger,
      ]}
    >
      <Text style={styles.messageText}>{message}</Text>
    </View>
  );
}

export function EmptyState({ title }: { title: string }) {
  return (
    <View style={styles.emptyState}>
      <Text style={styles.emptyTitle}>{title}</Text>
    </View>
  );
}

export function TextField({
  label,
  value,
  onChangeText,
  placeholder,
  multiline = false,
  secureTextEntry = false,
  keyboardType,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  placeholder?: string;
  multiline?: boolean;
  secureTextEntry?: boolean;
  keyboardType?: 'default' | 'email-address' | 'numeric' | 'url';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <TextInput
        style={[styles.input, multiline && styles.inputMultiline]}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={palette.muted}
        multiline={multiline}
        secureTextEntry={secureTextEntry}
        keyboardType={keyboardType}
      />
    </View>
  );
}

export function FieldRenderer({
  field,
  draft,
  setValue,
}: {
  field: FormField;
  draft: Record<string, unknown>;
  setValue: (key: string, value: unknown) => void;
}) {
  const value = draft[field.key];

  if (field.type === 'boolean') {
    const active = Boolean(value);
    return (
      <View style={styles.field}>
        <Text style={styles.fieldLabel}>{field.label}</Text>
        {field.helper ? <Text style={styles.helper}>{field.helper}</Text> : null}
        <Pressable
          onPress={() => setValue(field.key, !active)}
          style={[styles.toggle, active && styles.toggleActive]}
        >
          <Text style={[styles.toggleText, active && styles.toggleTextActive]}>
            {active ? '已开启' : '已关闭'}
          </Text>
        </Pressable>
      </View>
    );
  }

  if (field.type === 'select') {
    return (
      <OptionGroup
        label={field.label}
        helper={field.helper}
        value={String(value ?? '')}
        options={field.options || []}
        onSelect={(next) => setValue(field.key, next)}
        multiple={false}
      />
    );
  }

  if (field.type === 'multiselect') {
    const values = Array.isArray(value) ? value.map(String) : [];
    return (
      <OptionGroup
        label={field.label}
        helper={field.helper}
        value={values}
        options={field.options || []}
        onSelect={(next) => setValue(field.key, next)}
        multiple
      />
    );
  }

  const keyboardType =
    field.type === 'email'
      ? 'email-address'
      : field.type === 'number'
        ? 'numeric'
        : field.type === 'url'
          ? 'url'
          : 'default';

  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{field.label}</Text>
      {field.helper ? <Text style={styles.helper}>{field.helper}</Text> : null}
      <TextInput
        style={[
          styles.input,
          (field.type === 'textarea' || field.type === 'multiline') && styles.inputMultiline,
        ]}
        value={String(value ?? '')}
        onChangeText={(next) => setValue(field.key, next)}
        placeholder={field.placeholder}
        placeholderTextColor={palette.muted}
        multiline={field.type === 'textarea' || field.type === 'multiline'}
        secureTextEntry={field.type === 'password'}
        keyboardType={keyboardType}
      />
    </View>
  );
}

function OptionGroup({
  label,
  helper,
  value,
  options,
  onSelect,
  multiple,
}: {
  label: string;
  helper?: string;
  value: string | string[];
  options: SelectOption[];
  onSelect: (value: string | string[]) => void;
  multiple: boolean;
}) {
  const currentValues = Array.isArray(value) ? value : [value];

  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      {helper ? <Text style={styles.helper}>{helper}</Text> : null}
      <View style={styles.optionWrap}>
        {options.map((option) => {
          const selected = currentValues.includes(option.value);
          return (
            <Pressable
              key={option.value}
              onPress={() => {
                if (!multiple) {
                  onSelect(option.value);
                  return;
                }

                if (selected) {
                  onSelect(currentValues.filter((item) => item !== option.value));
                } else {
                  onSelect([...currentValues, option.value]);
                }
              }}
              style={[styles.optionChip, selected && styles.optionChipActive]}
            >
              <Text style={[styles.optionText, selected && styles.optionTextActive]}>
                {option.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

export function Sheet({
  visible,
  title,
  description,
  onClose,
  children,
  footer,
}: {
  visible: boolean;
  title: string;
  description?: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
}) {
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          <View style={styles.sheetHeader}>
            <View style={{ flex: 1 }}>
              <Text style={styles.sheetTitle}>{title}</Text>
              {description ? <Text style={styles.sheetDescription}>{description}</Text> : null}
            </View>
            <Button label="关闭" onPress={onClose} variant="ghost" compact />
          </View>
          <ScrollView style={styles.sheetBody} contentContainerStyle={{ paddingBottom: 24 }}>
            {children}
          </ScrollView>
          {footer ? <View style={styles.sheetFooter}>{footer}</View> : null}
        </View>
      </View>
    </Modal>
  );
}

export function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statBox}>
      <Text style={styles.statLabel}>{label}</Text>
      <Text style={styles.statValue}>{value}</Text>
    </View>
  );
}

export const surfaceStyles = StyleSheet.create({
  scrollContent: {
    padding: 20,
    gap: 16,
  },
  twoColumn: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
});

const styles = StyleSheet.create({
  button: {
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 12,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 92,
  },
  buttonCompact: {
    minWidth: 0,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  buttonPrimary: {
    backgroundColor: palette.accent,
  },
  buttonSecondary: {
    backgroundColor: palette.surfaceAlt,
    borderWidth: 1,
    borderColor: palette.border,
  },
  buttonGhost: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: palette.border,
  },
  buttonDanger: {
    backgroundColor: palette.danger,
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonPressed: {
    opacity: 0.86,
  },
  buttonLabel: {
    color: palette.white,
    fontWeight: '700',
  },
  buttonLabelSecondary: {
    color: palette.text,
  },
  buttonLabelGhost: {
    color: palette.text,
  },
  screenTitle: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
  },
  screenHeading: {
    fontSize: 30,
    fontWeight: '800',
    color: palette.text,
  },
  screenDescription: {
    marginTop: 6,
    color: palette.muted,
    lineHeight: 21,
  },
  card: {
    backgroundColor: palette.surface,
    borderRadius: 22,
    borderWidth: 1,
    borderColor: palette.border,
    padding: 18,
    gap: 12,
  },
  cardTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: palette.text,
  },
  cardSubtitle: {
    marginTop: 6,
    color: palette.muted,
    lineHeight: 20,
  },
  cardBody: {
    gap: 10,
  },
  actionRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  badgeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 10,
  },
  badge: {
    backgroundColor: palette.accentSoft,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  badgeText: {
    color: palette.accent,
    fontWeight: '700',
    fontSize: 12,
  },
  message: {
    borderRadius: 16,
    padding: 14,
    backgroundColor: palette.surfaceAlt,
    borderWidth: 1,
    borderColor: palette.border,
  },
  messageSuccess: {
    backgroundColor: '#E8F2EC',
    borderColor: '#9FC1AE',
  },
  messageDanger: {
    backgroundColor: '#F7E7E5',
    borderColor: '#D8A3A3',
  },
  messageText: {
    color: palette.text,
    lineHeight: 20,
  },
  emptyState: {
    borderStyle: 'dashed',
    borderWidth: 1,
    borderColor: palette.border,
    borderRadius: 20,
    padding: 24,
    backgroundColor: palette.surfaceAlt,
  },
  emptyTitle: {
    color: palette.muted,
    fontWeight: '600',
  },
  field: {
    gap: 8,
  },
  fieldLabel: {
    fontWeight: '800',
    color: palette.text,
  },
  helper: {
    color: palette.muted,
    lineHeight: 19,
  },
  input: {
    borderWidth: 1,
    borderColor: palette.border,
    borderRadius: 16,
    backgroundColor: palette.white,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: palette.text,
  },
  inputMultiline: {
    minHeight: 132,
    textAlignVertical: 'top',
  },
  toggle: {
    borderRadius: 999,
    borderWidth: 1,
    borderColor: palette.border,
    backgroundColor: palette.surfaceAlt,
    paddingVertical: 12,
    alignItems: 'center',
  },
  toggleActive: {
    backgroundColor: palette.shell,
    borderColor: palette.shell,
  },
  toggleText: {
    fontWeight: '800',
    color: palette.text,
  },
  toggleTextActive: {
    color: palette.white,
  },
  optionWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  optionChip: {
    borderRadius: 999,
    borderWidth: 1,
    borderColor: palette.border,
    backgroundColor: palette.surfaceAlt,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  optionChipActive: {
    backgroundColor: palette.shell,
    borderColor: palette.shell,
  },
  optionText: {
    color: palette.text,
    fontWeight: '700',
  },
  optionTextActive: {
    color: palette.white,
  },
  overlay: {
    flex: 1,
    backgroundColor: palette.overlay,
    justifyContent: 'center',
    padding: 16,
  },
  sheet: {
    maxHeight: '92%',
    backgroundColor: palette.surface,
    borderRadius: 28,
    paddingHorizontal: 18,
    paddingTop: 18,
  },
  sheetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 12,
    paddingBottom: 12,
  },
  sheetTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: palette.text,
  },
  sheetDescription: {
    marginTop: 6,
    color: palette.muted,
  },
  sheetBody: {
    maxHeight: '70%',
  },
  sheetFooter: {
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: palette.border,
  },
  statBox: {
    minWidth: 150,
    flexGrow: 1,
    backgroundColor: palette.surface,
    borderWidth: 1,
    borderColor: palette.border,
    borderRadius: 22,
    padding: 18,
    gap: 8,
  },
  statLabel: {
    color: palette.muted,
    fontWeight: '700',
  },
  statValue: {
    fontSize: 28,
    fontWeight: '900',
    color: palette.text,
  },
});
