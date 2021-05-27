
/// DTO that tells whether or not a given command is allowed, along with a possible reason for it.
class CommandAllowance {

  final dynamic command;

  final bool isAllowed;

  final String reason;

  CommandAllowance(this.command, this.isAllowed, this.reason);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CommandAllowance &&
              runtimeType == other.runtimeType &&
              command == other.command &&
              isAllowed == other.isAllowed &&
              reason == other.reason;

  @override
  int get hashCode => command.hashCode ^ isAllowed.hashCode ^ reason.hashCode;

  @override
  String toString() {
    if (isAllowed) {
      return '${command.runtimeType} allowed';
    }
    if (reason.isNotEmpty) {
      return '${command.runtimeType} not allowed because $reason';
    }
    return '${command.runtimeType} not allowed';
  }
}
