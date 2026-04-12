import { StatusBar } from 'expo-status-bar';
import { SafeAreaView } from 'react-native';
import { AppRoot } from './src/app';

export default function App() {
  return (
    <SafeAreaView style={{ flex: 1 }}>
      <StatusBar style="dark" />
      <AppRoot />
    </SafeAreaView>
  );
}
