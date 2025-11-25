class Validators {
  static String? emptyValidator(String? text) {
    if (text!.isEmpty) {
      return 'Please Fill in the field';
    }
    return null;
  }

  static String? doubleValidator(String? text) {
    if (text!.isEmpty) {
      return 'Please Fill in the field';
    }
    try {
      double.parse(text);
      return null;
    } catch (e) {
      return "Please enter correct value";
    }
  }

  static String? usernameValidator(String? email) {
    if (email!.isEmpty) {
      return 'Please fill in the username';
    }

    if (email.length < 6) {
      return 'Username must be at least 6 characters';
    }
    return null;
  }

  static String? emailValidator(String? email) {
    if (email!.isEmpty) {
      return 'Please Fill in the email';
    }

    const p =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    final regExp = RegExp(p);

    if (!regExp.hasMatch(email.trim())) {
      return 'Please Enter Valid Email Address';
    }
    return null;
  }

  static String? passwordValidator(String? password) {
    if (password!.isEmpty) {
      return 'Please fill in the password';
    }
    // const p =
    //     r"""^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z])(?=.*?[#?!@$%^&*\-\(\)_+\[\]{};:<>,"'./=,.|\\\~`]).{8,}$""";
    // const p =
    //     r"""^(?=.*\d)(?=.*[a-z])(?=.*[a-zA-Z])(?=.*?[#?!@$%^&*\-\(\)_+\[\]{};:<>,"'./=,.|\\\~`]).{8,}$""";
    // final regExp = RegExp(p);

    // if (!regExp.hasMatch(password.trim())) {
    //   return 'Password must be minimum eight characters, at least one uppercase letter,one lowercase letter, one number and one special character';
    // }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  static String? confirmPasswordValidator(String? password, String? oldPassword) {
    if (password!.isEmpty) {
      return 'Please fill in the password';
    }

    if (password != oldPassword) {
      return "Passwords don't match";
    }
    return null;
  }
}
