import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:umiperer/modals/Match.dart';
import 'package:umiperer/screens/matchDetailsScreens/custom_dialog.dart';
import 'package:umiperer/widgets/over_card.dart';

class CounterPage extends StatefulWidget {
  CounterPage({this.match, this.user});

  final User user;
  final CricketMatch match;

  @override
  _CounterPageState createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {

  int currentOverNo=0;

  final scoreSelectionAreaLength = 220;
  List<Container> balls;
  bool isFirstOverStarted = false;
  String _chosenValue;

  ScrollController _scrollController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _chosenValue=widget.match.team2List[0];
    _scrollController = ScrollController(keepScrollOffset: true);
  }

  @override
  Widget build(BuildContext context) {

    balls = [
      ballWidget(),
      ballWidget(),
      ballWidget(),
      ballWidget(),
      ballWidget(),
      ballWidget(),
    ];

    return Container(
      color: Colors.black12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          miniScoreCard(),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 10),
          //     child: Text(
          //       'OVERS',
          //     ),
          //   ),
          // ),
          //////////////
          buildOversList(),
          Container(
            margin: EdgeInsets.only(top: 3,bottom: 6),
            child: Text(
              'OPTIONS FOR NEXT BALL',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: usersRef.doc(widget.user.uid).collection('createdMatches').doc(widget.match.getMatchId()).snapshots(),
            builder: (context,snapshot){
              if(!snapshot.hasData){
                return loadingDataContainer();
              } else{
                final matchData = snapshot.data.data();
                final currentOver = matchData['currentOverNumber'];

                if(currentOver==0){
                  return startFirstOverBtn();
                } else{
                  return scoreSelectionWidget(playersName: "Pulkit");
                }
              }
            },
          )
          // widget.match.currentOver.getCurrentOverNo()==0?
          // startFirstOverBtn():
          // scoreSelectionWidget()
        ],
      ),
    );
  }

  buildOversList(){

    int inningNo = widget.match.getInningNo();
    int currentBallOfThisOver=0;
    int currentOver;

    return StreamBuilder<QuerySnapshot>(
      stream: usersRef.doc(widget.user.uid).collection('createdMatches').doc(widget.match.getMatchId())
          .collection('inning${inningNo}over').snapshots(),

      builder: (context,snapshot){
        if(!snapshot.hasData){

          return CircularProgressIndicator();
        }
        else{

          final oversData = snapshot.data.docs;

          oversData.forEach((over) {
              if(over.data()['overNo']==currentOverNo){
                currentBallOfThisOver = over.data()['currentBall'];
                currentOver=over.data()['overNo'];
              }
          });
          return Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.match.getOverCount(),
              itemBuilder: (BuildContext context, int index) =>
                  overCard(overNo: (index + 1),currentBallNo: currentBallOfThisOver,currentOver: currentOver),
            ),
          );
        }
      },

    );
  }

  ///dialog to choose next over players
  newOverPlayersSelectionDialog(){
    return showDialog(
      context: context,
      builder: (BuildContext context) => CustomDialog(
        match: widget.match,
        user: widget.user,

        //TODO: animation of horizontal list view
        //PROBLEM: first over me bhi animate hori h
        // scrollListAnimationFunction: (){
        //   if (_scrollController.hasClients && widget.match.currentOver!=1){
        //     double offset = _scrollController.offset + 300;
        //     _scrollController.animateTo(offset, duration: Duration(seconds: 1), curve: Curves.fastOutSlowIn);
        //     // _scrollController.jumpTo(300.0);
        //   }
        // },
      ),
    );
  }

  ///custom Circular Progess Indicator
  loadingDataContainer(){
    return Container(
      width: double.infinity,
      height: scoreSelectionAreaLength.toDouble(),
      color: Colors.white,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  ///only visible when starting first over to make UI intiative
  startFirstOverBtn(){
    return Container(
      width: double.infinity,
      height: scoreSelectionAreaLength.toDouble(),
      color: Colors.white,
      child: Container(
        child: FlatButton(
          onPressed: (){
            newOverPlayersSelectionDialog();
          },
          child: Text("START FIRST OVER"),
        ),
      ),
    );
  }

  ///stream-builder making batsmen score card
  playersScore() {

    String batsmen1name = "----------";
    int batsmen1Run = 0;
    int batsmen1Balls =0;
    int batsmen1Fours = 0;
    int batsmen1Sixes = 0;
    int batsmen1SR = 0;
    try{
      batsmen1SR = (batsmen1Run/batsmen1Sixes).roundToDouble().toInt();
    } catch(e){
      batsmen1SR = 0;
    }

    String batsmen2name = "----------";
    int batsmen2Run = 0;
    int batsmen2Balls =0;
    int batsmen2Fours = 0;
    int batsmen2Sixes = 0;
    int batsmen2SR = 0;

    try{
      batsmen2SR = (batsmen1Run/batsmen1Sixes).roundToDouble().toInt();
    } catch(e){
      batsmen2SR = 0;
    }

    final TextStyle textStyle = TextStyle(color: Colors.black54);
    return StreamBuilder<QuerySnapshot>(

      stream: usersRef.doc(widget.user.uid).collection('createdMatches').doc(widget.match.getMatchId()).
              collection('firstInning').doc("BattingTeam").collection('Players').
              where('isBatting',isEqualTo: true,).snapshots(),
      builder: (context,snapshot){

        if(!snapshot.hasData){
          return Center(
            child: CircularProgressIndicator(),
          );
        } else{
          final playersData = snapshot.data.docs;

          playersData.forEach((element) {

            if(element.data()['isOnStrike']){
              batsmen1name = element.data()['name'];
              batsmen1Run = element.data()['runs'];
              batsmen1Fours = element.data()['noOf4s'];
              batsmen1Sixes = element.data()['noOf6s'];
              batsmen1Balls = element.data()['balls'];
            } else{
              batsmen2name = element.data()['name'];
              batsmen2Run = element.data()['runs'];
              batsmen2Fours = element.data()['noOf4s'];
              batsmen2Sixes = element.data()['noOf6s'];
              batsmen2Balls = element.data()['balls'];
            }
          });

          return Container(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: 120,
                        child: Text(
                          "Batsman",
                          style: textStyle,
                        )),
                    Container(
                        width: 30,
                        child: Text(
                          "R",
                          style: textStyle,
                        )),
                    Container(
                        width: 30,
                        child: Text(
                          "B",
                          style: textStyle,
                        )),
                    Container(
                        width: 30,
                        child: Text(
                          "4s",
                          style: textStyle,
                        )),
                    Container(
                        width: 30,
                        child: Text(
                          "6s",
                          style: textStyle,
                        )),
                    Container(
                        width: 30,
                        child: Text(
                          "SR",
                          style: textStyle,
                        )),
                  ],
                ),
                SizedBox(height: 4,),

                //Batsman's data
                batsmanScoreRow(
                    playerName: batsmen1name,
                    runs: batsmen1Run.toString(),
                    balls: batsmen1Balls.toString(),
                    noOf4s: batsmen1Fours.toString(),
                    noOf6s: batsmen1Sixes.toString(),
                    SR: batsmen1SR.toString(),
                ),
                SizedBox(height: 4,),
                batsmanScoreRow(
                  playerName: batsmen2name,
                  runs: batsmen2Run.toString(),
                  balls: batsmen2Balls.toString(),
                  noOf4s: batsmen2Fours.toString(),
                  noOf6s: batsmen2Sixes.toString(),
                  SR: batsmen2SR.toString(),
                ),

                //Line
                Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  color: Colors.black12,
                  height: 2,
                ),
                SizedBox(height: 4,),
                //Bowler's Data
                bowlerStatsRow(
                    runs: "R",
                    playerName: "Bowler",
                    economy: "ER",
                    median: "M",
                    overs: "O",
                    wickets: "W",
                    textStyle: textStyle),
                SizedBox(height: 4,),
                StreamBuilder<QuerySnapshot>(
                  stream: usersRef.doc(widget.user.uid).collection('createdMatches').doc(widget.match.getMatchId()).
                  collection('firstInning').doc("BowlingTeam").collection('Players').
                  where('isBowling',isEqualTo: true,).snapshots(),
                  builder: (context,snapshot){

                    if(!snapshot.hasData){
                      return CircularProgressIndicator();
                    } else{

                      final bowlingTeam = snapshot.data.docs;

                      String bowlersName = "----------";
                      int oversBowled = 0;
                      int maidainOvers = 0;
                      int runsGiven =0;
                      int wicketsTaken = 0;
                      int ER = 0;

                      try{
                        ER = (runsGiven/oversBowled).roundToDouble().toInt();
                      } catch(e){
                        ER = 0;
                      }

                      bowlingTeam.forEach((playerDoc) {

                        bowlersName = playerDoc.data()['name'];
                        oversBowled = playerDoc.data()['overs'];
                        runsGiven = playerDoc.data()['runs'];
                        wicketsTaken = playerDoc.data()['wickets'];
                        maidainOvers = playerDoc.data()['maidans'];

                      });

                      return bowlerStatsRow(
                          runs: runsGiven.toString(),
                          playerName: bowlersName,
                          economy: ER.toString(),
                          median: maidainOvers.toString(),
                          overs: oversBowled.toString(),
                          wickets: wicketsTaken.toString(),
                          textStyle: textStyle.copyWith(color: Colors.black));
                    }
                  },
                ),

              ],
            ),
          );
        }

      },

    );
  }

  ///the function associated with run buttons,
  ///this will be called when normal runs are scores.
  updateRuns({String playerName, int runs}){

    //update players runs in collection named after player inside TEAM>BATSMEN>PLAYERSNAME
    //
    print("Player $playerName scores $runs");

  }

  ///this is placed at the bottom, contains many run buttons
  scoreSelectionWidget({String playersName}){

    final double buttonWidth = 60;
    final btnColor = Colors.black12;
    final spaceBtwn = SizedBox(width: 4,);

    return Container(
      height: scoreSelectionAreaLength.toDouble(),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ///row one [0,1,2,3,4]
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlatButton(
                  color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: "RAJU", runs: 0);},
                    child: Text("0")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: playersName, runs: 1);},
                    child: Text("1")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: playersName, runs: 2);},
                    child: Text("2")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: playersName, runs: 3);},
                    child: Text("3")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: playersName, runs: 4);},
                    child: Text("4")),
              ],
            ),
            ///row 2 [6,Wide,LB,Out,NB]
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: playersName, runs: 6);},
                    child: Text("6")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    onPressed: (){updateRuns(playerName: playersName, runs: 0);},
                    child: Text("Wide")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    //TODO: legBye runs need to updated [open new run set]
                    onPressed: (){updateRuns(playerName: playersName, runs: 0);},
                    child: Text("LB")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    //TODO: no-ball -- open new no-ball set
                    onPressed: (){updateRuns(playerName: playersName, runs: 1);},
                    child: Text("NB")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    //TODO: out btn clicked
                    onPressed: (){updateRuns(playerName: playersName, runs: 0);},
                    child: Text("Out")),
              ],
            ),
            ///row 3 [over throw, overEnd,]
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    //TODO: over throw
                    onPressed: (){updateRuns(playerName: playersName, runs: 0);},
                    child: Text("Over Throw")),
                spaceBtwn,
                FlatButton(
                    color: btnColor,
                    minWidth: buttonWidth,
                    //TODO: start new over
                    onPressed: (){

                      newOverPlayersSelectionDialog();

                      // updateRuns(playerName: playersName, runs: 0);

                      },
                    child: Text("Start new over")),

              ],
            ),
          ],
        ),
      ),
    );
  }

  ///over container with 6balls
  ///we will increase no of balls in specific cases
  ///TODO: increase no of balls...in the lower section
  overCard({int overNo,int currentBallNo,int currentOver})
  //String bowlerName,String batsman1Name,String batsman2Name
  {
    if(overNo==currentOver) {
      balls[currentBallNo] =
          ballWidget(isCurrentBall: true, isThisCurrentOver: true);
    }
    return Container(
      // padding: EdgeInsets.symmetric(horizontal: 10),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), color: Colors.white),
      height: 60,
      // color: Colors.black26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 8,
              top: 8,
            ),
            child: Text("OVER NO: $overNo"),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 4,horizontal: 4),
            child: Row(
              children: balls,
            ),
          ),
        ],
      ),
    );
  }

  ///not in use currently
  bowlerWidget() {
    return Container(
        decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4)),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text("Bowler: Bumrah 🏐"));
  }

  ///not in use currently
  batsmanWidget({String batsmanName, bool isOnStrike}){
    return Container(
        decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4)),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child:
        isOnStrike?
        Text("$batsmanName 🏏"):
        Text("$batsmanName"),
    );
  }

  ///circleBall widget placed inside Over container
  ballWidget({bool isCurrentBall=false, bool isThisCurrentOver=false}) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: isCurrentBall? Colors.blue.shade600:Colors.blue.shade100,
        ));
  }

  ///toss result line at the top
  ///TODO: might change its position
  tossLineWidget() {
    return Container(
        padding: EdgeInsets.only(left: 12, top: 12),
        child: Text(
            "${widget.match.getTossWinner()} won the toss and choose to ${widget.match.getChoosedOption()}"));
  }

  ///not in use currently
  oversContainer() {
    return ListView(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      children: [
        OverCard(
          user: widget.user,
          match: widget.match,
          currentOverNumber: 1,
        ),
        OverCard(
          user: widget.user,
          match: widget.match,
          currentOverNumber: 1,
        ),
        OverCard(
          user: widget.user,
          match: widget.match,
          currentOverNumber: 1,
        ),
        OverCard(
          user: widget.user,
          match: widget.match,
          currentOverNumber: 1,
        ),
        OverCard(
          user: widget.user,
          match: widget.match,
          currentOverNumber: 1,
        ),
      ],
    );
  }

  ///upper scorecard
  miniScoreCard() {
    return Column(
      children: [
        tossLineWidget(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: usersRef.doc(widget.user.uid).collection('createdMatches').doc(widget.match.getMatchId()).snapshots(),
            builder: (context,snapshot){

              if(!snapshot.hasData){
                return CircularProgressIndicator();
              }
              else{

                final inningData = snapshot.data.data();

                final totalRuns = inningData['totalRuns'];
                final currentOverNumber = inningData['currentOverNumber'];
                currentOverNo = currentOverNumber;
                final currentBattingTeam =inningData['currentBattingTeam'];
                final wicketsDownOfInning1 = inningData['wicketsDownOfInning1'];

                double CRR = 0;

                if(currentOverNumber!=0){
                  CRR=(totalRuns/currentOverNumber);
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentBattingTeam.toString().toUpperCase(),
                              style: TextStyle(fontSize: 24),
                            ),
                            Text(
                              "$totalRuns-$wicketsDownOfInning1 ($currentOverNumber)",
                              style: TextStyle(fontSize: 16),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            Text("CRR"),
                            Text(CRR.toStringAsFixed(2)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      color: Colors.black12,
                      height: 2,
                    ),
                    playersScore(),
                  ],
                );
              }

            },

          ),
        ),
      ],
    );
  }

  final TextStyle textStyle = TextStyle(color: Colors.black);

  batsmanScoreRow(
      {String playerName,
      String runs,
      String balls,
      String noOf4s,
      String noOf6s,
      String SR}) {
    final TextStyle textStyle = TextStyle(color: Colors.black);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 120,
          child: Text(
            playerName,
            style: textStyle,
            maxLines: 2,
          ),
        ),
        Container(
            width: 30,
            child: Text(
              runs,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              balls,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              noOf4s,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              noOf6s,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              SR,
              style: textStyle,
            )),
      ],
    );
  }

  bowlerStatsRow(
      {String playerName,
      String overs,
      String median,
      String runs,
      String wickets,
      String economy,
      TextStyle textStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 120,
          child: Text(
            playerName,
            style: textStyle,
            maxLines: 2,
          ),
        ),
        Container(
            width: 30,
            child: Text(
              overs,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              median,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              runs,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              wickets,
              style: textStyle,
            )),
        Container(
            width: 30,
            child: Text(
              economy,
              style: textStyle,
            )),
      ],
    );
  }

  addNewOverButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      height: 100,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          IconButton(
            iconSize: 50,
            padding: EdgeInsets.zero,
            onPressed: () {
              print("AAAAAAAAAAAAAAAA");
            },
            icon: Icon(Icons.add),
          ),
          Text("Add new over")
        ],
      ),
    );
  }

}
