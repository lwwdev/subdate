import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../brand/brand_catalog.dart';
import '../data/providers.dart';
import '../format.dart';
import '../logic/renewals.dart';
import '../models/category.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'brand_picker.dart';
import 'service_icon.dart';

Future<void> showEditSheet(BuildContext context, {Subscription? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EditSubscriptionSheet(existing: existing),
  );
}

class EditSubscriptionSheet extends ConsumerStatefulWidget {
  final Subscription? existing;
  const EditSubscriptionSheet({super.key, this.existing});

  @override
  ConsumerState<EditSubscriptionSheet> createState() => _EditSubscriptionSheetState();
}

class _EditSubscriptionSheetState extends ConsumerState<EditSubscriptionSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late String _currency;
  late Cadence _cadence;
  late int _every;
  late DateTime _date;
  late int _remind;
  late bool _trial;
  late bool _paused;
  late int _people;
  DateTime? _endsOn;
  String? _brandKey;
  String? _category;
  Uint8List? _image;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final settings = ref.read(settingsProvider);
    _name = TextEditingController(text: e?.name ?? '');
    _amount = TextEditingController(text: e == null ? '' : e.amount.toStringAsFixed(2));
    _notes = TextEditingController(text: e?.notes ?? '');
    _currency = e?.currency ?? settings.homeCurrency;
    _cadence = e?.cadence ?? Cadence.monthly;
    _every = e?.every ?? 1;
    // for existing ones show the next renewal, nicer than some date from 2019
    _date = e == null ? dateOnly(DateTime.now()) : nextRenewal(e, DateTime.now());
    _remind = e?.remindDaysBefore ?? settings.defaultRemind;
    _trial = e?.trial ?? false;
    _paused = e?.paused ?? false;
    _people = e?.people ?? 1;
    _endsOn = e?.endsOn;
    _brandKey = e?.brandKey;
    _category = e?.category;
    _image = e?.customImage;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Subscription get _draft => Subscription(
    id: widget.existing?.id ?? 'draft',
    name: _name.text.trim(),
    amount: double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0,
    currency: _currency,
    cadence: _cadence,
    every: _every,
    startDate: _startDate(),
    brandKey: _brandKey,
    customImage: _image,
    color: widget.existing?.color ?? Colors.primaries[_name.text.length % Colors.primaries.length].toARGB32(),
    remindDaysBefore: _remind,
    trial: _trial,
    paused: _paused,
    notes: _notes.text.trim(),
    category: _category,
    people: _people,
    endsOn: _endsOn,
  );

  // keep the original start date if the user didnt actually move the date,
  // otherwise past months on the calendar would lose their icons
  DateTime _startDate() {
    final e = widget.existing;
    if (e != null && e.cadence == _cadence && e.every == _every && nextRenewal(e, DateTime.now()) == _date) {
      return e.startDate;
    }
    return _date;
  }

  Future<void> _pickBrand() async {
    final b = await pickBrand(context);
    if (b == null) return;
    setState(() {
      _brandKey = b.key;
      _image = null;
      if (_name.text.trim().isEmpty || brands.any((x) => x.name == _name.text)) _name.text = b.name;
      if (_amount.text.isEmpty && b.price != null) {
        _amount.text = b.price!.toStringAsFixed(2);
        _currency = b.currency;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 256, maxHeight: 256);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        _image = bytes;
        _brandKey = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("couldn't load that image")));
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final d = _draft;
    if (d.name.isEmpty) return setState(() => _error = 'needs a name');
    if (d.amount <= 0) return setState(() => _error = 'amount looks wrong');
    final s = _isNew
        ? Subscription(
            id: const Uuid().v4(),
            name: d.name,
            amount: d.amount,
            currency: d.currency,
            cadence: d.cadence,
            every: d.every,
            startDate: d.startDate,
            brandKey: d.brandKey,
            customImage: d.customImage,
            color: d.color,
            remindDaysBefore: d.remindDaysBefore,
            trial: d.trial,
            notes: d.notes,
            category: d.category,
            people: d.people,
            endsOn: d.endsOn,
          )
        : d;
    await ref.read(subsProvider.notifier).save(s);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${widget.existing!.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final gone = widget.existing!;
    final subs = ref.read(subsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    await subs.remove(gone.id);
    if (mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text('${gone.name} deleted'),
      action: SnackBarAction(label: 'Undo', onPressed: () => subs.save(gone)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currencies = {...ref.watch(fxProvider).currencies, _currency}.toList()..sort();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? 'New subscription' : 'Edit subscription',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(onTap: _pickBrand, child: ServiceIcon(_draft, size: 64)),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickBrand,
                        icon: const Icon(Icons.apps_rounded, size: 18),
                        label: const Text('Pick service'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Image'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: [for (final c in currencies) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final c in Cadence.values)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: _cadence == c,
                    onSelected: (_) => setState(() => _cadence = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Every', style: TextStyle(color: AppColors.muted)),
                IconButton(
                  onPressed: _every > 1 ? () => setState(() => _every--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_every', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: _every < 24 ? () => setState(() => _every++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Text(_unit(), style: const TextStyle(color: AppColors.muted)),
              ],
            ),
            Row(
              children: [
                const Text('Split between', style: TextStyle(color: AppColors.muted)),
                IconButton(
                  tooltip: 'Fewer people',
                  onPressed: _people > 1 ? () => setState(() => _people--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_people', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  tooltip: 'More people',
                  onPressed: _people < 20 ? () => setState(() => _people++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Expanded(
                  child: Text(
                    _people == 1 ? 'just me' : 'you pay ${money(_draft.share, _currency)}',
                    style: const TextStyle(color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // only stored once the user picks one, otherwise it follows the brand
            DropdownButtonFormField<Category>(
              key: ValueKey(categoryOf(_draft)),
              initialValue: categoryOf(_draft),
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in Category.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(c.label),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v!.name),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Free trial'),
              subtitle: const Text('first charge is when the trial ends', style: TextStyle(color: AppColors.muted)),
              value: _trial,
              onChanged: (v) => setState(() => _trial = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_trial ? 'Trial ends' : 'Next payment'),
              subtitle: Text(longDate(_date)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            if (ref.read(notificationsProvider).supported)
              DropdownButtonFormField<int>(
                initialValue: remindOptions.containsKey(_remind) ? _remind : 1,
                decoration: const InputDecoration(labelText: 'Remind me'),
                items: [for (final e in remindOptions.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _remind = v!),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Notes', hintText: 'which card, family plan, etc'),
            ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Paused'),
                subtitle: const Text('hides it everywhere without deleting', style: TextStyle(color: AppColors.muted)),
                value: _paused,
                onChanged: (v) => setState(() => _paused = v),
              ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cancelled'),
                subtitle: const Text('still runs until the date below, then stops', style: TextStyle(color: AppColors.muted)),
                value: _endsOn != null,
                onChanged: (v) => setState(() => _endsOn = v ? _date : null),
              ),
            if (!_isNew && _endsOn != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Runs until'),
                subtitle: Text(longDate(_endsOn!)),
                trailing: const Icon(Icons.event_busy_rounded),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _endsOn!,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _endsOn = d);
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(_isNew ? 'Add' : 'Save'),
            ),
            if (!_isNew) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _delete,
                child: const Text('Delete', style: TextStyle(color: AppColors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _unit() {
    final base = switch (_cadence) {
      Cadence.weekly => 'week',
      Cadence.monthly => 'month',
      Cadence.quarterly => 'quarter',
      Cadence.yearly => 'year',
    };
    return _every == 1 ? base : '${base}s';
  }
}
