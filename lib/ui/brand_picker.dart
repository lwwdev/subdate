import 'package:flutter/material.dart';

import '../brand/brand_catalog.dart';
import '../models/subscription.dart';
import '../theme.dart';
import 'service_icon.dart';

Future<Brand?> pickBrand(BuildContext context) {
  return showModalBottomSheet<Brand>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _BrandPicker(),
  );
}

class _BrandPicker extends StatefulWidget {
  const _BrandPicker();

  @override
  State<_BrandPicker> createState() => _BrandPickerState();
}

class _BrandPickerState extends State<_BrandPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = brands.where((b) => b.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'search',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: list.isEmpty
                  ? const Center(
                      child: Text("not here, just type the name yourself",
                          style: TextStyle(color: AppColors.muted)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 96,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final b = list[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, b),
                          child: Column(
                            children: [
                              ServiceIcon(_preview(b), size: 56),
                              const SizedBox(height: 6),
                              Text(b.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// fake sub just so ServiceIcon can draw it
Subscription _preview(Brand b) => Subscription(
      id: b.key,
      name: b.name,
      amount: 0,
      currency: 'CAD',
      cadence: Cadence.monthly,
      startDate: DateTime(2000),
      brandKey: b.key,
    );
