import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _userDateOfBirth = TextEditingController();
  final TextEditingController _userEmail = TextEditingController();
  final TextEditingController _userMobileNumber = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  bool _isEditing = false;

  String _initialUserName = '';
  DateTime _initialDateOfBirth = DateTime.now();
  String _initialEmail = '';
  String _initialMobileNumber = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _userName.text = "Shantanu";
    _userDateOfBirth.text = "23/08/2024";
    _userEmail.text = "shan@gmail.com";
    _userMobileNumber.text = "9876543210";

    _saveInitialValues();
  }

  void _saveInitialValues() {
    _initialUserName = _userName.text;
    _initialDateOfBirth =
        DateTime.tryParse(_userDateOfBirth.text) ?? DateTime.now();
    _initialEmail = _userEmail.text;
    _initialMobileNumber = _userMobileNumber.text;
  }

  void _toggleEditMode() {
    if (_isEditing) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() {
          _isEditing = false;
        });
      }
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _userName.text = _initialUserName;
      _userDateOfBirth.text = _formatDate(_initialDateOfBirth);
      _userEmail.text = _initialEmail;
      _userMobileNumber.text = _initialMobileNumber;
      _isEditing = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _initialDateOfBirth) {
      setState(() {
        _initialDateOfBirth = pickedDate;
        _userDateOfBirth.text = _formatDate(pickedDate);
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the backgroundColor from Scaffold
      body: Container(
        height: 10000,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Form(
                key: _formKey, // Attach form key
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/logo_bgless.png",
                          width: 50,
                          height: 50,
                        ),
                        SizedBox(width: 15),
                        Text(
                          'Profit Pocket',
                          style: TextStyle(
                            fontSize: 35,
                            color: Theme.of(context).focusColor,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    SizedBox(height: 10),
                    Text(
                      "PROFILE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).focusColor,
                        fontSize: 23,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildLabeledTextFormField(
                      label: "User Name",
                      controller: _userName,
                      isEnabled: _isEditing,
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: _isEditing ? _selectDate : null,
                      child: AbsorbPointer(
                        child: _buildLabeledTextFormField(
                          label: "Date of Birth",
                          controller: _userDateOfBirth,
                          isEnabled: _isEditing,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildLabeledTextFormField(
                      label: "Email",
                      controller: _userEmail,
                      isEnabled: _isEditing,
                    ),
                    SizedBox(height: 10),
                    _buildLabeledTextFormField(
                      label: "Mobile Number",
                      controller: _userMobileNumber,
                      isEnabled: _isEditing,
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _toggleEditMode,
                            child: Text(_isEditing ? "Save" : "Edit"),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              textStyle: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 10),
                          if (_isEditing)
                            ElevatedButton(
                              onPressed: _cancelEdit,
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Theme.of(context).focusColor),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                textStyle: TextStyle(fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledTextFormField({
    required String label,
    required TextEditingController controller,
    required bool isEnabled,
    bool isDatePicker = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(color: Colors.white, fontSize: 16),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ),
        ),
        SizedBox(height: 5),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Colors.grey, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Colors.grey, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
          readOnly: !isEnabled,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label cannot be empty';
            }
            return null;
          },
        ),
      ],
    );
  }
}
