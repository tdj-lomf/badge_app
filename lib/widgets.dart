// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// modified by Toda (2022/06) for AI Badge.

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, required this.result, this.onTap})
      : super(key: key);

  final ScanResult result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return 'N/A';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.black,
          onPrimary: Colors.white,
        ),
        onPressed: (result.advertisementData.connectable) ? onTap : null,
        child: const Text('CONNECT'),
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(context, 'Manufacturer Data',
            getNiceManufacturerData(result.advertisementData.manufacturerData)),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData)),
      ],
    );
  }
}

class ServiceRow extends StatefulWidget {
  final BluetoothService service;

  const ServiceRow({Key? key, required this.service}) : super(key: key);

  @override
  _ServiceRowState createState() => _ServiceRowState();
}

class _ServiceRowState extends State<ServiceRow> {
  double _eyeX = 100;
  double _eyeY = 100;
  final _eyelidZito1 = <bool>[false];
  final _eyelidZito2 = <bool>[false];
  final _eyelidNiyake = <bool>[false];
  final _eyelidMabataki = <bool>[false];

  @override
  Widget build(BuildContext context) {
    var service = widget.service;
    if (service.characteristics.isNotEmpty) {
      BluetoothCharacteristic? cLed;
      BluetoothCharacteristic? cEye;
      BluetoothCharacteristic? cEyelid;
      for (BluetoothCharacteristic c in service.characteristics) {
        String name = c.uuid.toString().toUpperCase().substring(4, 8);
        switch (name) {
          case "2A57":
            cLed = c;
            break;
          case "F468":
            cEye = c;
            break;
          case "D297":
            cEyelid = c;
            break;
        }
      }
      return Row(children: [
        const SizedBox(width: 50),
        Column(
          children: [
            const SizedBox(height: 60),
            GestureDetector(
              onPanUpdate: (details) async {
                var pos = details.localPosition;
                double fixedX = _fixPosition(pos.dx);
                double fixedY = _fixPosition(pos.dy);
                _setPosition(fixedX, fixedY);
              },
              onPanEnd: (details) async {
                // x, y それぞれ0~14に変換して合計1byteで送信する。
                // 7が中心とする。
                int dataX = _eyeX * 14 ~/ 200;
                int dataY = _eyeY * 14 ~/ 200;
                if (dataX > 14) {
                  dataX = 14;
                }
                if (dataY > 14) {
                  dataY = 14;
                }
                dataY = 14 - dataY; // canvasのy座標が上下逆なので反転
                final int dataXY = (dataX << 4) | dataY;
                print("dataX " + dataX.toString());
                print("dataY " + dataY.toString());
                print("dataXY " + dataXY.toString());
                try {
                  await cEye!.write([dataXY], withoutResponse: false);
                  await cEye!.read();
                } catch (e) {
                  // ignore failed communication
                }
              },
              child: EyeCanvas(
                painter: EyePainter(eyeX: _eyeX, eyeY: _eyeY),
              ),
            ),
          ],
        ),
        const SizedBox(width: 50),
        TextButton(
          child: const Text("Center"),
          onPressed: () async {
            _setPosition(50, 50);
            final int dataXY = (7 << 4) | 7;
            try {
              await cEye!.write([dataXY], withoutResponse: false);
              await cEye!.read();
            } catch (e) {
              // ignore failed communication
            }
          },
        ),
        const SizedBox(width: 50),
        Column(
          children: [
            const SizedBox(height: 30),
            _buildToggleButton(cEyelid!, _eyelidZito1, "zito lv.1", 2, 0),
            Row(
              children: [
                _buildToggleButton(cEyelid!, _eyelidZito2, "zito lv.2", 3, 0),
                const SizedBox(width: 10),
                Column(
                  children: [
                    TextButton(
                      child: const Text("Open"),
                      onPressed: () => _writeEyelidCommand(cEyelid!, 0),
                    ),
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () => _writeEyelidCommand(cEyelid!, 5),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                _buildToggleButton(cEyelid!, _eyelidNiyake, "niyake", 4, 0),
              ],
            ),
            Row(
              children: [
                _buildToggleButton(cEyelid!, _eyelidMabataki, "blink", 1, 1),
              ],
            ),
          ],
        ),
      ]);
    }
    return ListTile(
      title: const Text('Service'),
      subtitle:
          Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
    );
  }

  void _writeEyelidCommand(BluetoothCharacteristic? c, int id) async {
    if (c != null) {
      try {
        await c.write([id], withoutResponse: false);
        await c.read();
      } catch (e) {
        // ignore communication error
      }
    }
  }

  void _setPosition(double eyeX, double eyeY) {
    setState(() {
      _eyeX = eyeX;
      _eyeY = eyeY;
    });
  }

  double _fixPosition(double pos) {
    double fixed = pos;
    if (pos < 0.0) {
      fixed = 0.0;
    } else if (200.0 < pos) {
      fixed = 200.0;
    }
    return fixed;
  }

  ToggleButtons _buildToggleButton(BluetoothCharacteristic? c,
      List<bool> states, String name, int onCommand, int offCommand) {
    return ToggleButtons(
      isSelected: states,
      children: [
        Text(name),
      ],
      onPressed: (index) {
        setState(() {
          states[index] = !states[index];
        });
        final int id = states[index] ? onCommand : offCommand;
        _writeEyelidCommand(c, id);
      },
    );
  }
}

class EyeCanvas extends StatelessWidget {
  final double _width = 200;
  final double _height = 200;
  final CustomPainter painter;

  const EyeCanvas({Key? key, required this.painter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: CustomPaint(
        painter: painter,
      ),
    );
  }
}

class EyePainter extends CustomPainter {
  final double eyeX;
  final double eyeY;

  const EyePainter({required this.eyeX, required this.eyeY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black12;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = Colors.black;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 5, paint);
    paint.color = Colors.blue;
    canvas.drawCircle(Offset(eyeX, eyeY), 15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDeleate) {
    return true;
  }
}
