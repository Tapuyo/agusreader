import 'package:agus_reader/constants/constant.dart';
import 'package:flutter/material.dart';

class MenuLabelButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsets? padding;
  final double? textSize;
  final bool isSelect;

  const MenuLabelButton({
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
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 35,
          width: 200,
          decoration: BoxDecoration(
      color: isSelect ? kColorBlue:Colors.transparent,
   
      borderRadius: BorderRadius.circular(20),),
  
        child: Padding(
          padding: padding ??
              const EdgeInsets.only(top: 0, bottom: 20, left: 20, right: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                text,
                style: isSelect? kTextStyleHeadline2Ligth:kTextStyleHeadline2Dark,
              ),
            ],
          ),
        ),
      )
  ),
    );
}}