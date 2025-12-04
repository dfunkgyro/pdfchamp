import 'package:flutter/material.dart';
import '../../core/theme/app_theme_constants.dart';

/// PDF editing and annotation tools widget
class PdfToolsWidget extends StatefulWidget {
  final bool isEditing;
  final Function(PdfTool)? onToolSelected;
  final Function(Color)? onColorSelected;
  final Function(double)? onThicknessChanged;

  const PdfToolsWidget({
    super.key,
    required this.isEditing,
    this.onToolSelected,
    this.onColorSelected,
    this.onThicknessChanged,
  });

  @override
  State<PdfToolsWidget> createState() => _PdfToolsWidgetState();
}

class _PdfToolsWidgetState extends State<PdfToolsWidget> {
  PdfTool _selectedTool = PdfTool.select;
  Color _selectedColor = AppColors.warning;
  double _thickness = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.isEditing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool Selection
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _buildToolButton(
                icon: Icons.pan_tool,
                tool: PdfTool.select,
                tooltip: 'Select',
              ),
              _buildToolButton(
                icon: Icons.highlight,
                tool: PdfTool.highlight,
                tooltip: 'Highlight',
              ),
              _buildToolButton(
                icon: Icons.comment,
                tool: PdfTool.comment,
                tooltip: 'Comment',
              ),
              _buildToolButton(
                icon: Icons.draw,
                tool: PdfTool.draw,
                tooltip: 'Draw',
              ),
              _buildToolButton(
                icon: Icons.text_fields,
                tool: PdfTool.text,
                tooltip: 'Add Text',
              ),
              _buildToolButton(
                icon: Icons.check_box_outline_blank,
                tool: PdfTool.shape,
                tooltip: 'Shapes',
              ),
              _buildToolButton(
                icon: Icons.crop,
                tool: PdfTool.redact,
                tooltip: 'Redact',
              ),
              _buildToolButton(
                icon: Icons.edit_note,
                tool: PdfTool.formFill,
                tooltip: 'Fill Form',
              ),
            ],
          ),

          const Divider(height: AppSpacing.md),

          // Color Picker
          if (_selectedTool != PdfTool.select) ...[
            Text(
              'Color',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _buildColorButton(AppColors.warning), // Yellow
                _buildColorButton(AppColors.accent), // Green
                _buildColorButton(AppColors.primary), // Blue
                _buildColorButton(AppColors.error), // Red
                _buildColorButton(AppColors.secondary), // Purple
                _buildColorButton(Colors.black),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Thickness Slider
          if (_selectedTool == PdfTool.draw ||
              _selectedTool == PdfTool.highlight) ...[
            Text(
              'Thickness',
              style: theme.textTheme.labelSmall,
            ),
            Slider(
              value: _thickness,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              label: _thickness.toStringAsFixed(0),
              onChanged: (value) {
                setState(() => _thickness = value);
                widget.onThicknessChanged?.call(value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required PdfTool tool,
    required String tooltip,
  }) {
    final isSelected = _selectedTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() => _selectedTool = tool);
          widget.onToolSelected?.call(tool);
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;

    return InkWell(
      onTap: () {
        setState(() => _selectedColor = color);
        widget.onColorSelected?.call(color);
      },
      borderRadius: BorderRadius.circular(AppRadius.circular),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

/// PDF editing tool types
enum PdfTool {
  select,
  highlight,
  comment,
  draw,
  text,
  shape,
  redact,
  formFill,
}
