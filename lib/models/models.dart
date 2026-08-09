import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

// =====================================================================
// Member
// =====================================================================
enum MemberStatus { active, inactive, expired }

extension MemberStatusX on MemberStatus {
  String get label => switch (this) {
        MemberStatus.active => 'Active',
        MemberStatus.inactive => 'Inactive',
        MemberStatus.expired => 'Expired',
      };
  Color get color => switch (this) {
        MemberStatus.active => AppColors.success,
        MemberStatus.inactive => AppColors.inkSoft,
        MemberStatus.expired => AppColors.danger,
      };
  Color get bg => switch (this) {
        MemberStatus.active => AppColors.successBg,
        MemberStatus.inactive => AppColors.divider,
        MemberStatus.expired => AppColors.dangerBg,
      };
}

class Member {
  final String id;
  final String memberCode;
  final String name;
  final String email;
  final String phone;
  final MemberStatus status;
  final String? photoUrl;
  final List<String> documents;
  final String? seatNo;
  final String? plan; // membership plan name (from admin-made plans/shifts)
  final DateTime? joinedAt;
  final DateTime? expiresAt;
  // profile / basic
  final String? address;
  final String? gender; // male | female
  final bool isVip;
  // plan / billing
  final DateTime? startDate;
  final DateTime? billDate;
  final String? paymentMethod;
  final double dueAmount;
  final DateTime? dueReminder;
  // other (optional) details
  final DateTime? dob;
  final String? homePhone;
  final String? fatherName;
  final String? uniqueId;
  final String? institute;
  final String? course;
  final DateTime? marriageAnniversary;
  final String? batchStart;
  final String? batchEnd;
  final String? remark;

  const Member({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.photoUrl,
    this.documents = const [],
    this.seatNo,
    this.plan,
    this.joinedAt,
    this.expiresAt,
    this.address,
    this.gender,
    this.isVip = false,
    this.startDate,
    this.billDate,
    this.paymentMethod,
    this.dueAmount = 0,
    this.dueReminder,
    this.dob,
    this.homePhone,
    this.fatherName,
    this.uniqueId,
    this.institute,
    this.course,
    this.marriageAnniversary,
    this.batchStart,
    this.batchEnd,
    this.remark,
  });

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        id: m['id'].toString(),
        memberCode: m['member_code'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        status: MemberStatus.values.firstWhere(
          (e) => e.name == (m['status'] ?? 'active'),
          orElse: () => MemberStatus.active,
        ),
        photoUrl: m['photo_url'],
        documents: (m['documents'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        seatNo: m['seat_no'],
        plan: m['plan'],
        joinedAt: _date(m['joined_at']),
        expiresAt: _date(m['expires_at']),
        address: m['address'],
        gender: m['gender'],
        isVip: m['is_vip'] == true,
        startDate: _date(m['start_date']),
        billDate: _date(m['bill_date']),
        paymentMethod: m['payment_method'],
        dueAmount: (m['due_amount'] as num?)?.toDouble() ?? 0,
        dueReminder: _date(m['due_reminder']),
        dob: _date(m['dob']),
        homePhone: m['home_phone'],
        fatherName: m['father_name'],
        uniqueId: m['unique_id'],
        institute: m['institute'],
        course: m['course'],
        marriageAnniversary: _date(m['marriage_anniversary']),
        batchStart: m['batch_start'],
        batchEnd: m['batch_end'],
        remark: m['remark'],
      );

  Map<String, dynamic> toMap() => {
        'member_code': memberCode,
        'name': name,
        'email': email,
        'phone': phone,
        'status': status.name,
        'photo_url': photoUrl,
        'documents': documents,
        'seat_no': seatNo,
        'plan': plan,
        'joined_at': joinedAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'address': address,
        'gender': gender,
        'is_vip': isVip,
        'start_date': startDate?.toIso8601String(),
        'bill_date': billDate?.toIso8601String(),
        'payment_method': paymentMethod,
        'due_amount': dueAmount,
        'due_reminder': dueReminder?.toIso8601String(),
        'dob': dob?.toIso8601String(),
        'home_phone': homePhone,
        'father_name': fatherName,
        'unique_id': uniqueId,
        'institute': institute,
        'course': course,
        'marriage_anniversary': marriageAnniversary?.toIso8601String(),
        'batch_start': batchStart,
        'batch_end': batchEnd,
        'remark': remark,
      };

  Member copyWith({
    String? memberCode,
    String? name,
    String? email,
    String? phone,
    MemberStatus? status,
    String? photoUrl,
    List<String>? documents,
    String? seatNo,
    String? plan,
    DateTime? joinedAt,
    DateTime? expiresAt,
    String? address,
    String? gender,
    bool? isVip,
    DateTime? startDate,
    DateTime? billDate,
    String? paymentMethod,
    double? dueAmount,
    DateTime? dueReminder,
    DateTime? dob,
    String? homePhone,
    String? fatherName,
    String? uniqueId,
    String? institute,
    String? course,
    DateTime? marriageAnniversary,
    String? batchStart,
    String? batchEnd,
    String? remark,
  }) =>
      Member(
        id: id,
        memberCode: memberCode ?? this.memberCode,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        status: status ?? this.status,
        photoUrl: photoUrl ?? this.photoUrl,
        documents: documents ?? this.documents,
        seatNo: seatNo ?? this.seatNo,
        plan: plan ?? this.plan,
        joinedAt: joinedAt ?? this.joinedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        address: address ?? this.address,
        gender: gender ?? this.gender,
        isVip: isVip ?? this.isVip,
        startDate: startDate ?? this.startDate,
        billDate: billDate ?? this.billDate,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        dueAmount: dueAmount ?? this.dueAmount,
        dueReminder: dueReminder ?? this.dueReminder,
        dob: dob ?? this.dob,
        homePhone: homePhone ?? this.homePhone,
        fatherName: fatherName ?? this.fatherName,
        uniqueId: uniqueId ?? this.uniqueId,
        institute: institute ?? this.institute,
        course: course ?? this.course,
        marriageAnniversary: marriageAnniversary ?? this.marriageAnniversary,
        batchStart: batchStart ?? this.batchStart,
        batchEnd: batchEnd ?? this.batchEnd,
        remark: remark ?? this.remark,
      );
}

// =====================================================================
// Book
// =====================================================================
enum BookStatus { available, issued, reserved }

class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final int totalCopies;
  final int availableCopies;
  final String? coverUrl;
  final Color accent;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.category = 'General',
    required this.totalCopies,
    required this.availableCopies,
    this.coverUrl,
    this.accent = AppColors.info,
  });

  BookStatus get status =>
      availableCopies == 0 ? BookStatus.issued : BookStatus.available;

  factory Book.fromMap(Map<String, dynamic> m) => Book(
        id: m['id'].toString(),
        title: m['title'] ?? '',
        author: m['author'] ?? '',
        isbn: m['isbn'] ?? '',
        category: m['category'] ?? 'General',
        totalCopies: (m['total_copies'] ?? 1) as int,
        availableCopies: (m['available_copies'] ?? 0) as int,
        coverUrl: m['cover_url'],
        accent:
            m['accent'] != null ? Color(m['accent'] as int) : AppColors.info,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'isbn': isbn,
        'category': category,
        'total_copies': totalCopies,
        'available_copies': availableCopies,
        'cover_url': coverUrl,
        'accent': accent.toARGB32(),
      };

  Book copyWith({
    String? title,
    String? author,
    String? isbn,
    String? category,
    int? totalCopies,
    int? availableCopies,
    Color? accent,
  }) =>
      Book(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        isbn: isbn ?? this.isbn,
        category: category ?? this.category,
        totalCopies: totalCopies ?? this.totalCopies,
        availableCopies: availableCopies ?? this.availableCopies,
        coverUrl: coverUrl,
        accent: accent ?? this.accent,
      );
}

// =====================================================================
// Transaction (issue / return)
// =====================================================================
class Transaction {
  final String id;
  final String? bookId;
  final String? memberId;
  final String bookTitle;
  final String memberName;
  final bool isReturn; // true = returned, false = issued
  final DateTime time;
  final DateTime? dueAt;

  const Transaction({
    required this.id,
    this.bookId,
    this.memberId,
    required this.bookTitle,
    required this.memberName,
    required this.isReturn,
    required this.time,
    this.dueAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
        id: m['id'].toString(),
        bookId: m['book_id']?.toString(),
        memberId: m['member_id']?.toString(),
        bookTitle: m['book_title'] ?? '',
        memberName: m['member_name'] ?? '',
        isReturn: (m['type'] ?? 'issue') == 'return',
        time: _date(m['created_at']) ?? DateTime.now(),
        dueAt: _date(m['due_at']),
      );

  Map<String, dynamic> toMap() => {
        'book_id': bookId,
        'member_id': memberId,
        'book_title': bookTitle,
        'member_name': memberName,
        'type': isReturn ? 'return' : 'issue',
        'due_at': dueAt?.toIso8601String(),
      };
}

/// A currently-outstanding book loan (an issue with no matching return yet).
class Loan {
  final String bookId;
  final String bookTitle;
  final String memberId;
  final String memberName;
  final DateTime issuedAt;
  final DateTime? dueAt;

  const Loan({
    required this.bookId,
    required this.bookTitle,
    required this.memberId,
    required this.memberName,
    required this.issuedAt,
    this.dueAt,
  });

  bool get isOverdue =>
      dueAt != null && dueAt!.isBefore(DateTime.now());
  int get daysOverdue =>
      dueAt == null ? 0 : DateTime.now().difference(dueAt!).inDays;
}

// =====================================================================
// Payment
// =====================================================================
enum PaymentType { membership, fine }

enum PaymentStatus { paid, pending, overdue }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.paid => 'Paid',
        PaymentStatus.pending => 'Pending',
        PaymentStatus.overdue => 'Overdue',
      };
  Color get color => switch (this) {
        PaymentStatus.paid => AppColors.success,
        PaymentStatus.pending => AppColors.warning,
        PaymentStatus.overdue => AppColors.danger,
      };
  Color get bg => switch (this) {
        PaymentStatus.paid => AppColors.successBg,
        PaymentStatus.pending => AppColors.warningBg,
        PaymentStatus.overdue => AppColors.dangerBg,
      };
}

class Payment {
  final String id;
  final String? memberId;
  final String memberName;
  final String memberCode;
  final PaymentType type;
  final double amount;
  final PaymentStatus status;
  final String method; // cash | razorpay
  final DateTime date;
  final String? photoUrl;

  const Payment({
    required this.id,
    this.memberId,
    required this.memberName,
    required this.memberCode,
    required this.type,
    required this.amount,
    required this.status,
    this.method = 'cash',
    required this.date,
    this.photoUrl,
  });

  String get typeLabel =>
      type == PaymentType.membership ? 'Membership Fee' : 'Fine';

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'].toString(),
        memberId: m['member_id']?.toString(),
        memberName: m['member_name'] ?? '',
        memberCode: m['member_code'] ?? '',
        type: (m['type'] ?? 'membership') == 'fine'
            ? PaymentType.fine
            : PaymentType.membership,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == (m['status'] ?? 'paid'),
          orElse: () => PaymentStatus.paid,
        ),
        method: m['method'] ?? 'cash',
        date: _date(m['paid_at']) ?? _date(m['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'member_id': memberId,
        'member_name': memberName,
        'member_code': memberCode,
        'type': type.name,
        'amount': amount,
        'status': status.name,
        'method': method,
        'paid_at':
            status == PaymentStatus.paid ? date.toIso8601String() : null,
      };
}

// =====================================================================
// Attendance
// =====================================================================
enum AttendanceState { present, absent, pending }

extension AttendanceStateX on AttendanceState {
  String get label => switch (this) {
        AttendanceState.present => 'Present',
        AttendanceState.absent => 'Absent',
        AttendanceState.pending => 'Pending',
      };
  Color get color => switch (this) {
        AttendanceState.present => AppColors.success,
        AttendanceState.absent => AppColors.danger,
        AttendanceState.pending => AppColors.warning,
      };
  Color get bg => switch (this) {
        AttendanceState.present => AppColors.successBg,
        AttendanceState.absent => AppColors.dangerBg,
        AttendanceState.pending => AppColors.warningBg,
      };
}

class AttendanceEntry {
  final String id;
  final String? memberId;
  final String memberName;
  final DateTime markedAt;
  final AttendanceState state;
  final String? photoUrl;

  const AttendanceEntry({
    required this.id,
    this.memberId,
    required this.memberName,
    required this.markedAt,
    required this.state,
    this.photoUrl,
  });

  String get time => DateFormat('h:mm a').format(markedAt);

  factory AttendanceEntry.fromMap(Map<String, dynamic> m) => AttendanceEntry(
        id: m['id'].toString(),
        memberId: m['member_id']?.toString(),
        memberName: m['member_name'] ?? '',
        markedAt: _date(m['marked_at']) ?? DateTime.now(),
        state: AttendanceState.values.firstWhere(
          (e) => e.name == (m['state'] ?? 'present'),
          orElse: () => AttendanceState.present,
        ),
      );

  Map<String, dynamic> toMap() => {
        'member_id': memberId,
        'member_name': memberName,
        'state': state.name,
        'marked_at': markedAt.toIso8601String(),
      };
}

// =====================================================================
// Library (tenant root / admin profile)
// =====================================================================
class Library {
  final String id;
  final String name;
  final String adminName;
  final String adminPhone;
  final String adminEmail;
  final int totalSeats;
  final String plan; // free | trial | starter | professional | business
  final DateTime? planExpiresAt;
  final String? referralCode;

  const Library({
    required this.id,
    required this.name,
    required this.adminName,
    required this.adminPhone,
    required this.adminEmail,
    this.totalSeats = 30,
    this.plan = 'free',
    this.planExpiresAt,
    this.referralCode,
  });

  bool get isPaid => plan != 'free' && plan != 'trial';

  factory Library.fromMap(Map<String, dynamic> m) => Library(
        id: m['id'].toString(),
        name: m['name'] ?? '',
        adminName: m['admin_name'] ?? '',
        adminPhone: m['admin_phone'] ?? '',
        adminEmail: m['admin_email'] ?? '',
        totalSeats: (m['total_seats'] ?? 30) as int,
        plan: m['plan'] ?? 'free',
        planExpiresAt: _date(m['plan_expires_at']),
        referralCode: m['referral_code'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'admin_name': adminName,
        'admin_phone': adminPhone,
        'admin_email': adminEmail,
        'total_seats': totalSeats,
        'plan': plan,
        'plan_expires_at': planExpiresAt?.toIso8601String(),
        'referral_code': referralCode,
      };

  Library copyWith(
          {String? name,
          String? adminName,
          String? adminEmail,
          int? totalSeats,
          String? plan,
          DateTime? planExpiresAt,
          String? referralCode}) =>
      Library(
        id: id,
        name: name ?? this.name,
        adminName: adminName ?? this.adminName,
        adminPhone: adminPhone,
        adminEmail: adminEmail ?? this.adminEmail,
        totalSeats: totalSeats ?? this.totalSeats,
        plan: plan ?? this.plan,
        planExpiresAt: planExpiresAt ?? this.planExpiresAt,
        referralCode: referralCode ?? this.referralCode,
      );
}

// =====================================================================
// Referral
// =====================================================================
class Referral {
  final String id;
  final String referrerCode;
  final String? referredLibraryId;
  final String referredName;
  final double reward;
  final String status; // pending | credited
  final DateTime createdAt;

  const Referral({
    required this.id,
    required this.referrerCode,
    this.referredLibraryId,
    required this.referredName,
    required this.reward,
    required this.status,
    required this.createdAt,
  });

  bool get isCredited => status == 'credited';

  factory Referral.fromMap(Map<String, dynamic> m) => Referral(
        id: m['id'].toString(),
        referrerCode: m['referrer_code'] ?? '',
        referredLibraryId: m['referred_library_id']?.toString(),
        referredName: m['referred_name'] ?? 'New library',
        reward: (m['reward'] as num?)?.toDouble() ?? 200,
        status: m['status'] ?? 'pending',
        createdAt: _date(m['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'referrer_code': referrerCode,
        'referred_library_id': referredLibraryId,
        'referred_name': referredName,
        'reward': reward,
        'status': status,
      };
}

// =====================================================================
// Subscription — billing cycles + plan tiers
// =====================================================================
class BillingCycle {
  final String id;
  final String label;
  final int months;
  final double discount; // 0..1, applied to (monthlyPrice * months)

  const BillingCycle(this.id, this.label, this.months, this.discount);

  static const List<BillingCycle> all = [
    BillingCycle('monthly', 'Monthly', 1, 0.0),
    BillingCycle('quarterly', 'Quarterly', 3, 0.05),
    BillingCycle('halfyearly', '6 Months', 6, 0.10),
    BillingCycle('yearly', '1 Year', 12, 0.15),
    BillingCycle('2year', '2 Years', 24, 0.20),
    BillingCycle('5year', '5 Years', 60, 0.30),
  ];

  static BillingCycle byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);
}

class SubPlan {
  final String id; // starter | professional | business
  final String name;
  final String tagline;
  final double monthlyPrice; // base per-month price
  final int seatLimit; // -1 = unlimited
  final List<String> features;
  final bool highlight;

  const SubPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.seatLimit,
    required this.features,
    this.highlight = false,
  });

  /// Total price to charge for [cycle] (after the cycle discount).
  double totalFor(BillingCycle cycle) =>
      (monthlyPrice * cycle.months) * (1 - cycle.discount);

  /// Effective per-month price for [cycle] (for the "₹X/mo" caption).
  double effectiveMonthly(BillingCycle cycle) =>
      cycle.months == 0 ? monthlyPrice : totalFor(cycle) / cycle.months;

  static const List<SubPlan> catalog = [
    SubPlan(
      id: 'starter',
      name: 'Starter',
      tagline: 'For a single small library',
      monthlyPrice: 299,
      seatLimit: 50,
      features: [
        'Up to 50 seats',
        'Members, Books & Attendance',
        'Seat & plan management',
        'Basic reports',
      ],
    ),
    SubPlan(
      id: 'professional',
      name: 'Professional',
      tagline: 'For growing libraries',
      monthlyPrice: 599,
      seatLimit: 150,
      features: [
        'Up to 150 seats',
        'Payments + Razorpay',
        'Collection, expense & tax reports',
        'Auto SMS reminders',
        'Enquiry management',
      ],
      highlight: true,
    ),
    SubPlan(
      id: 'business',
      name: 'Business Premier',
      tagline: 'Multi-branch & unlimited',
      monthlyPrice: 1199,
      seatLimit: -1,
      features: [
        'Unlimited seats',
        'Multiple branches',
        'All Professional features',
        'Priority support',
        'Early access to AI Assistant',
      ],
    ),
  ];

  static SubPlan byId(String id) =>
      catalog.firstWhere((p) => p.id == id, orElse: () => catalog.first);
}

// =====================================================================
// Shift (library timing slot with its own fee)
// =====================================================================
class Shift {
  final String id;
  final String name; // Morning, Afternoon, Evening, Night, Full Day
  final String startTime; // "06:00 AM"
  final String endTime; // "12:00 PM"
  final double fee;

  const Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.fee,
  });

  factory Shift.fromMap(Map<String, dynamic> m) => Shift(
        id: m['id'].toString(),
        name: m['name'] ?? '',
        startTime: m['start_time'] ?? '',
        endTime: m['end_time'] ?? '',
        fee: (m['fee'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
        'fee': fee,
      };

  Shift copyWith(
          {String? name, String? startTime, String? endTime, double? fee}) =>
      Shift(
        id: id,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        fee: fee ?? this.fee,
      );

  static List<Shift> defaults() => const [
        Shift(id: 's-morning', name: 'Morning', startTime: '06:00 AM', endTime: '12:00 PM', fee: 500),
        Shift(id: 's-afternoon', name: 'Afternoon', startTime: '12:00 PM', endTime: '04:00 PM', fee: 400),
        Shift(id: 's-evening', name: 'Evening', startTime: '04:00 PM', endTime: '08:00 PM', fee: 500),
        Shift(id: 's-night', name: 'Night', startTime: '08:00 PM', endTime: '11:00 PM', fee: 400),
        Shift(id: 's-fullday', name: 'Full Day', startTime: '06:00 AM', endTime: '11:00 PM', fee: 1000),
      ];
}

// =====================================================================
// Seat allotment (one member holds one seat in one shift)
// =====================================================================
/// Two seat bookings conflict when they can't share the same physical seat.
/// A "Full Day" booking occupies the seat for every slot, so it conflicts with
/// any shift (and itself). Two different timed shifts (e.g. Morning + Evening)
/// can share one seat, so they do NOT conflict.
bool seatShiftsConflict(String a, String b) {
  if (a == b) return true;
  const full = 'Full Day';
  return a == full || b == full;
}

class SeatAllotment {
  final String id;
  final int seatNo;
  final String shift;
  final String memberId;
  final String memberName;

  const SeatAllotment({
    required this.id,
    required this.seatNo,
    required this.shift,
    required this.memberId,
    required this.memberName,
  });

  factory SeatAllotment.fromMap(Map<String, dynamic> m) => SeatAllotment(
        id: m['id'].toString(),
        seatNo: (m['seat_no'] ?? 0) as int,
        shift: m['shift'] ?? '',
        memberId: m['member_id']?.toString() ?? '',
        memberName: m['member_name'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'seat_no': seatNo,
        'shift': shift,
        'member_id': memberId,
        'member_name': memberName,
      };
}

// =====================================================================
// Enquiry (walk-in lead)
// =====================================================================
enum EnquiryStatus { fresh, followUp, converted, closed }

extension EnquiryStatusX on EnquiryStatus {
  String get label => switch (this) {
        EnquiryStatus.fresh => 'New',
        EnquiryStatus.followUp => 'Follow Up',
        EnquiryStatus.converted => 'Converted',
        EnquiryStatus.closed => 'Closed',
      };
  Color get color => switch (this) {
        EnquiryStatus.fresh => AppColors.info,
        EnquiryStatus.followUp => AppColors.warning,
        EnquiryStatus.converted => AppColors.success,
        EnquiryStatus.closed => AppColors.inkSoft,
      };
  Color get bg => switch (this) {
        EnquiryStatus.fresh => AppColors.infoBg,
        EnquiryStatus.followUp => AppColors.warningBg,
        EnquiryStatus.converted => AppColors.successBg,
        EnquiryStatus.closed => AppColors.divider,
      };
}

class Enquiry {
  final String id;
  final String name;
  final String phone;
  final String note;
  final EnquiryStatus status;
  final DateTime createdAt;

  const Enquiry({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory Enquiry.fromMap(Map<String, dynamic> m) => Enquiry(
        id: m['id'].toString(),
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        note: m['note'] ?? '',
        status: EnquiryStatus.values.firstWhere(
          (e) => e.name == (m['status'] ?? 'fresh'),
          orElse: () => EnquiryStatus.fresh,
        ),
        createdAt: _date(m['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'note': note,
        'status': status.name,
      };

  Enquiry copyWith(
          {String? name, String? phone, String? note, EnquiryStatus? status}) =>
      Enquiry(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        note: note ?? this.note,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

// =====================================================================
// Expense
// =====================================================================
class Expense {
  final String id;
  final String title;
  final double amount;
  final String note;
  final DateTime spentOn;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.note,
    required this.spentOn,
  });

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'].toString(),
        title: m['title'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        note: m['note'] ?? '',
        spentOn: _date(m['spent_on']) ?? _date(m['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'note': note,
        'spent_on': spentOn.toIso8601String(),
      };

  Expense copyWith(
          {String? title, double? amount, String? note, DateTime? spentOn}) =>
      Expense(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        spentOn: spentOn ?? this.spentOn,
      );
}

// =====================================================================
// Invoice
// =====================================================================
class InvoiceItem {
  final String description;
  final double amount;
  const InvoiceItem({required this.description, required this.amount});

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
        description: m['description'] ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
      );
  Map<String, dynamic> toMap() =>
      {'description': description, 'amount': amount};
}

class Invoice {
  final String id;
  final String invoiceNo;
  final String billTo;
  final String phone;
  final DateTime date;
  final List<InvoiceItem> items;
  final double taxPercent;
  final String notes;

  const Invoice({
    required this.id,
    required this.invoiceNo,
    required this.billTo,
    required this.phone,
    required this.date,
    required this.items,
    required this.taxPercent,
    required this.notes,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.amount);
  double get taxAmount => subtotal * taxPercent / 100;
  double get total => subtotal + taxAmount;

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
        id: m['id'].toString(),
        invoiceNo: m['invoice_no'] ?? '',
        billTo: m['bill_to'] ?? '',
        phone: m['phone'] ?? '',
        date: _date(m['date']) ?? _date(m['created_at']) ?? DateTime.now(),
        items: (m['items'] as List?)
                ?.map((e) => InvoiceItem.fromMap(
                    (e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        taxPercent: (m['tax_percent'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'invoice_no': invoiceNo,
        'bill_to': billTo,
        'phone': phone,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toMap()).toList(),
        'tax_percent': taxPercent,
        'notes': notes,
      };
}

// =====================================================================
// Tax
// =====================================================================
class Tax {
  final String id;
  final String name;
  final double percent;

  const Tax({required this.id, required this.name, required this.percent});

  factory Tax.fromMap(Map<String, dynamic> m) => Tax(
        id: m['id'].toString(),
        name: m['name'] ?? '',
        percent: (m['percent'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {'name': name, 'percent': percent};

  Tax copyWith({String? name, double? percent}) =>
      Tax(id: id, name: name ?? this.name, percent: percent ?? this.percent);
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
