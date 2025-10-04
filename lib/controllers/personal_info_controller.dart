import '../models/personal_info_model.dart';

class PersonalInfoController {
  PersonalInfo _info = PersonalInfo(
    address: "Amman - Tabarbor",
    email: "johncena@gmail.com",
    phone: "07834737335",
    altPhone: "079736462084",
    identifier1: "Identifier 1",
    identifier1Phone: "079999999",
    identifier2: "Identifier 2",
    identifier2Phone: "078888888",
  );

  PersonalInfo get info => _info;

  void updateInfo(PersonalInfo newInfo) {
    _info = newInfo;
  }
}
