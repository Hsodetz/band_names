import 'dart:io';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: '1', name: 'Metallica', votes: 5 ),
    // Band(id: '2', name: 'Queen', votes: 1 ),
    // Band(id: '3', name: 'Héroes del Silencio', votes: 2 ),
    // Band(id: '4', name: 'Bon Jovi', votes: 5 ),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);
    
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List)
        .map( (band) => Band.fromMap(band) )
        .toList();

    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BandNames', style: TextStyle( color: Colors.black87 ) ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child:
              socketService.serverStatus == ServerStatus.online ?
              Icon(Icons.check_circle_outline, color: Colors.blue[300],) :
              const Icon(Icons.offline_bolt, color: Colors.red,)

          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, index) => _bandTile(bands[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        onPressed: () {
          addNewBand();
        },
        child: const Icon( Icons.add ),
      ),
    );
  }

  Widget _bandTile( Band band ) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: ( direction ) {
        print('direction: $direction');
        print('id: ${ band.id }');
        // llamar el borrado en el server
        socketService.socket.emit('delete-band', {'id': band.id});
      },
      background: Container(
        padding: const EdgeInsets.only( left: 8.0 ),
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle( color: Colors.white) ),
        )
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text( band.name.substring(0,2) ),
        ),
        title: Text( band.name ),
        trailing: Text('${ band.votes }', style: const TextStyle( fontSize: 20) ),
        onTap: () {
          print(band.name);
          print(band.id);

          socketService.socket.emit('vote-band', {'id': band.id});

        },
      ),
    );
  }

   addNewBand() {

    final textController = TextEditingController();
    
    if ( Platform.isAndroid ) {
      // Android
      return showDialog(
        context: context,
        builder: ( context ) {
          return AlertDialog(
            title: const Text('New band name:'),
            content: TextField(
              controller: textController,
            ),
            actions: <Widget>[
              MaterialButton(
                elevation: 5,
                textColor: Colors.blue,
                onPressed: () => addBandToList( textController.text ),
                child: const Text('Add'),
              )
            ],
          );
        },
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: ( _ ) {
        return CupertinoAlertDialog(
          title: const Text('New band name:'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add'),
              onPressed: () => addBandToList( textController.text )
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Dismiss'),
              onPressed: () => Navigator.pop(context)
            )
          ],
        );
      }
    );

  }

  void addBandToList( String name ) {
    print(name);

    if ( name.length > 1 ) {
      // Podemos agregar
      // bands.add( Band(id: DateTime.now().toString(), name: name, votes: 0 ) );
      // setState(() {});

      // ahora usando los sockets
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': name});
      
      
    }


    Navigator.pop(context);

  }

  Widget _showGraph() {
    Map<String, double> dataMap = {};

    bands.forEach((band) { 
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: PieChart(dataMap: dataMap)
    );
  }
}