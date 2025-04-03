import 'package:xbox_remote_play/xbox/input_key.dart';

class InputFrame {
  bool nexus = false;
  bool menu = false;
  bool view = false;
  bool a = false;
  bool b = false;
  bool x = false;
  bool y = false;
  bool dPadLeft = false;
  bool dPadUp = false;
  bool dPadRight = false;
  bool dPadDown = false;
  bool leftShoulder = false;
  bool rightShoulder = false;
  bool leftThumb = false;
  bool rightThumb = false;

  int leftStickXAxis = 0;
  int leftStickYAxis = 0;
  int rightStickXAxis = 0;
  int rightStickYAxis = 0;
  int leftTrigger = 0;
  int rightTrigger = 0;

  void Touch(InputKey key, bool state) {
    switch (key) {
      case InputKey.nexus:
        this.nexus = state;
        break;
      case InputKey.menu:
        this.menu = state;
        break;
      case InputKey.view:
        this.view = state;
        break;
      case InputKey.a:
        this.a = state;
        break;
      case InputKey.b:
        this.b = state;
        break;
      case InputKey.x:
        this.x = state;
        break;
      case InputKey.y:
        this.y = state;
        break;
      case InputKey.dpadLeft:
        this.dPadLeft = state;
        break;
      case InputKey.dpadUp:
        this.dPadUp = state;
        break;
      case InputKey.dpadRight:
        this.dPadRight = state;
        break;
      case InputKey.dpadDown:
        this.dPadDown = state;
        break;
      case InputKey.leftShoulder:
        this.leftShoulder = state;
        break;
      case InputKey.rightShoulder:
        this.rightShoulder = state;
        break;
      case InputKey.leftThumb:
        this.leftThumb = state;
        break;
      case InputKey.rightThumb:
        this.rightThumb = state;
        break;
      default:
        break;
    }
  }

  void Click(InputKey key, int? milliseconds) async {
    var duration = Duration(milliseconds: milliseconds ?? 50);
    switch (key) {
      case InputKey.nexus:
        this.nexus = true;
        await Future.delayed(duration);
        this.nexus = false;
        break;
      case InputKey.menu:
        this.menu = true;
        await Future.delayed(duration);
        this.menu = false;
        break;
      case InputKey.view:
        this.view = true;
        await Future.delayed(duration);
        this.view = false;
        break;
      case InputKey.a:
        this.a = true;
        await Future.delayed(duration);
        this.a = false;
        break;
      case InputKey.b:
        this.b = true;
        await Future.delayed(duration);
        this.b = false;
        break;
      case InputKey.x:
        this.x = true;
        await Future.delayed(duration);
        this.x = false;
        break;
      case InputKey.y:
        this.y = true;
        await Future.delayed(duration);
        this.y = false;
        break;
      case InputKey.dpadLeft:
        this.dPadLeft = true;
        await Future.delayed(duration);
        this.dPadLeft = false;
        break;
      case InputKey.dpadUp:
        this.dPadUp = true;
        await Future.delayed(duration);
        this.dPadUp = false;
        break;
      case InputKey.dpadRight:
        this.dPadRight = true;
        await Future.delayed(duration);
        this.dPadRight = false;
        break;
      case InputKey.dpadDown:
        this.dPadDown = true;
        await Future.delayed(duration);
        this.dPadDown = false;
        break;
      case InputKey.leftShoulder:
        this.leftShoulder = true;
        await Future.delayed(duration);
        this.leftShoulder = false;
        break;
      case InputKey.rightShoulder:
        this.rightShoulder = true;
        await Future.delayed(duration);
        this.rightShoulder = false;
        break;
      case InputKey.leftThumb:
        this.leftThumb = true;
        await Future.delayed(duration);
        this.leftThumb = false;
        break;
      case InputKey.rightThumb:
        this.rightThumb = true;
        await Future.delayed(duration);
        this.rightThumb = false;
        break;
      default:
        break;
    }
  }

  void SetAxis(InputKey key, int value) {
    switch (key) {
      case InputKey.leftStickXAxis:
        this.leftStickXAxis = value;
        break;
      case InputKey.leftStickYAxis:
        this.leftStickYAxis = value;
        break;
      case InputKey.rightStickXAxis:
        this.rightStickXAxis = value;
        break;
      case InputKey.rightStickYAxis:
        this.rightStickYAxis = value;
        break;
      case InputKey.leftTrigger:
        this.leftTrigger = value;
        break;
      case InputKey.rightTrigger:
        this.rightTrigger = value;
        break;
      default:
        break;
    }
  }

  bool Equals(InputFrame value) {
    if (this.a != value.a ||
        this.b != value.b ||
        this.x != value.x ||
        this.y != value.y ||
        this.leftStickXAxis != value.leftStickXAxis ||
        this.leftStickYAxis != value.leftStickYAxis ||
        this.rightStickXAxis != value.rightStickXAxis ||
        this.rightStickYAxis != value.rightStickYAxis ||
        this.leftThumb != value.leftThumb ||
        this.rightThumb != value.rightThumb ||
        this.dPadLeft != value.dPadLeft ||
        this.dPadUp != value.dPadUp ||
        this.dPadRight != value.dPadRight ||
        this.dPadDown != value.dPadDown ||
        this.leftTrigger != value.leftTrigger ||
        this.rightTrigger != value.rightTrigger ||
        this.leftShoulder != value.leftShoulder ||
        this.rightShoulder != value.rightShoulder ||
        this.nexus != value.nexus ||
        this.menu != value.menu ||
        this.view != value.view) {
      return false;
    }
    return true;
  }

  InputFrame DeepCopy() {
    var value = new InputFrame();
    value.a = this.a;
    value.b = this.b;
    value.x = this.x;
    value.y = this.y;
    value.leftStickXAxis = this.leftStickXAxis;
    value.leftStickYAxis = this.leftStickYAxis;
    value.rightStickXAxis = this.rightStickXAxis;
    value.rightStickYAxis = this.rightStickYAxis;
    value.leftThumb = this.leftThumb;
    value.rightThumb = this.rightThumb;
    value.dPadLeft = this.dPadLeft;
    value.dPadUp = this.dPadUp;
    value.dPadRight = this.dPadRight;
    value.dPadDown = this.dPadDown;
    value.leftTrigger = this.leftTrigger;
    value.rightTrigger = this.rightTrigger;
    value.leftShoulder = this.leftShoulder;
    value.rightShoulder = this.rightShoulder;
    value.nexus = this.nexus;
    value.menu = this.menu;
    value.view = this.view;
    return value;
  }
}
