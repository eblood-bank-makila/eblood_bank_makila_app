import 'package:animate_do/animate_do.dart';
import 'package:eblood_bank_mak_app/apps/config/utils/Utils.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/notification/DatumNotificationModel.dart';
import 'package:flutter/material.dart';
import '../config/theme/ColorPages.dart';

class NotificationWidget extends StatelessWidget {
  final DatumNotificationModel
      notification; // Changez ici pour un seul DactumModel

  NotificationWidget({required this.notification});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(width: 0.1, color: ColorPages.COLOR_CARD),
              borderRadius: BorderRadius.circular(15),
            ),
            //height: 120,
            child: Card(
                color: ColorPages.COLOR_CARD,
                elevation: 0,
                margin: EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(children: [
                      Icon(
                        Icons.comment,
                        color: ColorPages.COLOR_GRIS,
                        size: 19,
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title.capitalizeFirstLetter(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.0,
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Column(
                              children: [
                                Container(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          notification.notification,
                                          style: TextStyle(
                                            fontSize: 11.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      child: Text(
                                        notification.createdAt
                                            .formatReadableDate(),
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          color: ColorPages.COLOR_NOIR,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // Prevent overflow
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]))),
          ),
          SizedBox(
            height: 7,
          )
        ],
      ),
    );
  }
}
