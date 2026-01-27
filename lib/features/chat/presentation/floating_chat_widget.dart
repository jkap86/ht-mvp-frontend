import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/states/states.dart';
import '../../../core/widgets/user_avatar.dart';
import '../domain/chat_message.dart';
import 'providers/chat_provider.dart';

/// Floating chat widget that can be collapsed to a FAB or expanded to a
/// draggable, resizable panel. Persists position and size across sessions.
class FloatingChatWidget extends ConsumerStatefulWidget {
  final int leagueId;

  const FloatingChatWidget({super.key, required this.leagueId});

  @override
  ConsumerState<FloatingChatWidget> createState() => _FloatingChatWidgetState();
}

class _FloatingChatWidgetState extends ConsumerState<FloatingChatWidget>
    with SingleTickerProviderStateMixin {
  // Persistence keys
  static const _keyPositionX = 'floating_chat_position_x';
  static const _keyPositionY = 'floating_chat_position_y';
  static const _keyWidth = 'floating_chat_width';
  static const _keyHeight = 'floating_chat_height';

  // Size constraints
  static const _minSize = Size(280, 300);
  static const _maxSize = Size(500, 600);
  static const _defaultSize = Size(350, 400);

  // State
  bool _isExpanded = false;
  Offset? _position; // null until we know screen size
  Size _size = _defaultSize;
  bool _isLoaded = false;

  // Controllers for chat
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadSavedState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animationController.forward();
  }

  void _collapse() {
    _animationController.reverse().then((_) {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble(_keyPositionX);
    final savedY = prefs.getDouble(_keyPositionY);
    final savedWidth = prefs.getDouble(_keyWidth);
    final savedHeight = prefs.getDouble(_keyHeight);

    setState(() {
      if (savedX != null && savedY != null) {
        _position = Offset(savedX, savedY);
      }
      if (savedWidth != null && savedHeight != null) {
        _size = Size(
          savedWidth.clamp(_minSize.width, _maxSize.width),
          savedHeight.clamp(_minSize.height, _maxSize.height),
        );
      }
      _isLoaded = true;
    });
  }

  Future<void> _saveState() async {
    if (_position == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPositionX, _position!.dx);
    await prefs.setDouble(_keyPositionY, _position!.dy);
    await prefs.setDouble(_keyWidth, _size.width);
    await prefs.setDouble(_keyHeight, _size.height);
  }

  Offset _getDefaultPosition(Size screenSize) {
    return Offset(
      screenSize.width - _size.width - 16,
      screenSize.height - _size.height - 16,
    );
  }

  void _clampPosition(Size screenSize) {
    if (_position == null) return;
    final maxX = screenSize.width - _size.width;
    final maxY = screenSize.height - _size.height;
    _position = Offset(
      _position!.dx.clamp(0, maxX.clamp(0, double.infinity)),
      _position!.dy.clamp(0, maxY.clamp(0, double.infinity)),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final notifier = ref.read(chatProvider(widget.leagueId).notifier);
    final success = await notifier.sendMessage(text);
    if (success) {
      _messageController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    // Positioned.fill ensures this widget fills the parent Stack
    // Then we use our own internal Stack for positioning children
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableSize = Size(constraints.maxWidth, constraints.maxHeight);

          // Initialize position if not set
          _position ??= _getDefaultPosition(availableSize);

          // Ensure position is within bounds
          _clampPosition(availableSize);

          // Internal Stack allows Positioned children to work correctly
          // Show both during animation for smooth transition
          return Stack(
            children: [
              if (!_isExpanded || _animationController.isAnimating)
                _buildCollapsedButton(),
              if (_isExpanded || _animationController.isAnimating)
                _buildExpandedPanel(availableSize),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        heroTag: 'floating_chat_fab',
        onPressed: _expand,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildExpandedPanel(Size availableSize) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(chatProvider(widget.leagueId));

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomRight,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: _size.width,
              height: _size.height,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildHeader(colorScheme, availableSize),
                  Expanded(child: _buildMessageList(state)),
                  _buildMessageInput(state, colorScheme),
                  _buildResizeHandle(availableSize, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, Size availableSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final maxX = availableSize.width - _size.width;
          final maxY = availableSize.height - _size.height;
          _position = Offset(
            (_position!.dx + details.delta.dx).clamp(0, maxX.clamp(0, double.infinity)),
            (_position!.dy + details.delta.dy).clamp(0, maxY.clamp(0, double.infinity)),
          );
        });
      },
      onPanEnd: (_) => _saveState(),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.drag_indicator,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'League Chat',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.onPrimaryContainer),
              onPressed: _collapse,
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    if (state.isLoading) {
      return const AppLoadingView();
    }

    if (state.messages.isEmpty) {
      return const AppEmptyView(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Start the conversation!',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildMessageInput(ChatState state, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                isDense: true,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: state.isSending ? null : _sendMessage,
            icon: state.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 18),
            iconSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle(Size availableSize, ColorScheme colorScheme) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Dynamic max: can't exceed available space from current position
          final maxWidth = (availableSize.width - _position!.dx - 8)
              .clamp(_minSize.width, _maxSize.width);
          final maxHeight = (availableSize.height - _position!.dy - 8)
              .clamp(_minSize.height, availableSize.height - 8);

          final newWidth = (_size.width + details.delta.dx)
              .clamp(_minSize.width, maxWidth);
          final newHeight = (_size.height + details.delta.dy)
              .clamp(_minSize.height, maxHeight);
          _size = Size(newWidth, newHeight);
        });
      },
      onPanEnd: (_) => _saveState(),
      child: Align(
        alignment: Alignment.bottomRight,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            child: Icon(
              Icons.open_in_full,
              size: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: message.username,
            size: 28,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message.message,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
