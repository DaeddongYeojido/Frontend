import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/report_provider.dart';

class ReportWriteScreen extends ConsumerStatefulWidget {
  const ReportWriteScreen({super.key});

  @override
  ConsumerState<ReportWriteScreen> createState() => _ReportWriteScreenState();
}

class _ReportWriteScreenState extends ConsumerState<ReportWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openHoursCtrl = TextEditingController();
  final _memoCtrl    = TextEditingController();

  double? _lat;
  double? _lng;
  Marker? _pinMarker;

  String? _openStatus;
  bool? _isDisabled;
  bool? _isGenderSep;
  File? _image;

  bool _mapExpanded = false;
  GoogleMapController? _mapController;

  static const _initialPosition = LatLng(37.5665, 126.9780); // 서울 시청

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _openHoursCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  void _onMapTap(LatLng coord) {
    setState(() {
      _lat = coord.latitude;
      _lng = coord.longitude;
      _pinMarker = Marker(
        markerId: const MarkerId('pin'),
        position: coord,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(coord));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도에서 위치를 선택해주세요.')),
      );
      return;
    }

    final ok = await ref.read(reportNotifierProvider.notifier).submit(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          lat: _lat!,
          lng: _lng!,
          openStatus: _openStatus,
          isDisabled: _isDisabled,
          isGenderSep: _isGenderSep,
          openHours: _openHoursCtrl.text.trim().isEmpty
              ? null
              : _openHoursCtrl.text.trim(),
          memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
          image: _image,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제보가 등록되었습니다. 검토 후 반영될 예정이에요.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제보 등록에 실패했어요. 다시 시도해주세요.'),
          backgroundColor: AppColors.closed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(reportNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '화장실 제보하기',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // ── 기본 정보 ─────────────────────────────────────────────
            _SectionHeader(label: '기본 정보', required: true),
            const SizedBox(height: 10),
            _Field(controller: _nameCtrl, label: '화장실 이름',
                hint: '예: 홍대입구역 공중화장실', required: true),
            const SizedBox(height: 10),
            _Field(controller: _addressCtrl, label: '주소',
                hint: '예: 서울특별시 마포구 양화로 160', required: true),

            // ── 위치 설정 ─────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: '위치 설정 (지도에서 핀 찍기)', required: true),
            const SizedBox(height: 8),
            if (_lat != null && _lng != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            GestureDetector(
              onTap: () => setState(() => _mapExpanded = !_mapExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _mapExpanded ? 300 : 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _lat == null
                          ? AppColors.filterBorder
                          : AppColors.primary,
                      width: 1.5),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _initialPosition,
                        zoom: 14,
                      ),
                      onMapCreated: (ctrl) => _mapController = ctrl,
                      onTap: _onMapTap,
                      markers: _pinMarker != null ? {_pinMarker!} : {},
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                    if (!_mapExpanded)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.3),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app,
                                    color: AppColors.primary, size: 28),
                                SizedBox(height: 4),
                                Text('탭하여 지도 펼치기',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        backgroundColor: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_mapExpanded)
                      const Positioned(
                        top: 8, left: 0, right: 0,
                        child: Center(
                          child: Text('지도를 탭하여 위치 선택',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── 운영 정보 ─────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: '운영 정보', required: false),
            const SizedBox(height: 10),
            const Text('운영 상태',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            _ChoiceRow<String>(
              options: const ['OPEN', 'NIGHT', 'CLOSED'],
              labels: const ['운영중', '야간운영', '폐쇄'],
              selected: _openStatus,
              onSelect: (v) =>
                  setState(() => _openStatus = _openStatus == v ? null : v),
              activeColors: const [AppColors.open, AppColors.night, AppColors.closed],
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _ToggleChip(
                  icon: Icons.accessible,
                  label: '장애인 화장실',
                  value: _isDisabled,
                  onToggle: (v) => setState(() => _isDisabled = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleChip(
                  icon: Icons.wc,
                  label: '남녀 구분',
                  value: _isGenderSep,
                  onToggle: (v) => setState(() => _isGenderSep = v),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _Field(controller: _openHoursCtrl, label: '운영 시간',
                hint: '예: 06:00~22:00', required: false),

            // ── 메모 ──────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: '메모', required: false),
            const SizedBox(height: 10),
            TextFormField(
              controller: _memoCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: '추가 정보를 자유롭게 입력하세요.',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.filterBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.filterBorder)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            // ── 사진 첨부 ─────────────────────────────────────────────
            const SizedBox(height: 12),
            _SectionHeader(label: '사진 첨부', required: false),
            const SizedBox(height: 10),
            _ImagePicker(
              image: _image,
              onPick: _pickImage,
              onRemove: () => setState(() => _image = null),
            ),

            // ── 제출 ──────────────────────────────────────────────────
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: submitState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: submitState.isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('제보 등록하기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 재사용 위젯 ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool required;
  const _SectionHeader({required this.label, required this.required});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.closed, fontSize: 14)),
        ] else ...[
          const SizedBox(width: 6),
          const Text('(선택)', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ]);
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;
  const _Field({required this.controller, required this.label,
      required this.hint, required this.required});
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label을(를) 입력해주세요.' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.filterBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.filterBorder)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}

class _ChoiceRow<T> extends StatelessWidget {
  final List<T> options;
  final List<String> labels;
  final T? selected;
  final ValueChanged<T> onSelect;
  final List<Color> activeColors;
  const _ChoiceRow({required this.options, required this.labels,
      required this.selected, required this.onSelect, required this.activeColors});
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(options.length, (i) {
          final active = selected == options[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? activeColors[i].withOpacity(0.12) : Colors.white,
                  border: Border.all(
                      color: active ? activeColors[i] : AppColors.filterBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? activeColors[i] : AppColors.textSecondary)),
              ),
            ),
          );
        }),
      );
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? value;
  final ValueChanged<bool?> onToggle;
  const _ToggleChip({required this.icon, required this.label,
      required this.value, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final isOn = value == true;
    return GestureDetector(
      onTap: () {
        if (value == null) onToggle(true);
        else if (value == true) onToggle(false);
        else onToggle(null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isOn ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
              color: isOn ? AppColors.primary : AppColors.filterBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16,
              color: isOn ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOn ? AppColors.primary : AppColors.textSecondary)),
            Text(
              value == true ? '있음' : value == false ? '없음' : '미선택',
              style: TextStyle(
                  fontSize: 10,
                  color: value == true ? AppColors.primary : AppColors.textHint),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final File? image;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _ImagePicker({required this.image, required this.onPick, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(image!,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.filterBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 32, color: AppColors.textHint),
            SizedBox(height: 6),
            Text('사진 추가',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
