import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

const double _kEnrollmentFee = 200;
const _kPaymentMethods = ['Cash', 'UPI', 'Card', 'Razorpay', 'Bank Transfer'];

/// Opens the full-screen member add/edit form. Returns true if saved.
Future<bool?> showMemberForm(BuildContext context,
    {Member? existing, String? suggestedCode}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          _MemberForm(existing: existing, suggestedCode: suggestedCode),
    ),
  );
}

class _MemberForm extends StatefulWidget {
  final Member? existing;
  final String? suggestedCode;
  const _MemberForm({this.existing, this.suggestedCode});

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  // controllers
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _seat = TextEditingController();
  final _paid = TextEditingController();
  final _discount = TextEditingController();
  final _email = TextEditingController();
  final _homePhone = TextEditingController();
  final _father = TextEditingController();
  final _uniqueId = TextEditingController();
  final _institute = TextEditingController();
  final _course = TextEditingController();
  final _remark = TextEditingController();
  final _batchStart = TextEditingController();
  final _batchEnd = TextEditingController();

  // state
  String _gender = 'male';
  bool _isVip = false;
  MemberStatus _status = MemberStatus.active;
  String? _plan;
  double _planFee = 0;
  String? _paymentMethod;
  String _discountType = 'flat'; // flat | percent
  final Set<String> _selectedTaxIds = {};
  DateTime _startDate = DateTime.now();
  DateTime _billDate = DateTime.now();
  DateTime? _dueReminder;
  DateTime? _dob;
  DateTime? _marriage;

  List<Shift> _plans = [];
  List<Tax> _taxes = [];
  bool _saving = false;
  bool _otherOpen = false;
  String? _photoUrl;
  final List<String> _documents = [];
  bool _uploadingPhoto = false;
  bool _uploadingDoc = false;
  final _picker = ImagePicker();

  bool get _isEdit => widget.existing != null;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code.text = e?.memberCode ?? widget.suggestedCode ?? '';
    _name.text = e?.name ?? '';
    _address.text = e?.address ?? '';
    _phone.text = e?.phone.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    _seat.text = e?.seatNo ?? '';
    _email.text = e?.email ?? '';
    _homePhone.text = e?.homePhone ?? '';
    _father.text = e?.fatherName ?? '';
    _uniqueId.text = e?.uniqueId ?? '';
    _institute.text = e?.institute ?? '';
    _course.text = e?.course ?? '';
    _remark.text = e?.remark ?? '';
    _batchStart.text = e?.batchStart ?? '';
    _batchEnd.text = e?.batchEnd ?? '';
    _gender = e?.gender ?? 'male';
    _isVip = e?.isVip ?? false;
    _status = e?.status ?? MemberStatus.active;
    _plan = e?.plan;
    _paymentMethod = e?.paymentMethod;
    _startDate = e?.startDate ?? DateTime.now();
    _billDate = e?.billDate ?? DateTime.now();
    _dueReminder = e?.dueReminder;
    _dob = e?.dob;
    _marriage = e?.marriageAnniversary;
    _photoUrl = e?.photoUrl;
    if (e != null) _documents.addAll(e.documents);
    _load();
  }

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 1000);
    if (x == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url =
          await Repo.instance.uploadMedia(File(x.path), folder: 'photos');
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      _snack('Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickDocuments() async {
    final files = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1600);
    if (files.isEmpty) return;
    setState(() => _uploadingDoc = true);
    try {
      for (final x in files) {
        final url =
            await Repo.instance.uploadMedia(File(x.path), folder: 'docs');
        if (url != null) _documents.add(url);
      }
    } catch (e) {
      _snack('Document upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
  }

  Future<void> _load() async {
    final results = await Future.wait([
      Repo.instance.shifts(),
      Repo.instance.taxes(),
    ]);
    if (!mounted) return;
    setState(() {
      _plans = results[0] as List<Shift>;
      _taxes = results[1] as List<Tax>;
      if (_plan != null) {
        final m = _plans.where((p) => p.name == _plan);
        if (m.isNotEmpty) _planFee = m.first.fee;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _code, _name, _address, _phone, _seat, _paid, _discount, _email,
      _homePhone, _father, _uniqueId, _institute, _course, _remark,
      _batchStart, _batchEnd
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- computed totals ---------------------------------------------------
  DateTime get _expiry =>
      DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
  double get _discountVal => double.tryParse(_discount.text.trim()) ?? 0;
  double get _discountAmount =>
      _discountType == 'percent' ? _planFee * _discountVal / 100 : _discountVal;
  double get _taxPct => _taxes
      .where((t) => _selectedTaxIds.contains(t.id))
      .fold<double>(0, (s, t) => s + t.percent);
  double get _taxable =>
      (_planFee + _kEnrollmentFee - _discountAmount).clamp(0, 1 << 31).toDouble();
  double get _taxAmount => _taxable * _taxPct / 100;
  double get _total => _taxable + _taxAmount;
  double get _paidVal => double.tryParse(_paid.text.trim()) ?? 0;
  double get _due => (_total - _paidVal).clamp(0, 1 << 31).toDouble();

  Future<void> _pickPlan() async {
    if (_plans.isEmpty) {
      _snack('No plans yet. Create them in Plans & Shifts first.');
      return;
    }
    final picked = await showSearchablePicker<Shift>(
      context,
      title: 'Select plan',
      items: _plans,
      label: (s) => s.name,
      subtitle: (s) => '${s.startTime} – ${s.endTime} • ${_rupee.format(s.fee)}',
      searchHint: 'Search plan',
    );
    if (picked != null) {
      setState(() {
        _plan = picked.name;
        _planFee = picked.fee;
        _paid.text = _total.toStringAsFixed(0); // default: full payment
      });
    }
  }

  Future<void> _pickMethod() async {
    final picked = await showSearchablePicker<String>(
      context,
      title: 'Payment method',
      items: _kPaymentMethods,
      label: (s) => s,
      searchHint: 'Search',
    );
    if (picked != null) setState(() => _paymentMethod = picked);
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime(2100),
      );

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('Please enter a name');
      return;
    }
    if (!_isVip && _plan == null) {
      _snack('Select a plan, or mark the member VIP');
      return;
    }
    setState(() => _saving = true);
    try {
      final phone = _phone.text.trim().isEmpty ? '' : '+91 ${_phone.text.trim()}';
      final base = Member(
        id: _isEdit
            ? widget.existing!.id
            : DateTime.now().microsecondsSinceEpoch.toString(),
        memberCode: _code.text.trim(),
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: phone,
        status: _status,
        photoUrl: _photoUrl,
        documents: _documents,
        seatNo: _seat.text.trim(),
        plan: _isVip ? null : _plan,
        joinedAt: _isEdit ? widget.existing!.joinedAt : DateTime.now(),
        expiresAt: _isVip ? null : _expiry,
        address: _address.text.trim(),
        gender: _gender,
        isVip: _isVip,
        startDate: _isVip ? null : _startDate,
        billDate: _billDate,
        paymentMethod: _paymentMethod,
        dueAmount: _isVip ? 0 : _due,
        dueReminder: _dueReminder,
        dob: _dob,
        homePhone: _homePhone.text.trim(),
        fatherName: _father.text.trim(),
        uniqueId: _uniqueId.text.trim(),
        institute: _institute.text.trim(),
        course: _course.text.trim(),
        marriageAnniversary: _marriage,
        batchStart: _batchStart.text.trim(),
        batchEnd: _batchEnd.text.trim(),
        remark: _remark.text.trim(),
      );

      if (_isEdit) {
        await Repo.instance.updateMember(base);
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final saved = await Repo.instance.addMember(base);

      // Auto-book seat for the chosen plan.
      final seatNo = int.tryParse(_seat.text.trim());
      if (seatNo != null && seatNo > 0 && _plan != null && !_isVip) {
        try {
          await Repo.instance.allotSeat(seatNo, _plan!, saved);
        } catch (_) {
          _snack('Member added, but seat $seatNo is already taken for $_plan.');
        }
      }

      // Record payments: what was paid (Paid) and any Due (Pending).
      if (!_isVip) {
        if (_paidVal > 0) {
          await Repo.instance.addPayment(Repo.instance.newPayment(
            member: saved,
            type: PaymentType.membership,
            amount: _paidVal,
            status: PaymentStatus.paid,
            method: (_paymentMethod ?? 'cash').toLowerCase(),
          ));
        }
        if (_due > 0) {
          await Repo.instance.addPayment(Repo.instance.newPayment(
            member: saved,
            type: PaymentType.membership,
            amount: _due,
            status: PaymentStatus.pending,
            method: (_paymentMethod ?? 'cash').toLowerCase(),
          ));
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Member' : 'Add Member'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.card,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : Text(_isEdit ? 'Save Changes' : 'Add Member'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _photoCard(),
          const SizedBox(height: 14),
          _basicCard(),
          const SizedBox(height: 14),
          _vipCard(),
          if (!_isVip) ...[
            const SizedBox(height: 14),
            _planCard(),
          ],
          const SizedBox(height: 14),
          _otherCard(),
        ],
      ),
    );
  }

  // ---- cards -------------------------------------------------------------
  Widget _card(String title, IconData icon, List<Widget> children,
      {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.rLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primary)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _photoCard() {
    final img = mediaImage(_photoUrl);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.rLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: img,
                child: img == null
                    ? Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 34)
                    : null,
              ),
              if (_uploadingPhoto)
                Positioned.fill(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Photo',
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickPhoto,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text(_photoUrl == null ? 'Choose Image' : 'Change'),
                ),
              ],
            ),
          ),
          if (_photoUrl != null)
            IconButton(
              onPressed: () => setState(() => _photoUrl = null),
              icon: const Icon(Icons.close_rounded, color: AppColors.inkFaint),
            ),
        ],
      ),
    );
  }

  Widget _documentsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Upload Documents',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.inkSoft)),
            const Spacer(),
            if (_uploadingDoc)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._documents.asMap().entries.map((e) {
              final url = e.value;
              final img = mediaImage(url);
              return Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppColors.rMd),
                      border: Border.all(color: AppColors.border),
                      image: img != null
                          ? DecorationImage(image: img, fit: BoxFit.cover)
                          : null,
                    ),
                    child: img == null
                        ? const Icon(Icons.description_rounded,
                            color: AppColors.inkFaint)
                        : null,
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => setState(() => _documents.removeAt(e.key)),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: AppColors.danger, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: _uploadingDoc ? null : _pickDocuments,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(AppColors.rMd),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.add_a_photo_rounded,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _basicCard() {
    return _card('Member Details', Icons.person_rounded, [
      _labeled('Member ID', _tf(_code, 'e.g. 1',
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly])),
      _labeled('Name', _tf(_name, 'Full name')),
      _labeled('Address', _tf(_address, 'Address')),
      const SizedBox(height: 4),
      Row(
        children: [
          _genderChip('Male', 'male', Icons.male_rounded),
          const SizedBox(width: 10),
          _genderChip('Female', 'female', Icons.female_rounded),
        ],
      ),
      const SizedBox(height: 12),
      _labeled(
        'Mobile',
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppColors.rMd)),
              child: Text('+91',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: _tf(_phone, 'Mobile',
                    keyboard: TextInputType.phone,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10)
                    ])),
          ],
        ),
      ),
      _labeled('Seat No (auto-books for the plan)', _tf(_seat, 'e.g. 12',
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly])),
    ]);
  }

  Widget _vipCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppColors.rLg),
      onTap: () => setState(() => _isVip = !_isVip),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.rLg),
          border: Border.all(
              color: _isVip ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(_isVip ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: _isVip ? AppColors.primary : AppColors.inkFaint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VIP Member',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('For VIP members no plan is required.',
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard() {
    return _card('Plan Details *', Icons.tune_rounded, [
      _labeled('Plan',
          PickerField(hint: 'Select Plan', value: _plan, onTap: _pickPlan)),
      _labeled('Plan Amount', _readonly(_rupee.format(_planFee))),
      _labeled('Start Date',
          _dateField(_startDate, (d) => setState(() => _startDate = d))),
      _labeled('Expiry Date', _readonly(DateFormat('yyyy-MM-dd').format(_expiry))),
      _labeled(
          'Payment Method',
          PickerField(
              hint: 'Select Payment Method',
              value: _paymentMethod,
              onTap: _pickMethod)),
      _labeled('Paid Amount', _tf(_paid, '0',
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}))),
      _labeled('Enrollment Fee', _readonly(_rupee.format(_kEnrollmentFee))),
      _labeled(
          'Discount Type',
          Row(
            children: [
              _segChip('Flat (₹)', 'flat'),
              const SizedBox(width: 10),
              _segChip('Percent (%)', 'percent'),
            ],
          )),
      _labeled('Discount', _tf(_discount, '0',
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}))),
      if (_taxes.isNotEmpty) ...[
        Text('Taxes Applicable',
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _taxes.map((t) {
            final sel = _selectedTaxIds.contains(t.id);
            return GestureDetector(
              onTap: () => setState(() {
                sel ? _selectedTaxIds.remove(t.id) : _selectedTaxIds.add(t.id);
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppColors.rMd),
                  border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                    '${t.name} ${t.percent.toStringAsFixed(t.percent % 1 == 0 ? 0 : 1)}%',
                    style: GoogleFonts.lexend(
                        color: sel ? Colors.white : AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
      // summary
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.circular(AppColors.rMd)),
        child: Column(
          children: [
            _sumRow('Total payable', _rupee.format(_total)),
            const SizedBox(height: 6),
            _sumRow('Due amount', _rupee.format(_due),
                highlight: _due > 0),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _labeled('Due Amount Reminder',
          _dateField(_dueReminder, (d) => setState(() => _dueReminder = d),
              hint: 'Set reminder date')),
      _labeled('Bill Date',
          _dateField(_billDate, (d) => setState(() => _billDate = d))),
    ]);
  }

  Widget _otherCard() {
    return _card(
      'Other Details',
      Icons.info_outline_rounded,
      _otherOpen
          ? [
              _labeled('Date Of Birth',
                  _dateField(_dob, (d) => setState(() => _dob = d),
                      hint: 'Date Of Birth')),
              _labeled('Email', _tf(_email, 'Email',
                  keyboard: TextInputType.emailAddress)),
              _labeled('Home Phone', _tf(_homePhone, 'Home Phone',
                  keyboard: TextInputType.phone)),
              _labeled('Father Name', _tf(_father, 'Father Name')),
              _labeled('Unique ID Number', _tf(_uniqueId, 'Unique ID Number')),
              _labeled('Institute', _tf(_institute, 'Institute')),
              _labeled('Course Pursuing', _tf(_course, 'Course Pursuing')),
              _labeled('Marriage Anniversary',
                  _dateField(_marriage, (d) => setState(() => _marriage = d),
                      hint: 'Marriage Anniversary')),
              Row(
                children: [
                  Expanded(
                      child: _labeled(
                          'Batch Start', _tf(_batchStart, 'e.g. 9:00 AM'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _labeled(
                          'Batch End', _tf(_batchEnd, 'e.g. 12:00 PM'))),
                ],
              ),
              _labeled('Remark', _tf(_remark, 'Remark')),
              _documentsField(),
            ]
          : [
              Text('Optional profile details (DOB, email, father name, '
                  'institute, course, batch timing, remark).',
                  style: GoogleFonts.lexend(
                      fontSize: 12.5, color: AppColors.inkSoft)),
            ],
      trailing: IconButton(
        icon: Icon(_otherOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: AppColors.primary),
        onPressed: () => setState(() => _otherOpen = !_otherOpen),
      ),
    );
  }

  // ---- small builders ----------------------------------------------------
  Widget _labeled(String label, Widget field) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            field,
          ],
        ),
      );

  Widget _tf(TextEditingController c, String hint,
      {TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      onChanged: onChanged,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _readonly(String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppColors.rMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(value,
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
      );

  Widget _dateField(DateTime? value, ValueChanged<DateTime> onPick,
      {String hint = 'Select date'}) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppColors.rMd),
      onTap: () async {
        final d = await _pickDate(value);
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppColors.rMd),
        ),
        child: Row(
          children: [
            Text(value != null ? DateFormat('yyyy-MM-dd').format(value) : hint,
                style: GoogleFonts.lexend(
                    fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                    color: value != null ? AppColors.ink : AppColors.inkFaint)),
            const Spacer(),
            Icon(Icons.calendar_month_rounded,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String label, String value, IconData icon) {
    final sel = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.rMd),
            border:
                Border.all(color: sel ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: sel ? Colors.white : AppColors.inkSoft),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.lexend(
                      color: sel ? Colors.white : AppColors.inkSoft,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segChip(String label, String value) {
    final sel = _discountType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discountType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.rMd),
            border:
                Border.all(color: sel ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: GoogleFonts.lexend(
                  color: sel ? Colors.white : AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _sumRow(String label, String value, {bool highlight = false}) => Row(
        children: [
          Text(label,
              style: GoogleFonts.lexend(
                  fontSize: 13, color: AppColors.inkSoft)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: highlight ? AppColors.danger : AppColors.ink)),
        ],
      );
}
