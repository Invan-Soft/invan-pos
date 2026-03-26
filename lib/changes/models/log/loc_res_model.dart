
class LocalResModel {
  LocalResModel({
    this.error,
    this.message,
    this.isFromServer,
  });

  bool? error;
  String? message;
  bool? isFromServer;

  factory LocalResModel.fromJson(Map<dynamic, dynamic> json) => LocalResModel(
        error: json["error"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "error": error,
        "message": message,
      };
}
