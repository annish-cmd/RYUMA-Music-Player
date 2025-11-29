import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlphabetScrollbar extends StatefulWidget {
  final List<String> alphabet;
  final Function(String) onLetterSelected;
  final Set<String> availableLetters;
  final String? currentLetter;
  final Color? activeColor;
  final Color? inactiveColor;

  const AlphabetScrollbar({
    super.key,
    this.alphabet = const [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      '#',
    ],
    required this.onLetterSelected,
    this.availableLetters = const {},
    this.currentLetter,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AlphabetScrollbar> createState() => _AlphabetScrollbarState();
}

class _AlphabetScrollbarState extends State<AlphabetScrollbar> {
  String? _dragLetter;
  bool _isDragging = false;
  final GlobalKey _scrollbarKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(String letter) {
    _removeOverlay();

    final RenderBox? renderBox =
        _scrollbarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final index = widget.alphabet.indexOf(letter);
    final letterHeight = renderBox.size.height / widget.alphabet.length;
    final yPosition =
        position.dy + (index * letterHeight) + (letterHeight / 2) - 28;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: 50,
        top: yPosition,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.activeColor ?? const Color(0xFFBB86FC),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (widget.activeColor ?? const Color(0xFFBB86FC))
                      .withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _selectLetterAtPosition(details.localPosition);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _selectLetterAtPosition(details.localPosition);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragLetter = null;
    });
    _removeOverlay();
  }

  void _selectLetterAtPosition(Offset position) {
    final RenderBox? renderBox =
        _scrollbarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final height = renderBox.size.height;
    final letterHeight = height / widget.alphabet.length;
    int index = (position.dy / letterHeight).floor();
    index = index.clamp(0, widget.alphabet.length - 1);

    final letter = widget.alphabet[index];

    final isAvailable =
        widget.availableLetters.isEmpty ||
        widget.availableLetters.contains(letter);

    if (_dragLetter != letter && isAvailable) {
      setState(() {
        _dragLetter = letter;
      });

      HapticFeedback.selectionClick();
      _showOverlay(letter);
      widget.onLetterSelected(letter);
    }
  }

  void _onTapLetter(String letter) {
    final isAvailable =
        widget.availableLetters.isEmpty ||
        widget.availableLetters.contains(letter);

    if (!isAvailable) return;

    HapticFeedback.selectionClick();
    widget.onLetterSelected(letter);

    setState(() {
      _dragLetter = letter;
    });

    _showOverlay(letter);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _removeOverlay();
        setState(() {
          _dragLetter = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? const Color(0xFFBB86FC);
    final inactiveColor = widget.inactiveColor ?? Colors.grey[600]!;

    final highlightedLetter = _dragLetter ?? widget.currentLetter;

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Container(
        key: _scrollbarKey,
        width: 24,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _isDragging
              ? Colors.grey[900]?.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widget.alphabet.map((letter) {
            final isAvailable =
                widget.availableLetters.isEmpty ||
                widget.availableLetters.contains(letter);
            final isHighlighted = highlightedLetter == letter;

            return Expanded(
              child: GestureDetector(
                onTap: () => _onTapLetter(letter),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: isHighlighted
                          ? activeColor
                          : isAvailable
                          ? inactiveColor
                          : inactiveColor.withOpacity(0.3),
                      fontSize: isHighlighted ? 12 : 10,
                      fontWeight: isHighlighted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
