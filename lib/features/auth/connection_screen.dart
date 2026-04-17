import 'package:flutter/material.dart';

import '../../core/models.dart';
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
    _baseUrlController = TextEditingController(text: widget.initialUrl);
    _discovery = widget.initialDiscovery;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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

    final introPanel = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CFBlog Flutter 工作台',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            '为移动端后台维护重做的技术指挥台。先连接站点，再登录你的管理员或编辑账号。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _FeatureRow(
            icon: Icons.devices_rounded,
            title: '跨端一致',
            subtitle: '同一套 Flutter 界面覆盖 Android、iOS 和 Web。',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.dashboard_customize_rounded,
            title: '更清晰的层级',
            subtitle: '从内容维护任务出发，优先展示高频操作和状态反馈。',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: Icons.draw_rounded,
            title: '更强的视觉系统',
            subtitle: '深色指挥台侧栏配暖色内容区，减少传统后台的乏味感。',
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
            subtitle: '支持现有 wp-json/wp/v2 接口，无需改后端结构。',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '站点地址',
              hintText: 'https://your-domain.com',
            ),
          ),
          const SizedBox(height: 14),
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
            const SizedBox(height: 16),
            InfoBanner(message: _message!, isError: _isError),
          ],
          const SizedBox(height: 18),
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
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E8),
                borderRadius: BorderRadius.circular(22),
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
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: introPanel),
                          const SizedBox(width: 18),
                          Expanded(flex: 10, child: formPanel),
                        ],
                      )
                    : Column(
                        children: [
                          introPanel,
                          const SizedBox(height: 16),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF6D7C8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFFD96C3D)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
