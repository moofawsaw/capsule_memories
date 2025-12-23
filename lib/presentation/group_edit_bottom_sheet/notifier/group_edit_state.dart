import '../models/group_edit_model.dart';

abstract class GroupEditState {
  GroupEditModel get groupEditModelObj;
}

class GroupEditInitial extends GroupEditState {
  @override
  GroupEditModel get groupEditModelObj => GroupEditModel();
}

class GroupEditLoaded extends GroupEditState {
  @override
  final GroupEditModel groupEditModelObj;

  GroupEditLoaded(this.groupEditModelObj);
}
