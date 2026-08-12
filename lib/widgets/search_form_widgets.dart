import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/search_params.dart';
import 'package:crgtransp72app/widgets/async_list_placeholder.dart';
import 'package:flutter/material.dart';

/// Заголовок поля в стиле SearchForm.
class SearchFieldLabel extends StatelessWidget {
  final String text;

  const SearchFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(top: 15),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black38,
          fontSize: 16,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

/// Обёртка dropdown / input в стиле приложения.
class SearchFieldBox extends StatelessWidget {
  final Widget child;
  final double? height;

  const SearchFieldBox({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black38, width: 2),
        color: grayprprColor,
      ),
      child: child,
    );
  }
}

const TextStyle kSearchFieldTextStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: Colors.black38,
  fontSize: 16,
);

/// Строка текстового поиска.
class SearchQueryField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const SearchQueryField({
    super.key,
    required this.controller,
    this.hint = 'Например: тюмень газель, экскаватор',
  });

  @override
  State<SearchQueryField> createState() => _SearchQueryFieldState();
}

class _SearchQueryFieldState extends State<SearchQueryField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SearchFieldBox(
      child: TextField(
        controller: widget.controller,
        style: kSearchFieldTextStyle,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: kSearchFieldTextStyle.copyWith(color: Colors.black26),
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: blueaccentColor),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black38),
                  onPressed: () => widget.controller.clear(),
                )
              : null,
        ),
      ),
    );
  }
}

/// Dropdown города / услуги с placeholder загрузки.
class SearchDropdownField<T> extends StatelessWidget {
  final bool isLoading;
  final bool loadFailed;
  final bool isEmpty;
  final VoidCallback onRetry;
  final String failedMessage;
  final String emptyMessage;
  final String hint;
  final T? value;
  final ValueChanged<T?> onChanged;
  final List<DropdownMenuItem<T>> items;

  const SearchDropdownField({
    super.key,
    required this.isLoading,
    required this.loadFailed,
    required this.isEmpty,
    required this.onRetry,
    required this.failedMessage,
    this.emptyMessage = 'Нет данных',
    required this.hint,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SearchFieldBox(
      height: 60,
      child: AsyncListPlaceholder(
        isLoading: isLoading,
        loadFailed: loadFailed,
        isEmpty: isEmpty,
        onRetry: onRetry,
        failedMessage: failedMessage,
        emptyMessage: emptyMessage,
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(hint, style: kSearchFieldTextStyle),
          dropdownColor: grayprprColor,
          value: value,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

/// Панель сортировки (чипы).
class SearchSortChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const SearchSortChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сортировка',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black38,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kSearchSortOptions.map((opt) {
                final active = selected == opt.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(opt.label),
                    selected: active,
                    selectedColor: blueaccentColor.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: active ? blueaccentColor : Colors.black54,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => onSelected(opt.value),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Тогл «Рядом со мной» + чипы радиуса.
class SearchNearMePanel extends StatelessWidget {
  final bool enabled;
  final int radiusKm;
  final bool loading;
  final String? statusText;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onRadiusChanged;

  const SearchNearMePanel({
    super.key,
    required this.enabled,
    required this.radiusKm,
    required this.onEnabledChanged,
    required this.onRadiusChanged,
    this.loading = false,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Рядом со мной',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              statusText ??
                  (enabled
                      ? 'Поиск по радиусу от вашей геопозиции'
                      : 'Включите, чтобы искать без выбора города'),
              style: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
            value: enabled,
            activeColor: blueaccentColor,
            onChanged: loading ? null : onEnabledChanged,
            secondary: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.near_me, color: blueaccentColor),
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            const Text(
              'Радиус, км',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black38,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kSearchRadiusOptions.map((km) {
                  final active = radiusKm == km;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$km'),
                      selected: active,
                      selectedColor: blueaccentColor.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: active ? blueaccentColor : Colors.black54,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: loading ? null : (_) => onRadiusChanged(km),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Кнопка «Найти» в стиле приложения.
class SearchPrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const SearchPrimaryButton({
    super.key,
    required this.onPressed,
    this.label = 'Найти',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            fixedSize: const Size(double.infinity, 50),
            foregroundColor: whiteprColor,
            backgroundColor: blueaccentColor,
            disabledForegroundColor: grayprprColor,
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

/// Раскрывающаяся панель дополнительных фильтров.
class SearchFiltersExpansion extends StatelessWidget {
  final List<Widget> children;

  const SearchFiltersExpansion({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        title: const Text(
          'Дополнительные фильтры',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: blueaccentColor,
            fontSize: 15,
          ),
        ),
        children: children,
      ),
    );
  }
}

/// Инфо-баннер на экране поиска.
class SearchInfoBanner extends StatelessWidget {
  final String text;

  const SearchInfoBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blueaccentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: blueaccentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: blueaccentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Подпись услуги со счётчиком; зелёный цвет при count > 0.
class SearchServiceCountLabel extends StatelessWidget {
  final String name;
  final int count;

  const SearchServiceCountLabel({
    super.key,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = count > 0 ? Colors.green.shade700 : Colors.black38;
    return Text(
      '$name ($count)',
      style: kSearchFieldTextStyle.copyWith(
        color: color,
        fontWeight: count > 0 ? FontWeight.w700 : FontWeight.bold,
      ),
    );
  }
}
