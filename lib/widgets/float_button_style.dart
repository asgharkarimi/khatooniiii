import 'package:flutter/material.dart';

class FloatButtonStyle extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final double bottomMargin;

  const FloatButtonStyle({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.bottomMargin = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          tooltip: tooltip,
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Extension method to easily apply the float button style to a scaffold
extension FloatButtonScaffold on Scaffold {
  /// Returns a scaffold with the float button style applied
  static Scaffold withFloatButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    double bottomMargin = 16,
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Color? backgroundColor,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
      backgroundColor: backgroundColor,
      floatingActionButton: FloatButtonStyle(
        label: label,
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
        bottomMargin: bottomMargin,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
} 