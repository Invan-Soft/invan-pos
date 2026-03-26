class SettingsFeatureModel {
  SettingsFeatureModel({
    this.addFromWarehause,
    this.chat,
    this.clientDebtByCategory,
    this.debts,
    this.delivery,
    this.inventory,
    this.isLocalServer,
    this.karaoke,
    this.nds,
    this.openTickets,
    this.openedReceipts,
    this.orders,
    this.prices,
    this.scale,
    this.section,
    this.shifts,
    this.showStock,
    this.timeClock,
    this.updatedAt,
    this.usePurchaseCostOnPricing,
    this.success,
  });

  bool? addFromWarehause;
  bool? chat;
  bool? clientDebtByCategory;
  bool? debts;
  bool? delivery;
  bool? inventory;
  bool? isLocalServer;
  bool? karaoke;
  bool? nds;
  bool? openTickets;
  bool? openedReceipts;
  bool? orders;
  bool? prices;
  bool? scale;
  bool? section;
  bool? shifts;
  bool? showStock;
  bool? timeClock;
  DateTime? updatedAt;
  bool? usePurchaseCostOnPricing;
  bool? success;

  factory SettingsFeatureModel.fromJson(Map<String, dynamic> json) =>
      SettingsFeatureModel(
        addFromWarehause: json["add_from_warehause"],
        chat: json["chat"],
        clientDebtByCategory: json["client_debt_by_category"],
        debts: json["debts"],
        delivery: json["delivery"],
        inventory: json["inventory"],
        isLocalServer: json["is_local_server"],
        karaoke: json["karaoke"],
        nds: json["nds"],
        openTickets: json["open_tickets"],
        openedReceipts: json["opened_receipts"],
        orders: json["orders"],
        prices: json["prices"],
        scale: json["scale"],
        section: json["section"],
        shifts: json["shifts"],
        showStock: json["show_stock"],
        timeClock: json["time_clock"],
        updatedAt: DateTime.parse(json["updatedAt"]),
        usePurchaseCostOnPricing: json["use_purchase_cost_on_pricing"],
      );

  Map<String, dynamic> toJson() => {
        "add_from_warehause": addFromWarehause,
        "chat": chat,
        "client_debt_by_category": clientDebtByCategory,
        "debts": debts,
        "delivery": delivery,
        "inventory": inventory,
        "is_local_server": isLocalServer,
        "karaoke": karaoke,
        "nds": nds,
        "open_tickets": openTickets,
        "opened_receipts": openedReceipts,
        "orders": orders,
        "prices": prices,
        "scale": scale,
        "section": section,
        "shifts": shifts,
        "show_stock": showStock,
        "time_clock": timeClock,
        "updatedAt": updatedAt?.toIso8601String(),
        "use_purchase_cost_on_pricing": usePurchaseCostOnPricing,
      };
}
