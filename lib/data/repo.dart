import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

/// Single data API for the whole app.
///
/// When Supabase is configured every call hits the database (scoped to the
/// signed-in admin's library). Otherwise it runs against a fully-mutable
/// in-memory store so the app is completely functional offline for preview.
class Repo {
  Repo._();
  static final Repo instance = Repo._();

  bool get live => SupabaseConfig.isConfigured;
  SupabaseClient get _c => Supabase.instance.client;
  String get _lib => SupabaseService.instance.libraryId ?? '';

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Bumped after every write so kept-alive screens (e.g. the dashboard in the
  /// bottom-nav IndexedStack) can refresh their data. Screens listen to this
  /// and re-run their queries.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  void _bump() => revision.value++;

  // ---- in-memory store ---------------------------------------------------
  final List<Member> _members = _seedMembers();
  final List<Book> _books = _seedBooks();
  final List<Payment> _payments = _seedPayments();
  final List<AttendanceEntry> _attendance = _seedAttendance();
  final List<Transaction> _txns = _seedTxns();
  final List<Shift> _shifts = Shift.defaults().toList();
  final List<SeatAllotment> _allotments = [];
  final List<Enquiry> _enquiries = _seedEnquiries();
  final List<Expense> _expenses = _seedExpenses();
  final List<Tax> _taxes = _seedTaxes();
  final List<Referral> _referrals = [];
  final List<Invoice> _invoices = [];

  // =====================================================================
  // MEMBERS
  // =====================================================================
  Future<List<Member>> members() async {
    if (!live) return List.of(_members);
    final rows = await _c
        .from('members')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Member.fromMap(e)).toList();
  }

  Future<String> nextMemberCode() async {
    final list = await members();
    // Highest numeric code + 1 (falls back to count-based).
    int maxN = 0;
    for (final m in list) {
      final n = int.tryParse(m.memberCode.replaceAll(RegExp(r'[^0-9]'), ''));
      if (n != null && n > maxN) maxN = n;
    }
    return '${maxN + 1}';
  }

  /// Inserts a member and returns it WITH its real id (a fresh DB UUID in live
  /// mode). Callers that need to link a seat/payment to the new member must use
  /// the returned object.
  Future<Member> addMember(Member m) async {
    if (!live) {
      _members.insert(0, m);
      _bump();
      return m;
    }
    final row = await _c
        .from('members')
        .insert({...m.toMap(), 'library_id': _lib})
        .select()
        .single();
    _bump();
    return Member.fromMap(row);
  }

  Future<void> updateMember(Member m) async {
    if (!live) {
      final i = _members.indexWhere((x) => x.id == m.id);
      if (i != -1) _members[i] = m;
    } else {
      await _c.from('members').update(m.toMap()).eq('id', m.id);
    }
    _bump();
  }

  Future<void> deleteMember(String id) async {
    if (!live) {
      _members.removeWhere((x) => x.id == id);
    } else {
      await _c.from('members').delete().eq('id', id);
    }
    _bump();
  }

  Member newMember({
    required String code,
    required String name,
    required String email,
    required String phone,
    required MemberStatus status,
    String? seatNo,
    String? plan,
    DateTime? expiresAt,
  }) =>
      Member(
        id: _id(),
        memberCode: code,
        name: name,
        email: email,
        phone: phone,
        status: status,
        seatNo: seatNo,
        plan: plan,
        joinedAt: DateTime.now(),
        expiresAt: expiresAt,
      );

  // =====================================================================
  // BOOKS
  // =====================================================================
  Future<List<Book>> books() async {
    if (!live) return List.of(_books);
    final rows = await _c
        .from('books')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Book.fromMap(e)).toList();
  }

  Future<void> addBook(Book b) async {
    if (!live) {
      _books.insert(0, b);
    } else {
      await _c.from('books').insert({...b.toMap(), 'library_id': _lib});
    }
    _bump();
  }

  Future<void> updateBook(Book b) async {
    if (!live) {
      final i = _books.indexWhere((x) => x.id == b.id);
      if (i != -1) _books[i] = b;
    } else {
      await _c.from('books').update(b.toMap()).eq('id', b.id);
    }
    _bump();
  }

  Future<void> deleteBook(String id) async {
    if (!live) {
      _books.removeWhere((x) => x.id == id);
    } else {
      await _c.from('books').delete().eq('id', id);
    }
    _bump();
  }

  Book newBook({
    required String title,
    required String author,
    required String isbn,
    required String category,
    required int copies,
    required Color accent,
  }) =>
      Book(
        id: _id(),
        title: title,
        author: author,
        isbn: isbn,
        category: category,
        totalCopies: copies,
        availableCopies: copies,
        accent: accent,
      );

  // =====================================================================
  // PAYMENTS
  // =====================================================================
  Future<List<Payment>> payments() async {
    if (!live) return List.of(_payments);
    final rows = await _c
        .from('payments')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Payment.fromMap(e)).toList();
  }

  Future<void> addPayment(Payment p) async {
    if (!live) {
      _payments.insert(0, p);
    } else {
      await _c.from('payments').insert({...p.toMap(), 'library_id': _lib});
    }
    _bump();
  }

  Payment newPayment({
    required Member member,
    required PaymentType type,
    required double amount,
    required PaymentStatus status,
    required String method,
  }) =>
      Payment(
        id: _id(),
        memberId: member.id,
        memberName: member.name,
        memberCode: member.memberCode,
        type: type,
        amount: amount,
        status: status,
        method: method,
        date: DateTime.now(),
      );

  // =====================================================================
  // ATTENDANCE
  // =====================================================================
  Future<List<AttendanceEntry>> attendance() async {
    if (!live) return List.of(_attendance);
    final start = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final rows = await _c
        .from('attendance')
        .select()
        .eq('library_id', _lib)
        .gte('marked_at', start.toIso8601String())
        .order('marked_at', ascending: false);
    return (rows as List).map((e) => AttendanceEntry.fromMap(e)).toList();
  }

  Future<void> markAttendance(Member m, AttendanceState state) async {
    final entry = AttendanceEntry(
      id: _id(),
      memberId: m.id,
      memberName: m.name,
      markedAt: DateTime.now(),
      state: state,
    );
    if (!live) {
      _attendance.insert(0, entry);
    } else {
      await _c.from('attendance').insert({...entry.toMap(), 'library_id': _lib});
    }
    _bump();
  }

  /// Updates an attendance row's state — used to "check out" a present member.
  Future<void> updateAttendanceState(String id, AttendanceState state) async {
    if (!live) {
      final i = _attendance.indexWhere((a) => a.id == id);
      if (i != -1) {
        final a = _attendance[i];
        _attendance[i] = AttendanceEntry(
          id: a.id,
          memberId: a.memberId,
          memberName: a.memberName,
          markedAt: a.markedAt,
          state: state,
          photoUrl: a.photoUrl,
        );
      }
    } else {
      await _c.from('attendance').update({'state': state.name}).eq('id', id);
    }
    _bump();
  }

  // =====================================================================
  // TRANSACTIONS / ISSUE-RETURN
  // =====================================================================
  Future<List<Transaction>> recentActivity({int limit = 8}) async {
    if (!live) return _txns.take(limit).toList();
    final rows = await _c
        .from('transactions')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map((e) => Transaction.fromMap(e)).toList();
  }

  Future<void> issueBook(Book b, Member m, {int loanDays = 14}) async {
    final txn = Transaction(
      id: _id(),
      bookId: b.id,
      memberId: m.id,
      bookTitle: b.title,
      memberName: m.name,
      isReturn: false,
      time: DateTime.now(),
      dueAt: DateTime.now().add(Duration(days: loanDays)),
    );
    final updated =
        b.copyWith(availableCopies: (b.availableCopies - 1).clamp(0, b.totalCopies));
    if (!live) {
      _txns.insert(0, txn);
      final i = _books.indexWhere((x) => x.id == b.id);
      if (i != -1) _books[i] = updated;
      _bump();
      return;
    }
    await _c.from('transactions').insert({...txn.toMap(), 'library_id': _lib});
    await updateBook(updated);
  }

  Future<void> returnBook(Book b, Member m) async {
    final txn = Transaction(
      id: _id(),
      bookId: b.id,
      memberId: m.id,
      bookTitle: b.title,
      memberName: m.name,
      isReturn: true,
      time: DateTime.now(),
    );
    final updated = b.copyWith(
        availableCopies: (b.availableCopies + 1).clamp(0, b.totalCopies));
    if (!live) {
      _txns.insert(0, txn);
      final i = _books.indexWhere((x) => x.id == b.id);
      if (i != -1) _books[i] = updated;
      _bump();
      return;
    }
    await _c.from('transactions').insert({...txn.toMap(), 'library_id': _lib});
    await updateBook(updated);
  }

  Future<List<Transaction>> monthTransactions() async {
    if (!live) return List.of(_txns);
    final start = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final rows = await _c
        .from('transactions')
        .select()
        .eq('library_id', _lib)
        .gte('created_at', start.toIso8601String())
        .order('created_at');
    return (rows as List).map((e) => Transaction.fromMap(e)).toList();
  }

  Future<List<Transaction>> allTransactions() async {
    if (!live) return List.of(_txns);
    final rows = await _c
        .from('transactions')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Transaction.fromMap(e)).toList();
  }

  Future<List<Transaction>> returnedTransactions() async {
    final all = await allTransactions();
    return all.where((t) => t.isReturn).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  /// Currently-issued books (issues with no matching return yet), matched in
  /// FIFO order per (book, member).
  Future<List<Loan>> activeLoans() async {
    final all = await allTransactions();
    all.sort((a, b) => a.time.compareTo(b.time)); // oldest first
    final open = <String, List<Transaction>>{};
    for (final t in all) {
      final key = '${t.bookId}|${t.memberId}';
      open.putIfAbsent(key, () => []);
      if (t.isReturn) {
        if (open[key]!.isNotEmpty) open[key]!.removeAt(0);
      } else {
        open[key]!.add(t);
      }
    }
    final loans = <Loan>[];
    for (final list in open.values) {
      for (final t in list) {
        loans.add(Loan(
          bookId: t.bookId ?? '',
          bookTitle: t.bookTitle,
          memberId: t.memberId ?? '',
          memberName: t.memberName,
          issuedAt: t.time,
          dueAt: t.dueAt,
        ));
      }
    }
    loans.sort((a, b) => a.issuedAt.compareTo(b.issuedAt));
    return loans;
  }

  Future<List<Loan>> overdueLoans() async {
    final loans = await activeLoans();
    return loans.where((l) => l.isOverdue).toList();
  }

  /// Returns a book from an active [Loan] (adds a return txn + frees a copy).
  Future<void> returnLoan(Loan loan) async {
    final list = await books();
    final book = list.where((b) => b.id == loan.bookId).toList();
    final member = Member(
      id: loan.memberId,
      memberCode: '',
      name: loan.memberName,
      email: '',
      phone: '',
      status: MemberStatus.active,
    );
    if (book.isNotEmpty) {
      await returnBook(book.first, member);
    } else {
      // Book was deleted — still record the return so the loan clears.
      final txn = Transaction(
        id: _id(),
        bookId: loan.bookId,
        memberId: loan.memberId,
        bookTitle: loan.bookTitle,
        memberName: loan.memberName,
        isReturn: true,
        time: DateTime.now(),
      );
      if (!live) {
        _txns.insert(0, txn);
      } else {
        await _c
            .from('transactions')
            .insert({...txn.toMap(), 'library_id': _lib});
      }
      _bump();
    }
  }

  /// Issued vs returned counts bucketed across the last 7 days (for the chart).
  Future<ChartSeries> issueReturnSeries({int days = 7}) async {
    final txns = await monthTransactions();
    final now = DateTime.now();
    final issued = List<double>.filled(days, 0);
    final returned = List<double>.filled(days, 0);
    for (final t in txns) {
      final ago = now.difference(t.time).inDays;
      if (ago < 0 || ago >= days) continue;
      final idx = days - 1 - ago;
      if (t.isReturn) {
        returned[idx] += 1;
      } else {
        issued[idx] += 1;
      }
    }
    return ChartSeries(issued: issued, returned: returned);
  }

  // =====================================================================
  // SHIFTS
  // =====================================================================
  Future<List<Shift>> shifts() async {
    if (!live) return List.of(_shifts);
    var rows = await _c
        .from('shifts')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: true);
    if ((rows as List).isEmpty) {
      final payload = Shift.defaults()
          .map((s) => {...s.toMap(), 'library_id': _lib})
          .toList();
      await _c.from('shifts').insert(payload);
      rows = await _c
          .from('shifts')
          .select()
          .eq('library_id', _lib)
          .order('created_at', ascending: true);
    }
    return (rows as List).map((e) => Shift.fromMap(e)).toList();
  }

  Future<void> saveShift(Shift s, {bool isNew = false}) async {
    if (!live) {
      final i = _shifts.indexWhere((x) => x.id == s.id);
      if (i != -1) {
        _shifts[i] = s;
      } else {
        _shifts.add(s);
      }
    } else if (isNew) {
      await _c.from('shifts').insert({...s.toMap(), 'library_id': _lib});
    } else {
      await _c.from('shifts').update(s.toMap()).eq('id', s.id);
    }
    _bump();
  }

  Future<void> deleteShift(String id) async {
    if (!live) {
      _shifts.removeWhere((x) => x.id == id);
    } else {
      await _c.from('shifts').delete().eq('id', id);
    }
    _bump();
  }

  Shift newShift({
    required String name,
    required String startTime,
    required String endTime,
    required double fee,
  }) =>
      Shift(
          id: _id(),
          name: name,
          startTime: startTime,
          endTime: endTime,
          fee: fee);

  // =====================================================================
  // SEATS / ALLOTMENTS
  // =====================================================================
  Future<List<SeatAllotment>> allotments(String shift) async {
    if (!live) {
      return _allotments.where((a) => a.shift == shift).toList();
    }
    final rows = await _c
        .from('seat_allotments')
        .select()
        .eq('library_id', _lib)
        .eq('shift', shift);
    return (rows as List).map((e) => SeatAllotment.fromMap(e)).toList();
  }

  /// Every seat allotment for the current library, across all shifts. Needed to
  /// check Full-Day vs shift conflicts.
  Future<List<SeatAllotment>> allSeatAllotments() async {
    if (!live) return List.of(_allotments);
    final rows =
        await _c.from('seat_allotments').select().eq('library_id', _lib);
    return (rows as List).map((e) => SeatAllotment.fromMap(e)).toList();
  }

  Future<void> allotSeat(int seatNo, String shift, Member m) async {
    // Block if the seat is already taken by a conflicting shift (Full Day vs
    // any slot, or the same slot).
    final existing = await allSeatAllotments();
    final clash = existing.any(
        (a) => a.seatNo == seatNo && seatShiftsConflict(a.shift, shift));
    if (clash) {
      throw Exception('Seat $seatNo is not available for $shift.');
    }
    final a = SeatAllotment(
      id: _id(),
      seatNo: seatNo,
      shift: shift,
      memberId: m.id,
      memberName: m.name,
    );
    if (!live) {
      _allotments.add(a);
    } else {
      await _c
          .from('seat_allotments')
          .insert({...a.toMap(), 'library_id': _lib});
    }
    _bump();
  }

  Future<void> freeSeat(String allotmentId) async {
    if (!live) {
      _allotments.removeWhere((a) => a.id == allotmentId);
    } else {
      await _c.from('seat_allotments').delete().eq('id', allotmentId);
    }
    _bump();
  }

  // =====================================================================
  // ENQUIRIES
  // =====================================================================
  Future<List<Enquiry>> enquiries() async {
    if (!live) return List.of(_enquiries);
    final rows = await _c
        .from('enquiries')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Enquiry.fromMap(e)).toList();
  }

  Future<void> saveEnquiry(Enquiry e, {bool isNew = false}) async {
    if (!live) {
      final i = _enquiries.indexWhere((x) => x.id == e.id);
      if (i != -1) {
        _enquiries[i] = e;
      } else {
        _enquiries.insert(0, e);
      }
    } else if (isNew) {
      await _c.from('enquiries').insert({...e.toMap(), 'library_id': _lib});
    } else {
      await _c.from('enquiries').update(e.toMap()).eq('id', e.id);
    }
    _bump();
  }

  Future<void> deleteEnquiry(String id) async {
    if (!live) {
      _enquiries.removeWhere((x) => x.id == id);
    } else {
      await _c.from('enquiries').delete().eq('id', id);
    }
    _bump();
  }

  Enquiry newEnquiry({
    required String name,
    required String phone,
    required String note,
    required EnquiryStatus status,
  }) =>
      Enquiry(
        id: _id(),
        name: name,
        phone: phone,
        note: note,
        status: status,
        createdAt: DateTime.now(),
      );

  // =====================================================================
  // EXPENSES
  // =====================================================================
  Future<List<Expense>> expenses() async {
    if (!live) return List.of(_expenses);
    final rows = await _c
        .from('expenses')
        .select()
        .eq('library_id', _lib)
        .order('spent_on', ascending: false);
    return (rows as List).map((e) => Expense.fromMap(e)).toList();
  }

  Future<void> saveExpense(Expense e, {bool isNew = false}) async {
    if (!live) {
      final i = _expenses.indexWhere((x) => x.id == e.id);
      if (i != -1) {
        _expenses[i] = e;
      } else {
        _expenses.insert(0, e);
      }
    } else if (isNew) {
      await _c.from('expenses').insert({...e.toMap(), 'library_id': _lib});
    } else {
      await _c.from('expenses').update(e.toMap()).eq('id', e.id);
    }
    _bump();
  }

  Future<void> deleteExpense(String id) async {
    if (!live) {
      _expenses.removeWhere((x) => x.id == id);
    } else {
      await _c.from('expenses').delete().eq('id', id);
    }
    _bump();
  }

  Expense newExpense({
    required String title,
    required double amount,
    required String note,
    required DateTime spentOn,
  }) =>
      Expense(
          id: _id(), title: title, amount: amount, note: note, spentOn: spentOn);

  // =====================================================================
  // TAXES
  // =====================================================================
  Future<List<Tax>> taxes() async {
    if (!live) return List.of(_taxes);
    final rows = await _c
        .from('taxes')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Tax.fromMap(e)).toList();
  }

  Future<void> saveTax(Tax t, {bool isNew = false}) async {
    if (!live) {
      final i = _taxes.indexWhere((x) => x.id == t.id);
      if (i != -1) {
        _taxes[i] = t;
      } else {
        _taxes.insert(0, t);
      }
    } else if (isNew) {
      await _c.from('taxes').insert({...t.toMap(), 'library_id': _lib});
    } else {
      await _c.from('taxes').update(t.toMap()).eq('id', t.id);
    }
    _bump();
  }

  Future<void> deleteTax(String id) async {
    if (!live) {
      _taxes.removeWhere((x) => x.id == id);
    } else {
      await _c.from('taxes').delete().eq('id', id);
    }
    _bump();
  }

  Tax newTax({required String name, required double percent}) =>
      Tax(id: _id(), name: name, percent: percent);

  // =====================================================================
  // INVOICES
  // =====================================================================
  Future<List<Invoice>> invoices() async {
    if (!live) return List.of(_invoices);
    final rows = await _c
        .from('invoices')
        .select()
        .eq('library_id', _lib)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Invoice.fromMap(e)).toList();
  }

  Future<String> nextInvoiceNo() async {
    final list = await invoices();
    return 'INV-${(list.length + 1).toString().padLeft(4, '0')}';
  }

  Future<void> saveInvoice(Invoice inv, {bool isNew = false}) async {
    if (!live) {
      final i = _invoices.indexWhere((x) => x.id == inv.id);
      if (i != -1) {
        _invoices[i] = inv;
      } else {
        _invoices.insert(0, inv);
      }
    } else if (isNew) {
      await _c.from('invoices').insert({...inv.toMap(), 'library_id': _lib});
    } else {
      await _c.from('invoices').update(inv.toMap()).eq('id', inv.id);
    }
    _bump();
  }

  Future<void> deleteInvoice(String id) async {
    if (!live) {
      _invoices.removeWhere((x) => x.id == id);
    } else {
      await _c.from('invoices').delete().eq('id', id);
    }
    _bump();
  }

  Invoice newInvoice({
    required String invoiceNo,
    required String billTo,
    required String phone,
    required DateTime date,
    required List<InvoiceItem> items,
    required double taxPercent,
    required String notes,
  }) =>
      Invoice(
        id: _id(),
        invoiceNo: invoiceNo,
        billTo: billTo,
        phone: phone,
        date: date,
        items: items,
        taxPercent: taxPercent,
        notes: notes,
      );

  // =====================================================================
  // STORAGE (member photo / documents)
  // =====================================================================
  static const _bucket = 'member-media';

  /// Uploads [file] to Supabase Storage and returns its public URL. In preview
  /// mode (no backend) it just returns the local file path so the image still
  /// displays.
  Future<String?> uploadMedia(File file, {String folder = 'misc'}) async {
    if (!live) return file.path;
    final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
    final path =
        '$_lib/$folder/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _c.storage.from(_bucket).upload(path, file);
    return _c.storage.from(_bucket).getPublicUrl(path);
  }

  // =====================================================================
  // REFERRALS
  // =====================================================================
  /// Records that [referredLib] signed up using someone's [referrerCode].
  Future<void> addReferral({
    required String referrerCode,
    required Library referredLib,
  }) async {
    final code = referrerCode.trim().toUpperCase();
    if (code.isEmpty) return;
    final ref = Referral(
      id: _id(),
      referrerCode: code,
      referredLibraryId: referredLib.id,
      referredName: referredLib.name,
      reward: 200,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    if (!live) {
      _referrals.add(ref);
      return;
    }
    await _c.from('referrals').insert(ref.toMap());
  }

  /// Referrals where [myCode] is the referrer (for the Refer & Earn stats).
  Future<List<Referral>> myReferrals(String myCode) async {
    final code = myCode.trim().toUpperCase();
    if (!live) {
      return _referrals.where((r) => r.referrerCode == code).toList();
    }
    final rows = await _c
        .from('referrals')
        .select()
        .eq('referrer_code', code)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Referral.fromMap(e)).toList();
  }

  /// Marks a pending referral as credited once the referred library subscribes.
  Future<void> creditReferralFor(String referredLibraryId) async {
    if (!live) {
      for (var i = 0; i < _referrals.length; i++) {
        if (_referrals[i].referredLibraryId == referredLibraryId &&
            _referrals[i].status == 'pending') {
          final r = _referrals[i];
          _referrals[i] = Referral(
            id: r.id,
            referrerCode: r.referrerCode,
            referredLibraryId: r.referredLibraryId,
            referredName: r.referredName,
            reward: r.reward,
            status: 'credited',
            createdAt: r.createdAt,
          );
        }
      }
      return;
    }
    await _c
        .from('referrals')
        .update({'status': 'credited'})
        .eq('referred_library_id', referredLibraryId)
        .eq('status', 'pending');
  }

  // =====================================================================
  // MEMBERSHIP EXPIRY
  // =====================================================================
  /// Members whose membership expires within [days] (includes already-expired),
  /// soonest first.
  Future<List<Member>> expiringSoon({int days = 15}) async {
    final all = await members();
    final now = DateTime.now();
    final list = all.where((m) {
      if (m.expiresAt == null) return false;
      return m.expiresAt!.difference(now).inDays <= days;
    }).toList()
      ..sort((a, b) => a.expiresAt!.compareTo(b.expiresAt!));
    return list;
  }

  /// Outstanding dues (pending + overdue) per member id.
  Future<Map<String, double>> duesByMember() async {
    final pays = await payments();
    final map = <String, double>{};
    for (final p in pays) {
      if (p.status != PaymentStatus.paid && p.memberId != null) {
        map[p.memberId!] = (map[p.memberId!] ?? 0) + p.amount;
      }
    }
    return map;
  }

  // =====================================================================
  // AGGREGATES
  // =====================================================================
  Future<DashboardData> dashboard() async {
    final results = await Future.wait([
      members(),
      recentActivity(),
      attendance(),
      activeLoans(),
      returnedTransactions(),
    ]);
    final mem = results[0] as List<Member>;
    final acts = results[1] as List<Transaction>;
    final att = results[2] as List<AttendanceEntry>;
    final loans = results[3] as List<Loan>;
    final returned = results[4] as List<Transaction>;

    return DashboardData(
      liveMembers: att.where((a) => a.state == AttendanceState.present).length,
      totalMembers: mem.length,
      activeMemberships:
          mem.where((m) => m.status == MemberStatus.active).length,
      booksIssued: loans.length,
      booksReturned: returned.length,
      overdueBooks: loans.where((l) => l.isOverdue).length,
      recent: acts,
    );
  }

  Future<ReportData> reports() async {
    final results = await Future.wait([members(), books(), payments()]);
    final mem = results[0] as List<Member>;
    final bks = results[1] as List<Book>;
    final pays = results[2] as List<Payment>;
    final fine = pays
        .where((p) => p.type == PaymentType.fine && p.status == PaymentStatus.paid)
        .fold<double>(0, (s, p) => s + p.amount);
    return ReportData(
      booksIssued: bks.fold(0, (s, b) => s + (b.totalCopies - b.availableCopies)),
      booksReturned:
          bks.fold(0, (s, b) => s + b.availableCopies).clamp(0, 100000),
      newMembers: mem.length,
      fineCollected: fine,
      topBooks: (bks.toList()
            ..sort((a, b) => (b.totalCopies - b.availableCopies)
                .compareTo(a.totalCopies - a.availableCopies)))
          .take(3)
          .toList(),
    );
  }

  Future<PaymentTotals> paymentTotals() async {
    final pays = await payments();
    double collection = 0, fineP = 0, pending = 0;
    for (final p in pays) {
      if (p.status == PaymentStatus.paid) {
        collection += p.amount;
        if (p.type == PaymentType.fine) fineP += p.amount;
      } else {
        pending += p.amount;
      }
    }
    return PaymentTotals(collection: collection, fine: fineP, pending: pending);
  }
}

// ---- aggregate value types -------------------------------------------
class DashboardData {
  final int liveMembers,
      totalMembers,
      activeMemberships,
      booksIssued,
      booksReturned,
      overdueBooks;
  final List<Transaction> recent;
  DashboardData({
    required this.liveMembers,
    required this.totalMembers,
    required this.activeMemberships,
    required this.booksIssued,
    required this.booksReturned,
    required this.overdueBooks,
    required this.recent,
  });
}

class ReportData {
  final int booksIssued, booksReturned, newMembers;
  final double fineCollected;
  final List<Book> topBooks;
  ReportData({
    required this.booksIssued,
    required this.booksReturned,
    required this.newMembers,
    required this.fineCollected,
    required this.topBooks,
  });
}

class PaymentTotals {
  final double collection, fine, pending;
  PaymentTotals(
      {required this.collection, required this.fine, required this.pending});
}

class ChartSeries {
  final List<double> issued, returned;
  ChartSeries({required this.issued, required this.returned});
}

// ---- seed data (in-memory preview mode) ------------------------------
List<Member> _seedMembers() => [
      Member(
          id: '1',
          memberCode: 'M00125',
          name: 'Rohit Sharma',
          email: 'rohit@gmail.com',
          phone: '+91 98765 43210',
          status: MemberStatus.active,
          joinedAt: DateTime(2026, 1, 12)),
      Member(
          id: '2',
          memberCode: 'M00126',
          name: 'Priya Singh',
          email: 'priya@gmail.com',
          phone: '+91 98765 43211',
          status: MemberStatus.active,
          joinedAt: DateTime(2026, 2, 3)),
      Member(
          id: '3',
          memberCode: 'M00127',
          name: 'Aman Verma',
          email: 'aman@gmail.com',
          phone: '+91 98765 43212',
          status: MemberStatus.active,
          joinedAt: DateTime(2026, 2, 20)),
      Member(
          id: '4',
          memberCode: 'M00128',
          name: 'Neha Patel',
          email: 'neha@gmail.com',
          phone: '+91 98765 43213',
          status: MemberStatus.expired,
          joinedAt: DateTime(2025, 11, 1)),
      Member(
          id: '5',
          memberCode: 'M00129',
          name: 'Vikram Joshi',
          email: 'vikram@gmail.com',
          phone: '+91 98765 43214',
          status: MemberStatus.active,
          joinedAt: DateTime(2026, 3, 5)),
      Member(
          id: '6',
          memberCode: 'M00130',
          name: 'Sneha Reddy',
          email: 'sneha@gmail.com',
          phone: '+91 98765 43215',
          status: MemberStatus.inactive,
          joinedAt: DateTime(2026, 1, 28)),
    ];

List<Book> _seedBooks() => const [
      Book(
          id: '1',
          title: 'The Alchemist',
          author: 'Paulo Coelho',
          isbn: '9780062315007',
          category: 'Fiction',
          totalCopies: 14,
          availableCopies: 12,
          accent: Color(0xFFE8622A)),
      Book(
          id: '2',
          title: 'Atomic Habits',
          author: 'James Clear',
          isbn: '9781847941831',
          category: 'Self-Help',
          totalCopies: 8,
          availableCopies: 5,
          accent: Color(0xFF2FB6A6)),
      Book(
          id: '3',
          title: 'Rich Dad Poor Dad',
          author: 'Robert Kiyosaki',
          isbn: '9781612680194',
          category: 'Finance',
          totalCopies: 10,
          availableCopies: 8,
          accent: Color(0xFF7C3AED)),
      Book(
          id: '4',
          title: 'Think and Grow Rich',
          author: 'Napoleon Hill',
          isbn: '9781585424334',
          category: 'Finance',
          totalCopies: 6,
          availableCopies: 0,
          accent: Color(0xFFEF4444)),
      Book(
          id: '5',
          title: 'The 5 AM Club',
          author: 'Robin Sharma',
          isbn: '9780358051084',
          category: 'Self-Help',
          totalCopies: 9,
          availableCopies: 7,
          accent: Color(0xFFF59E0B)),
    ];

List<Payment> _seedPayments() => [
      Payment(
          id: '1',
          memberName: 'Rohit Sharma',
          memberCode: 'M00125',
          type: PaymentType.membership,
          amount: 500,
          status: PaymentStatus.paid,
          date: DateTime(2026, 4, 21)),
      Payment(
          id: '2',
          memberName: 'Priya Singh',
          memberCode: 'M00126',
          type: PaymentType.fine,
          amount: 150,
          status: PaymentStatus.paid,
          date: DateTime(2026, 4, 21)),
      Payment(
          id: '3',
          memberName: 'Aman Verma',
          memberCode: 'M00127',
          type: PaymentType.membership,
          amount: 500,
          status: PaymentStatus.pending,
          date: DateTime(2026, 4, 20)),
      Payment(
          id: '4',
          memberName: 'Vikram Joshi',
          memberCode: 'M00129',
          type: PaymentType.fine,
          amount: 300,
          status: PaymentStatus.overdue,
          date: DateTime(2026, 4, 19)),
      Payment(
          id: '5',
          memberName: 'Sneha Reddy',
          memberCode: 'M00130',
          type: PaymentType.membership,
          amount: 500,
          status: PaymentStatus.paid,
          date: DateTime(2026, 4, 18)),
    ];

List<AttendanceEntry> _seedAttendance() => [
      AttendanceEntry(
          id: '1',
          memberName: 'Rohit Sharma',
          markedAt: DateTime.now().subtract(const Duration(minutes: 12)),
          state: AttendanceState.present),
      AttendanceEntry(
          id: '2',
          memberName: 'Priya Singh',
          markedAt: DateTime.now().subtract(const Duration(minutes: 24)),
          state: AttendanceState.present),
      AttendanceEntry(
          id: '3',
          memberName: 'Aman Verma',
          markedAt: DateTime.now().subtract(const Duration(minutes: 40)),
          state: AttendanceState.absent),
      AttendanceEntry(
          id: '4',
          memberName: 'Neha Patel',
          markedAt: DateTime.now().subtract(const Duration(minutes: 55)),
          state: AttendanceState.present),
    ];

List<Transaction> _seedTxns() => [
      Transaction(
          id: '1',
          bookTitle: 'The Alchemist',
          memberName: 'Rohit Sharma',
          isReturn: false,
          time: DateTime.now().subtract(const Duration(minutes: 2))),
      Transaction(
          id: '2',
          bookTitle: 'Atomic Habits',
          memberName: 'Priya Singh',
          isReturn: true,
          time: DateTime.now().subtract(const Duration(minutes: 15))),
      Transaction(
          id: '3',
          bookTitle: 'Rich Dad Poor Dad',
          memberName: 'Aman Verma',
          isReturn: false,
          time: DateTime.now().subtract(const Duration(minutes: 42))),
    ];

List<Enquiry> _seedEnquiries() => [
      Enquiry(
          id: 'e1',
          name: 'Karan Mehta',
          phone: '+91 90000 11111',
          note: 'Wants morning shift, asked about fees.',
          status: EnquiryStatus.fresh,
          createdAt: DateTime.now().subtract(const Duration(hours: 3))),
      Enquiry(
          id: 'e2',
          name: 'Divya Nair',
          phone: '+91 90000 22222',
          note: 'Will visit again tomorrow with documents.',
          status: EnquiryStatus.followUp,
          createdAt: DateTime.now().subtract(const Duration(days: 1))),
      Enquiry(
          id: 'e3',
          name: 'Sahil Khan',
          phone: '+91 90000 33333',
          note: 'Joined full-day plan.',
          status: EnquiryStatus.converted,
          createdAt: DateTime.now().subtract(const Duration(days: 2))),
    ];

List<Expense> _seedExpenses() => [
      Expense(
          id: 'x1',
          title: 'Electricity Bill',
          amount: 1600,
          note: 'Monthly power bill',
          spentOn: DateTime.now().subtract(const Duration(days: 2))),
      Expense(
          id: 'x2',
          title: 'Stationery',
          amount: 300,
          note: 'Registers and pens',
          spentOn: DateTime.now().subtract(const Duration(days: 5))),
    ];

List<Tax> _seedTaxes() => const [
      Tax(id: 't1', name: 'GST', percent: 18),
      Tax(id: 't2', name: 'Service Charge', percent: 5),
    ];
