import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/apps/widgets/DetailsPocheBanqueWidget.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/banque/BanqueModele.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gestionStocks/business/model/poche/PocheModel.dart';

class PocheBanqueWidget extends ConsumerWidget {
  final PocheModel poches;
  final BanqueModele banque;

  PocheBanqueWidget({required this.poches, required this.banque});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPocheBanqueWidget(
                poche: poches,
                banqueNom: banque.blood_bank_name,
                banque: banque,
              ),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(width: 0.1, color: ColorPages.COLOR_CARD),
                borderRadius: BorderRadius.circular(15),
              ),
              height: 100,
              child: Card(
                color: ColorPages.COLOR_CARD,
                elevation:.3,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 1.0),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
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
                              "${poches.bloodBagInfo.bloodTypeInfo.bloodTypeName} ${poches.bloodBagInfo.bloodRhesusInfo.bloodRheususName}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                            ),
                            SizedBox(
                              height: 1,
                            ),
                            Text(
                              "${poches.bloodBagInfo.bloodVolumeInfo.bloodVolumeName} ${poches.bloodBagInfo.bloodVolumeInfo.bloodVolumeUnityInfo.bloodVolumeUnityName} ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.0,
                                color: ColorPages.COLOR_GRIS,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "${poches.bloodStockCount} poche en stock",
                                  style: TextStyle(
                                    //fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: ColorPages.COLOR_BLUE,
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
          ],
        ),
      ),
    );
  }
}
