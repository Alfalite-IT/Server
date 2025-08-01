class ProductValidator {
  final Map<String, dynamic> _data;
  final List<String> _errors = [];

  ProductValidator(this._data);

  String? validate() {
    _validateString('name');
    _validateString('image');
    _validateString('contrast', isRequired: false);
    _validateString('visionAngle', isRequired: false);
    _validateString('redundancy', isRequired: false);
    _validateString('curvedVersion', isRequired: false);
    _validateString('opticalMultilayerInjection', isRequired: false);

    _validateList('location');
    _validateList('application');

    _validateNum('horizontal');
    _validateNum('vertical');
    _validateNum('brightness');
    _validateNum('pixelPitch');
    _validateNum('width');
    _validateNum('height');
    _validateNum('depth');
    _validateNum('consumption');
    _validateNum('weight');
    _validateNum('refreshRate', isRequired: false);
    
    return _errors.isEmpty ? null : _errors.join(' ');
  }

  void _validateString(String key, {bool isRequired = true}) {
    final value = _data[key];
    if (value == null) {
      if (isRequired) _errors.add('$key is required.');
      return;
    }
    if (value is! String) {
      _errors.add('$key must be a string.');
    } else if (isRequired && value.isEmpty) {
      _errors.add('$key cannot be empty.');
    }
  }

  void _validateList(String key) {
    final value = _data[key];
    if (value == null) {
      _errors.add('$key is required.');
      return;
    }
    if (value is! List) {
      _errors.add('$key must be a list of strings.');
    }
  }

  void _validateNum(String key, {bool isRequired = true}) {
    final value = _data[key];
    if (value == null) {
      if (isRequired) _errors.add('$key is required.');
      return;
    }
    // Accept any numeric type (int or double) from JSON.
    if (value is! num) {
      _errors.add('$key must be a number.');
    }
  }
} 