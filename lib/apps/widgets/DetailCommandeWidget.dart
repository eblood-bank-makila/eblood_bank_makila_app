import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/commande/business/model/DatumPanierModel.dart';
import 'package:flutter/material.dart';

class DetailCommandeWidget extends StatefulWidget {
  final DatumModel paniers;
  final int index;

  DetailCommandeWidget({required this.paniers, required this.index});

  @override
  _DetailCommandeWidgetState createState() => _DetailCommandeWidgetState();
}

class _DetailCommandeWidgetState extends State<DetailCommandeWidget> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.paniers.cartItems[widget.index].quantity;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paniers.cartItems.isEmpty) {
      return Center(child: Text("Aucun article dans le panier."));
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(width: 0.1, color: ColorPages.COLOR_CARD),
              borderRadius: BorderRadius.circular(0),
            ),
            //height: 88,
            child: Card(
              color: ColorPages.COLOR_BLANCHE,
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Padding(
                padding: EdgeInsets.all(1.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/poche.jfif'),
                      radius: 20,
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodTypeInfo.bloodTypeName} ${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodRhesusInfo.bloodRheususName}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.0,
                            ),
                          ),
                          Text(
                            "${widget.paniers.cartItems[0].bloodBankInfo.bloodBankName.capitalizeFirstLetter()}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.0,
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            "${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodVolumeInfo.bloodVolumeName} ${widget.paniers.cartItems[widget.index].bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 9.0,
                              color: ColorPages.COLOR_GRIS,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Qty: ${widget.paniers.cartItems[widget.index].quantity}",
                                style: TextStyle(
                                  fontSize: 9.0,
                                  color: ColorPages.COLOR_GRIS,
                                ),
                              ),
                              Text(
                                "\$ ${widget.paniers.cartItems[widget.index].quantity * widget.paniers.cartItems[widget.index].price}",
                                style: TextStyle(
                                  //fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                  color: ColorPages.COLOR_PRINCIPAL,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
        ],
      ),
    );
  }
}
