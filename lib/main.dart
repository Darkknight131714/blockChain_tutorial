import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

late Client httpClient;

late Web3Client ethClient;

//Ethereum address
final String myAddress = "0xF2D5a6d399DFa94e29443E214e297047D48b2825";

//url from Infura
final String blockchainUrl =
    "https://rinkeby.infura.io/v3/c8012b384cd44a69b24733d011968d07";

//strore the value of alpha and beta
var totalVotesA;
var totalVotesB;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? timer;
  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchainUrl, httpClient);
    timer = Timer.periodic(Duration(seconds: 5), (v) {
      getTotalVotes();
    });
    getTotalVotes();
    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  Future<DeployedContract> getContract() async {
    String abiFile = await rootBundle.loadString("assets/contract.json");

    String contractAddress = "0x0C22Cc06443A1EFf92549199c8BC5CBF84b56f1F";

    final contract = DeployedContract(
      ContractAbi.fromJson(abiFile, "Voting"),
      EthereumAddress.fromHex(contractAddress),
    );

    return contract;
  }

  Future<List<dynamic>> callFunction(String name) async {
    final contract = await getContract();
    final function = contract.function(name);
    final result = await ethClient
        .call(contract: contract, function: function, params: []);
    return result;
  }

  Future<void> getTotalVotes() async {
    List<dynamic> resultsA = await callFunction("getTotalVotesAlpha");
    List<dynamic> resultsB = await callFunction("getTotalVotesBeta");
    totalVotesA = resultsA[0];
    totalVotesB = resultsB[0];

    setState(() {});
  }

  Future<void> vote(bool voteAlpha) async {
    //obtain private key for write operation
    Credentials key = EthPrivateKey.fromHex(
        "e2b2b3b66cbdd5d8b22c2aaf3077843e295a0d301ed7397790a1ca962125346f");

    //obtain our contract from abi in json file
    final contract = await getContract();

    // extract function from json file
    final function = contract.function(
      voteAlpha ? "voteAlpha" : "voteBeta",
    );

    //send transaction using the our private key, function and contract
    await ethClient.sendTransaction(
        key,
        Transaction.callContract(
            contract: contract, function: function, parameters: []),
        chainId: 4);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Casting your vote. Please dont turn off the device"),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BlockChain"),
      ),
      body: Column(
        children: [
          Card(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text("Life"),
                        Text(totalVotesA != null
                            ? "Total Votes: $totalVotesA"
                            : "Fetching Data"),
                      ],
                    ),
                    Column(
                      children: [
                        Text("Death"),
                        Text(totalVotesB != null
                            ? "Total Votes: $totalVotesB"
                            : "Fetching Data"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await vote(true);
                },
                child: Text("Vote Life"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await vote(false);
                },
                child: Text("Vote Death"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
