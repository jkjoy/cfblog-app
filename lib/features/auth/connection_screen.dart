import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({
    super.key,
    required this.initialUrl,
    required this.initialDiscovery,
    required this.onInspect,
    required this.onLogin,
  });

  final String initialUrl;
  final DiscoveryInfo? initialDiscovery;
  final Future<DiscoveryInfo> Function(String baseUrl) onInspect;
  final Future<void> Function({
    required String baseUrl,
    required String username,
    required String password,
  })
  onLogin;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController _baseUrlController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  DiscoveryInfo? _discovery;
  String? _message;
  bool _isError = false;
  bool _inspecting = false;
  bool _loggingIn = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: _displayDomainInput(widget.initialUrl),
    );
    _discovery = widget.initialDiscovery;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _sanitizeDomainInput(String value) {
    final sanitized = _displayDomainInput(value);
    if (sanitized == value) {
      return;
    }

    _baseUrlController.value = TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }

  Future<void> _handleInspect() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _inspecting = true;
      _message = null;
    });
    try {
      final discovery = await widget.onInspect(_baseUrlController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _discovery = discovery;
        _isError = false;
        _message = '站点连接成功，可以继续登录。';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _inspecting = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loggingIn = true;
      _message = null;
    });
    try {
      await widget.onLogin(
        baseUrl: _baseUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;
    final compact = isCompactLayout(context);
    final stackedCredentials = width < 620;

    final introPanel = SurfaceCard(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 42 : 52,
                height: compact ? 42 : 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6D7C8),
                  borderRadius: BorderRadius.circular(compact ? 14 : 18),
                ),
                child: Icon(
                  Icons.space_dashboard_rounded,
                  color: const Color(0xFFD96C3D),
                  size: compact ? 20 : 24,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CFBlog APP',
                      style: (compact
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '你好,让我们开始写博客吧',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _IntroPill(icon: Icons.public_rounded),
              _IntroPill(icon: Icons.lock_rounded),
              _IntroPill(icon: Icons.devices_rounded),
            ],
          ),
        ],
      ),
    );

    final formPanel = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: '连接你的 CFBlog 站点',
            subtitle: '只输入域名即可，系统会自动补全 https 并连接 wp-json 接口。',
          ),
          SizedBox(height: compact ? 14 : 20),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            onChanged: _sanitizeDomainInput,
            decoration: const InputDecoration(
              labelText: '站点域名',
              hintText: 'your-domain.com',
              helperText: '支持子目录，例如 example.com/blog',
              prefixText: 'https://',
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          if (stackedCredentials)
            Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: '用户名'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: '用户名'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '密码'),
                  ),
                ),
              ],
            ),
          if (_message != null) ...[
            SizedBox(height: compact ? 12 : 16),
            InfoBanner(message: _message!, isError: _isError),
          ],
          SizedBox(height: compact ? 14 : 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _inspecting ? null : _handleInspect,
                icon: _inspecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded),
                label: Text(_inspecting ? '检查中...' : '检查站点'),
              ),
              FilledButton.icon(
                onPressed: _loggingIn ? null : _handleLogin,
                icon: _loggingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(_loggingIn ? '登录中...' : '登录工作台'),
              ),
            ],
          ),
          if (_discovery != null) ...[
            SizedBox(height: compact ? 16 : 24),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 14 : 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E8),
                borderRadius: BorderRadius.circular(compact ? 18 : 22),
                border: Border.all(color: const Color(0xFFD7CBBE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _discovery!.name.isEmpty ? '已识别站点' : _discovery!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _discovery!.description.isEmpty
                        ? '站点返回了有效的发现信息。'
                        : _discovery!.description,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _discovery!.home.isEmpty
                        ? _discovery!.url
                        : _discovery!.home,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 12 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 8, child: introPanel),
                          const SizedBox(width: 16),
                          Expanded(flex: 11, child: formPanel),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          introPanel,
                          SizedBox(height: compact ? 12 : 16),
                          formPanel,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _displayDomainInput(String value) {
  if (value.trim().isEmpty) {
    return '';
  }

  final normalized = normalizeBaseUrl(value);
  return normalized.replaceFirst(
    RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'),
    '',
  );
}

class _IntroPill extends StatelessWidget {
  const _IntroPill({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(
        icon,
        size: 16,
        color: AppTheme.textMuted,
      ),
    );
  }
}
