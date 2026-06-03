import 'package:flutter/material.dart';

class Container1 extends StatelessWidget {
  const Container1({
    super.key,
    this.height = 10,
    this.width = 10,
    required this.child,
  });

  final double height;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10, right: 20, left: 20),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          style: BorderStyle.solid,
          color: Colors.pink,
        ),
      ),
      height: height,
      child: child,
    );
  }
}

class Container2 extends StatelessWidget {
  const Container2({
    super.key,
    this.height = 10,
    this.width = 10,
    required this.child,
  });

  final double height;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10, right: 20, left: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 233, 222),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          style: BorderStyle.solid,
          color: Colors.pink,
        ),
      ),
      height: height,
      child: child,
    );
  }
}

class Container3 extends StatelessWidget {
  const Container3({
    super.key,
    this.height = 10,
    this.width = 10,
    required this.child,
  });

  final double height;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 20, left: 20),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          style: BorderStyle.solid,
          color: Colors.pink,
        ),
      ),
      height: height,
      child: child,
    );
  }
}
