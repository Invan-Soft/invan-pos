class FiscalStatusModel {
  String? _startTime;
  Sender? _sender;
  FiscalDB? _dB;

  FiscalStatusModel({String? startTime, Sender? sender, FiscalDB? dB}) {
    if (startTime != null) {
      _startTime = startTime;
    }
    if (sender != null) {
      _sender = sender;
    }
    if (dB != null) {
      _dB = dB;
    }
  }

  String? get startTime => _startTime;

  Sender? get sender => _sender;

  FiscalDB? get dB => _dB;

  FiscalStatusModel.fromJson(Map<String, dynamic> json) {
    _startTime = json['StartTime'];
    _sender = json['Sender'] != null ? Sender.fromJson(json['Sender']) : null;
    _dB = json['DB'] != null ? FiscalDB.fromJson(json['DB']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['StartTime'] = _startTime;
    if (_sender != null) {
      data['Sender'] = _sender!.toJson();
    }
    if (_dB != null) {
      data['DB'] = _dB!.toJson();
    }
    return data;
  }
}

class Sender {
  String? _liveAddress;
  String? _lastSendReceiveDuration;
  String? _lastOnlineTime;
  TotalFilesSent? _totalFilesSent;
  TotalFilesSent? _fullReceiptFilesSent;
  ReceiptFilesSent? _receiptFilesSent;
  TotalFilesSent? _advanceReceiptFilesSent;
  TotalFilesSent? _creditReceiptFilesSent;
  ReceiptFilesSent? _encodedFullReceiptBodyFilesSent;
  TotalFilesSent? _zReportFilesSent;
  TotalFilesSent? _totalAckFilesReceived;

  Sender(
      {String? liveAddress,
      String? lastSendReceiveDuration,
      String? lastOnlineTime,
      TotalFilesSent? totalFilesSent,
      TotalFilesSent? fullReceiptFilesSent,
      ReceiptFilesSent? receiptFilesSent,
      TotalFilesSent? advanceReceiptFilesSent,
      TotalFilesSent? creditReceiptFilesSent,
      ReceiptFilesSent? encodedFullReceiptBodyFilesSent,
      TotalFilesSent? zReportFilesSent,
      TotalFilesSent? totalAckFilesReceived}) {
    if (liveAddress != null) {
      _liveAddress = liveAddress;
    }
    if (lastSendReceiveDuration != null) {
      _lastSendReceiveDuration = lastSendReceiveDuration;
    }
    if (lastOnlineTime != null) {
      _lastOnlineTime = lastOnlineTime;
    }
    if (totalFilesSent != null) {
      _totalFilesSent = totalFilesSent;
    }
    if (fullReceiptFilesSent != null) {
      _fullReceiptFilesSent = fullReceiptFilesSent;
    }
    if (receiptFilesSent != null) {
      _receiptFilesSent = receiptFilesSent;
    }
    if (advanceReceiptFilesSent != null) {
      _advanceReceiptFilesSent = advanceReceiptFilesSent;
    }
    if (creditReceiptFilesSent != null) {
      _creditReceiptFilesSent = creditReceiptFilesSent;
    }
    if (encodedFullReceiptBodyFilesSent != null) {
      _encodedFullReceiptBodyFilesSent = encodedFullReceiptBodyFilesSent;
    }
    if (zReportFilesSent != null) {
      _zReportFilesSent = zReportFilesSent;
    }
    if (totalAckFilesReceived != null) {
      _totalAckFilesReceived = totalAckFilesReceived;
    }
  }

  String? get liveAddress => _liveAddress;

  String? get lastSendReceiveDuration => _lastSendReceiveDuration;

  String? get lastOnlineTime => _lastOnlineTime;

  TotalFilesSent? get totalFilesSent => _totalFilesSent;

  TotalFilesSent? get fullReceiptFilesSent => _fullReceiptFilesSent;

  ReceiptFilesSent? get receiptFilesSent => _receiptFilesSent;

  TotalFilesSent? get advanceReceiptFilesSent => _advanceReceiptFilesSent;

  TotalFilesSent? get creditReceiptFilesSent => _creditReceiptFilesSent;

  ReceiptFilesSent? get encodedFullReceiptBodyFilesSent =>
      _encodedFullReceiptBodyFilesSent;

  TotalFilesSent? get zReportFilesSent => _zReportFilesSent;

  TotalFilesSent? get totalAckFilesReceived => _totalAckFilesReceived;

  Sender.fromJson(Map<String, dynamic> json) {
    _liveAddress = json['LiveAddress'];
    _lastSendReceiveDuration = json['LastSendReceiveDuration'];
    _lastOnlineTime = json['LastOnlineTime'];
    _totalFilesSent = json['TotalFilesSent'] != null
        ? TotalFilesSent.fromJson(json['TotalFilesSent'])
        : null;
    _fullReceiptFilesSent = json['FullReceiptFilesSent'] != null
        ? TotalFilesSent.fromJson(json['FullReceiptFilesSent'])
        : null;
    _receiptFilesSent = json['ReceiptFilesSent'] != null
        ? ReceiptFilesSent.fromJson(json['ReceiptFilesSent'])
        : null;
    _advanceReceiptFilesSent = json['AdvanceReceiptFilesSent'] != null
        ? TotalFilesSent.fromJson(json['AdvanceReceiptFilesSent'])
        : null;
    _creditReceiptFilesSent = json['CreditReceiptFilesSent'] != null
        ? TotalFilesSent.fromJson(json['CreditReceiptFilesSent'])
        : null;
    _encodedFullReceiptBodyFilesSent =
        json['EncodedFullReceiptBodyFilesSent'] != null
            ? ReceiptFilesSent.fromJson(json['EncodedFullReceiptBodyFilesSent'])
            : null;
    _zReportFilesSent = json['ZReportFilesSent'] != null
        ? TotalFilesSent.fromJson(json['ZReportFilesSent'])
        : null;
    _totalAckFilesReceived = json['TotalAckFilesReceived'] != null
        ? TotalFilesSent.fromJson(json['TotalAckFilesReceived'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['LiveAddress'] = _liveAddress;
    data['LastSendReceiveDuration'] = _lastSendReceiveDuration;
    data['LastOnlineTime'] = _lastOnlineTime;
    if (_totalFilesSent != null) {
      data['TotalFilesSent'] = _totalFilesSent!.toJson();
    }
    if (_fullReceiptFilesSent != null) {
      data['FullReceiptFilesSent'] = _fullReceiptFilesSent!.toJson();
    }
    if (_receiptFilesSent != null) {
      data['ReceiptFilesSent'] = _receiptFilesSent!.toJson();
    }
    if (_advanceReceiptFilesSent != null) {
      data['AdvanceReceiptFilesSent'] = _advanceReceiptFilesSent!.toJson();
    }
    if (_creditReceiptFilesSent != null) {
      data['CreditReceiptFilesSent'] = _creditReceiptFilesSent!.toJson();
    }
    if (_encodedFullReceiptBodyFilesSent != null) {
      data['EncodedFullReceiptBodyFilesSent'] =
          _encodedFullReceiptBodyFilesSent!.toJson();
    }
    if (_zReportFilesSent != null) {
      data['ZReportFilesSent'] = _zReportFilesSent!.toJson();
    }
    if (_totalAckFilesReceived != null) {
      data['TotalAckFilesReceived'] = _totalAckFilesReceived!.toJson();
    }
    return data;
  }
}

class TotalFilesSent {
  int? _vG300750000021;

  TotalFilesSent({int? vG300750000021}) {
    if (vG300750000021 != null) {
      _vG300750000021 = vG300750000021;
    }
  }

  int? get vG300750000021 => _vG300750000021;

  TotalFilesSent.fromJson(Map<String, dynamic> json) {
    _vG300750000021 = json['VG300750000021'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['VG300750000021'] = _vG300750000021;
    return data;
  }
}

class ReceiptFilesSent {
  ReceiptFilesSent();

  ReceiptFilesSent.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    return data;
  }
}

class FiscalDB {
  ArchivedFiles? _archivedFiles;

  FiscalDB({ArchivedFiles? archivedFiles}) {
    if (archivedFiles != null) {
      _archivedFiles = archivedFiles;
    }
  }

  ArchivedFiles? get archivedFiles => _archivedFiles;

  FiscalDB.fromJson(Map<String, dynamic> json) {
    _archivedFiles = json['ArchivedFiles'] != null
        ? ArchivedFiles.fromJson(json['ArchivedFiles'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (_archivedFiles != null) {
      data['ArchivedFiles'] = _archivedFiles!.toJson();
    }
    return data;
  }
}

class ArchivedFiles {
  int? _i202205;

  ArchivedFiles({int? i202205}) {
    if (i202205 != null) {
      _i202205 = i202205;
    }
  }

  int? get i202205 => _i202205;

  ArchivedFiles.fromJson(Map<String, dynamic> json) {
    _i202205 = json['2022-05'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['2022-05'] = _i202205;
    return data;
  }
}
