import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierCtrl.dart';
import 'package:eblood_bank_mak_app/commande/ui/pages/panier/PanierPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../apps/config/theme/ColorPages.dart';

class CommandePage extends ConsumerStatefulWidget {
  const CommandePage({super.key});

  @override
  ConsumerState createState() => _CommandePageState();
}

class _CommandePageState extends ConsumerState<CommandePage> {
  @override
  Widget build(BuildContext context) {
    var state = ref.watch(panierCtrlProvider);
    return Scaffold(
      backgroundColor: ColorPages.COLOR_BLANCHE,
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_BLANCHE,
        title: Text(
          'Gérer les commandes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // Icon(
                //   Icons.shopping_cart_outlined,
                //   size: 22,
                // ),

                IconButton(
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PanierPage()),
                    );
                  },
                ),
                Positioned(
                  top: 10,
                  right: 15,
                  child: Badge(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    label: Text(
                      "${state.paniers?.data[0].cartItems.length ?? 0}",
                      style: TextStyle(color: ColorPages.COLOR_BLANCHE),
                    ),
                    child: SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
