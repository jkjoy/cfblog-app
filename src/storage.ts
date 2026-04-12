import AsyncStorage from '@react-native-async-storage/async-storage';
import type { AppConfig, SessionState } from './types';

const CONFIG_KEY = 'cfblog-mobile-config';
const SESSION_KEY = 'cfblog-mobile-session';

export async function loadConfig(): Promise<AppConfig | null> {
  const raw = await AsyncStorage.getItem(CONFIG_KEY);
  return raw ? (JSON.parse(raw) as AppConfig) : null;
}

export async function saveConfig(config: AppConfig): Promise<void> {
  await AsyncStorage.setItem(CONFIG_KEY, JSON.stringify(config));
}

export async function clearConfig(): Promise<void> {
  await AsyncStorage.removeItem(CONFIG_KEY);
}

export async function loadSession(): Promise<SessionState | null> {
  const raw = await AsyncStorage.getItem(SESSION_KEY);
  return raw ? (JSON.parse(raw) as SessionState) : null;
}

export async function saveSession(session: SessionState): Promise<void> {
  await AsyncStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

export async function clearSession(): Promise<void> {
  await AsyncStorage.removeItem(SESSION_KEY);
}
