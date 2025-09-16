import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';

class BoutonWidget extends StatefulWidget {
  final Function onPressed;
  final String text;

  BoutonWidget({required this.text, required this.onPressed});

  @override
  State<BoutonWidget> createState() => _BoutonWidgetState();
}

class _BoutonWidgetState extends State<BoutonWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 50,
      child: ElevatedButton(
        onPressed: widget.onPressed as void Function()?,
        child: Text(
          widget.text,
          style: TextStyle(
              color: ColorPages.COLOR_BLANCHE, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
            backgroundColor: ColorPages.COLOR_PRINCIPAL,
            elevation: 0,
            side: BorderSide(
              color: ColorPages.COLOR_PRINCIPAL, // Couleur du bord
              width: 2.0, // Épaisseur du bord
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: ColorPages.COLOR_PRINCIPAL,
                ))),
      ),
    );
  }
}
