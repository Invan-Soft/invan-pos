part of 'upd_bloc.dart';

abstract class UpdState {}

class UpdInitial extends UpdState {}

class UpdInitialState extends UpdState {
  List<UpdFailedRepo> repos;

  UpdInitialState({
    required this.repos,
  });
}

class UpdLoadingState extends UpdState {
  List<UpdFailedRepo> repos;

  UpdLoadingState({
    required this.repos,
  });
}

class UpdFailedState extends UpdState {
  final String error;
  final APDstatus status;

  UpdFailedState({required this.error, required this.status});
}

class UpdAllDoneState extends UpdState {
  UpdAllDoneState();
}

class UpdAllDoneSomeFailedState extends UpdState {
  List<UpdFailedRepo> repos;

  UpdAllDoneSomeFailedState(this.repos);
}

class UpdFailedRepo {
  APDstatus apdStatus;
  String? error;
  RepoStatus repoStatus;

  UpdFailedRepo({
    required this.apdStatus,
    required this.error,
    required this.repoStatus,
  });
}

class UpdShowErrorState extends UpdState {
  UpdFailedRepo repo;

  UpdShowErrorState(this.repo);
}

class UpdInitialState2 extends UpdState {
  List<UpdFailedRepo> repos;

  UpdInitialState2(this.repos);
}

enum RepoStatus { done, inProgress, failed }
