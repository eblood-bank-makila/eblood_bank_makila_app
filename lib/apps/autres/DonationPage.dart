import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DonationPage extends ConsumerStatefulWidget {
  const DonationPage({super.key});

  @override
  ConsumerState createState() => _DonationPageState();
}

class _DonationPageState extends ConsumerState<DonationPage> {
  double _donationAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPages.COLOR_BLANCHE,
      appBar: AppBar(
        backgroundColor: ColorPages.COLOR_BLANCHE,
        title: Text('Faire une donation',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre don aidera à soutenir le développement de cette application.',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Montant du don',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'A partir de 1 \$',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _donationAmount = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.0),
                Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.0),
            Text(
              'Votre don sera utilisé pour améliorer et maintenir cette application.',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 24.0),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 100,
        color: ColorPages.COLOR_BLANCHE,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity, // Définit la largeur maximale
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    "assets/images/image11.jfif",
                    width: 30,
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Container(
                  width: 230,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text(
                      'Faire un don de $_donationAmount \$',
                      style: TextStyle(
                        color: ColorPages.COLOR_PRINCIPAL,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: ColorPages.COLOR_PRINCIPAL,
                      backgroundColor: ColorPages.COLOR_TRANSPARENT,
                      elevation: 0,
                      side: BorderSide(
                        color: ColorPages.COLOR_PRINCIPAL,
                        width: 2.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                        side: BorderSide(
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
