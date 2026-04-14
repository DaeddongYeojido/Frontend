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
  final _nameCtrl      = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _openHoursCtrl = TextEditingController();
  final _memoCtrl      = TextEditingController();

  double? _lat;
  double? _lng;

  String? _openStatus;
  bool?   _isDisabled;
  bool?   _isGenderSep;
  File?   _image;

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

  /// 지도 페이지를 열고 결과(LatLng)를 받아옴
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerPage(
          initial: _lat != null && _lng != null
              ? LatLng(_lat!, _lng!)
              : null,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도에서 위치를 선택해주세요.')),
      );
      return;
    }

    final error = await ref.read(reportNotifierProvider.notifier).submit(
      name:        _nameCtrl.text.trim(),
      address:     _addressCtrl.text.trim(),
      lat:         _lat!,
      lng:         _lng!,
      openStatus:  _openStatus,
      isDisabled:  _isDisabled,
      isGenderSep: _isGenderSep,
      openHours:   _openHoursCtrl.text.trim().isEmpty
          ? null : _openHoursCtrl.text.trim(),
      memo:        _memoCtrl.text.trim().isEmpty
          ? null : _memoCtrl.text.trim(),
      image:       _image,
    );

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제보가 등록되었습니다. 검토 후 반영될 예정이에요.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.closed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(reportNotifierProvider);
    final hasPin = _lat != null && _lng != null;

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
            // ── 기본 정보 ──────────────────────────────────────────────
            _SectionHeader(label: '기본 정보', required: true),
            const SizedBox(height: 10),
            _Field(controller: _nameCtrl, label: '화장실 이름',
                hint: '예: 홍대입구역 공중화장실', required: true),
            const SizedBox(height: 10),
            _Field(controller: _addressCtrl, label: '주소',
                hint: '예: 서울특별시 마포구 양화로 160', required: true),

            // ── 위치 설정 ──────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: '위치 설정 (지도에서 핀 찍기)', required: true),
            const SizedBox(height: 8),

            // 지도 열기 버튼
            GestureDetector(
              onTap: _openMapPicker,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPin ? AppColors.primary : AppColors.filterBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      hasPin ? Icons.location_on : Icons.map_outlined,
                      color: hasPin ? AppColors.primary : AppColors.textHint,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: hasPin
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '위치 선택 완료',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                          : const Text(
                        '지도에서 위치를 골라 핀을 찍어주세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: hasPin ? AppColors.primary : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            // ── 운영 정보 ──────────────────────────────────────────────
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
              labels:  const ['운영중', '야간운영', '폐쇄'],
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

            // ── 메모 ───────────────────────────────────────────────────
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

            // ── 사진 첨부 ──────────────────────────────────────────────
            const SizedBox(height: 12),
            _SectionHeader(label: '사진 첨부', required: false),
            const SizedBox(height: 10),
            _ImagePicker(
              image: _image,
              onPick: _pickImage,
              onRemove: () => setState(() => _image = null),
            ),

            // ── 제출 버튼 ──────────────────────────────────────────────
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

// ── 전체화면 지도 핀 찍기 페이지 ──────────────────────────────────────────────

class _MapPickerPage extends StatefulWidget {
  final LatLng? initial;
  const _MapPickerPage({this.initial});

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  static const _defaultPosition = LatLng(37.5665, 126.9780);

  GoogleMapController? _ctrl;
  LatLng? _selected;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _selected = widget.initial;
      _marker = _buildMarker(widget.initial!);
    }
  }

  Marker _buildMarker(LatLng pos) => Marker(
    markerId: const MarkerId('pin'),
    position: pos,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
  );

  void _onTap(LatLng pos) {
    setState(() {
      _selected = pos;
      _marker = _buildMarker(pos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = _selected != null;

    return Scaffold(
      body: Stack(
        children: [
          // ── 전체화면 지도 ────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initial ?? _defaultPosition,
              zoom: 15,
            ),
            onMapCreated: (ctrl) => _ctrl = ctrl,
            onTap: _onTap,
            markers: _marker != null ? {_marker!} : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // ── 상단 바 ──────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    // 닫기 버튼
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 좌표 표시 바
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          hasPin
                              ? '${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}'
                              : '지도를 탭하여 위치를 선택하세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasPin
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight: hasPin
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 하단 확인 버튼 ───────────────────────────────────────────
          Positioned(
            left: 16, right: 16, bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: hasPin
                        ? () => Navigator.pop(context, _selected)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      hasPin ? '이 위치로 선택' : '위치를 먼저 선택해주세요',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
