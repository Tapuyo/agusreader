import 'package:agus_reader/constants/constant.dart';
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsets? padding;
  final double? textSize;
  final bool isSelect;

  const MenuButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.isSelect,
    this.elevation,
    this.borderRadius = 20,
    this.padding,
    this.textSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
      color: isSelect ? kColorBlue:kColorDarkBlue,
   
      borderRadius: BorderRadius.circular(20),),
  
        child: Padding(
          padding: padding ??
              const EdgeInsets.only(top: 0, bottom: 20, left: 20, right: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                text,
                style: isSelect ? kTextStyleHeadline2Ligth:kTextStyleHeadline2Dark,
              ),
            ],
          ),
        ),
      )
  ),
    );
}}