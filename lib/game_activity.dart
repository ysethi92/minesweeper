import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minesweeper/board.dart';

// Image Types
enum Images {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  mine,
  down,
  flagged,
}

class GameActivity extends StatefulWidget {
  @override
  _GameActivityState createState() => _GameActivityState();
}

class _GameActivityState extends State<GameActivity> {
  // Row and column count of the board
  int rowCount = 18;
  int columnCount = 10;

  List<List<Board>> board;

  List<bool> openedSquares;

  List<bool> flaggedSquares;

  int bombProb = 3;
  int maxProb = 15;

  int bombCount = 0;
  int squaresRemaining;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Container(
            color: Colors.white,
            height: 60.0,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    _initialise();
                  },
                  child: CircleAvatar(
                    child: Icon(
                      Icons.tag_faces,
                      color: Colors.black,
                      size: 42.0,
                    ),
                    backgroundColor: Colors.yellowAccent,
                  ),
                )
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
            ),
            itemBuilder: (context, position) {
              // Get row and column number of square
              int rowNumber = (position / columnCount).floor();
              int columnNumber = (position % columnCount);

              Image image;

              if (openedSquares[position] == false) {
                if (flaggedSquares[position] == true) {
                  image = getImage(Images.flagged);
                } else {
                  image = getImage(Images.down);
                }
              } else {
                if (board[rowNumber][columnNumber].hasBomb) {
                  image = getImage(Images.mine);
                } else {
                  image = getImage(
                    getImageFromNumber(
                        board[rowNumber][columnNumber].surroundedByBombs),
                  );
                }
              }

              return InkWell(
                // Opens square
                onTap: () {
                  if (board[rowNumber][columnNumber].hasBomb) {
                    gameOver();
                  }
                  if (board[rowNumber][columnNumber].surroundedByBombs == 0) {
                    _handleTap(rowNumber, columnNumber);
                  } else {
                    setState(() {
                      openedSquares[position] = true;
                      squaresRemaining = squaresRemaining - 1;
                    });
                  }

                  if (squaresRemaining <= bombCount) {
                    win();
                  }
                },
                // Flags square
                onLongPress: () {
                  if (openedSquares[position] == false) {
                    setState(() {
                      flaggedSquares[position] = true;
                    });
                  } else {
                    setState(() {
                      flaggedSquares[position] = false;
                    });
                  }
                },
                splashColor: Colors.grey,
                child: Container(
                  color: Colors.grey,
                  child: image,
                ),
              );
            },
            itemCount: rowCount * columnCount,
          ),
        ],
      ),
    );
  }

  // Initialises all lists
  void _initialise() {
    // Initialise all squares to having no bombs
    board = List.generate(rowCount, (i) {
      return List.generate(columnCount, (j) {
        return Board();
      });
    });

    // Initialise list to store which squares have been opened
    openedSquares = List.generate(rowCount * columnCount, (i) {
      return false;
    });

    flaggedSquares = List.generate(rowCount * columnCount, (i) {
      return false;
    });

    // Resets bomb count
    bombCount = 0;
    squaresRemaining = rowCount * columnCount;

    // Randomly generate bombs
    Random random = new Random();
    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        int randomNumber = random.nextInt(maxProb);
        if (randomNumber < bombProb) {
          board[i][j].hasBomb = true;
          bombCount++;
        }
      }
    }

    // Assigning numbers based on the number of mines around a cell.
    for (int i = 0; i < rowCount; i++) {
      for (int j = 0; j < columnCount; j++) {
        if (i > 0 && j > 0) {
          if (board[i - 1][j - 1].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (i > 0) {
          if (board[i - 1][j].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (i > 0 && j < columnCount - 1) {
          if (board[i - 1][j + 1].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (j > 0) {
          if (board[i][j - 1].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (j < columnCount - 1) {
          if (board[i][j + 1].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (i < rowCount - 1 && j > 0) {
          if (board[i + 1][j - 1].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (i < rowCount - 1) {
          if (board[i + 1][j].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }

        if (i < rowCount - 1 && j < columnCount - 1) {
          if (board[i + 1][j + 1].hasBomb) {
            board[i][j].surroundedByBombs++;
          }
        }
      }
    }

    setState(() {});
  }

  // recursive function
  void _handleTap(int i, int j) {
    int position = (i * columnCount) + j;
    openedSquares[position] = true;
    squaresRemaining = squaresRemaining - 1;

    if (i > 0) {
      if (!board[i - 1][j].hasBomb &&
          openedSquares[((i - 1) * columnCount) + j] != true) {
        if (board[i][j].surroundedByBombs == 0) {
          _handleTap(i - 1, j);
        }
      }
    }

    if (j > 0) {
      if (!board[i][j - 1].hasBomb &&
          openedSquares[(i * columnCount) + j - 1] != true) {
        if (board[i][j].surroundedByBombs == 0) {
          _handleTap(i, j - 1);
        }
      }
    }

    if (i < rowCount - 1) {
      if (!board[i + 1][j].hasBomb &&
          openedSquares[((i + 1) * columnCount) + j] != true) {
        if (board[i][j].surroundedByBombs == 0) {
          _handleTap(i + 1, j);
        }
      }
    }

    if (j < columnCount - 1) {
      if (!board[i][j + 1].hasBomb &&
          openedSquares[(i * columnCount) + j + 1] != true) {
        if (board[i][j].surroundedByBombs == 0) {
          _handleTap(i, j + 1);
        }
      }
    }

    setState(() {});
  }

  void win() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations!"),
          content: Text("Woww!! You Win!"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                _initialise();
                Navigator.pop(context);
              },
              child: Text("Play again"),
            ),
          ],
        );
      },
    );
  }

  void gameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Game Over!"),
          content: Text("Oops!! You stepped on a mine!"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                _initialise();
                Navigator.pop(context);
              },
              child: Text("Play again"),
            ),
          ],
        );
      },
    );
  }

  Image getImage(Images type) {
    switch (type) {
      case Images.zero:
        return Image.asset('images/0.png');
      case Images.one:
        return Image.asset('images/1.png');
      case Images.two:
        return Image.asset('images/2.png');
      case Images.three:
        return Image.asset('images/3.png');
      case Images.four:
        return Image.asset('images/4.png');
      case Images.five:
        return Image.asset('images/5.png');
      case Images.six:
        return Image.asset('images/6.png');
      case Images.seven:
        return Image.asset('images/7.png');
      case Images.eight:
        return Image.asset('images/8.png');
      case Images.mine:
        return Image.asset('images/mine.png');
      case Images.down:
        return Image.asset('images/down.png');
      case Images.flagged:
        return Image.asset('images/flag.png');
      default:
        return null;
    }
  }

  Images getImageFromNumber(int number) {
    switch (number) {
      case 0:
        return Images.zero;
      case 1:
        return Images.one;
      case 2:
        return Images.two;
      case 3:
        return Images.three;
      case 4:
        return Images.four;
      case 5:
        return Images.five;
      case 6:
        return Images.six;
      case 7:
        return Images.seven;
      case 8:
        return Images.eight;
      default:
        return null;
    }
  }
}
