import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';

class BoutonAnnulerWidget extends StatefulWidget {
  final Function onPressed;
  final String text;

  BoutonAnnulerWidget({required this.text, required this.onPressed});

  @override
  State<BoutonAnnulerWidget> createState() => _BoutonAnnulerWidgetState();
}

class _BoutonAnnulerWidgetState extends State<BoutonAnnulerWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorPages.COLOR_TRANSPARENT,
      height: 50,
      width: 300,
      child: ElevatedButton(
        onPressed: widget.onPressed as void Function()?,
        child: Text(
          widget.text,
          style: TextStyle(
              color: ColorPages.COLOR_BLANCHE, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
            foregroundColor: ColorPages.COLOR_PRINCIPAL,
            backgroundColor: ColorPages.COLOR_TRANSPARENT,
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
