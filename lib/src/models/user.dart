class User {
  String id;
  String email;
  String firstName;
  String lastName;
  String locale;
  bool activated;
  List<String> roles;

  User.fromJson(Map<String, Object> map) {
    id = map['id'];
    email = map['email'];
    firstName = map['firstName'];
    lastName = map['lastName'];
    activated = map['accountActivated'];
    locale = map['locale'];
    roles = map['roles'];
  }
}