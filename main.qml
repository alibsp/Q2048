import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.1
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Universal 2.12
import QtMultimedia 5.12
ApplicationWindow{
    visible: true
    Material.theme: Material.Accent
    Material.accent: Material.Purple

    width: 480
    height: 640
    //minimumHeight: height;
    //minimumWidth: width;
    //maximumHeight: height;
    //maximumWidth: width;
    title: qsTr("Q2048")
    color: "#fbf8ef";

    Settings {
        id: settigns;
        property alias columns: app.colCount;
        property alias rows: app.rowCount;
        property alias bestScore: app.bestScore;
    }
    id: app
    property var table: []
    property int rowCount : 4
    property int colCount : 4
    property real score : 0
    property int bestScore

    property var moving : false

    property var mm:Screen.pixelDensity

    property var cellWidth: (Math.min(width, (height-scoreBoard.height)))/colCount*.7
    property var cells : []
    property var blocks : []

    property var showLogs: true
    property var mute: false
    property var highSpeedAI: false
    property var searchDepth: 5

    property var numbers : [];

    ColumnLayout
    {
        anchors.fill: parent
        RowLayout
        {
            id:scoreBoard
            Layout.maximumWidth: grid.width
            Layout.margins: 5*mm
            Layout.alignment: Qt.AlignHCenter
            Text
            {
                Layout.alignment: Qt.AlignLeft
                color: "#766d65"
                text: qsTr("2048")
                font.family: "Verdana"
                font.bold: true
                font.pixelSize: 40
            }
            Item
            {
                Layout.fillWidth: true
            }

            ColumnLayout
            {
                Rectangle
                {
                    Layout.preferredWidth:30*mm
                    height: 48
                    color: "#bcada0"
                    radius: 3

                    ColumnLayout
                    {
                        anchors.centerIn: parent
                        Text {
                            color: "#f2e7d9"
                            text: qsTr("SCORE")
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 3*mm
                        }

                        Text {
                            color: "#ffffff"
                            text: app.score
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "Verdana"
                            font.bold: true
                            font.pixelSize: 5*mm
                        }
                    }
                }
                Button
                {
                    Layout.preferredWidth:30*mm
                    text: qsTr("Options")
                    onClicked:
                    {
                        rowCount = colCount = 4;
                        init();
                        itmKeys.forceActiveFocus();
                    }
                }
            }
            ColumnLayout
            {
                Rectangle
                {
                    Layout.preferredWidth:30*mm
                    height: 48
                    color: "#bcada0"
                    radius: 3
                    ColumnLayout
                    {
                        anchors.centerIn: parent
                        Text {
                            color: "#f2e7d9"
                            text: qsTr("BEST")
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 3*mm
                        }

                        Text {
                            color: "#ffffff"
                            text: app.bestScore
                            Layout.alignment: Qt.AlignHCenter
                            font.family: "Verdana"
                            font.bold: true
                            font.pixelSize: 5*mm
                        }
                    }
                }
                Button
                {
                    Layout.preferredWidth:30*mm
                    text: qsTr("New Game")
                    onClicked:
                    {
                        newGame();
                        itmKeys.forceActiveFocus();
                    }
                }
            }
        }

        Rectangle
        {
            id: item
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth:  grid.width + radius*4
            Layout.preferredHeight: grid.height + radius*4
            color: "#bbada0"
            radius: 1*mm
            Grid
            {
                anchors.centerIn: parent
                id: grid
                columns: app.colCount
                rows: app.rowCount
                spacing: 2*mm
                Repeater
                {
                    id:rpt
                    model: app.rowCount*app.colCount
                    Rectangle
                    {
                        width: app.cellWidth
                        height: width
                        color: "#ccc0b2"
                        radius: 1*mm
                    }
                    onItemAdded:
                    {
                        if(index==0)
                        {
                            cells = [];
                            for(var i=0;i<rowCount;i++)
                                cells[i] = [];
                        }
                        cells[Math.floor(index/4)][index%4] = item;
                    }
                }
            }

            GameOverWindow
            {
                id: gameOverWindow;
                anchors.fill: parent
                onTryAgainClicked:
                {
                    newGame();
                }
            }
        }
        Item
        {
            Layout.fillHeight: true
        }
    }


    Audio {
        id: audioPlayer
        source: "qrc:/audio/4.mp3"
    }

    Item{
        id: itmKeys
        focus: true
        Keys.onPressed:
        {
            console.log("Keys.onPressed:", event.key);
            if(event.key === Qt.Key_Space)
            {
                /*if(app.highSpeedAI || (!app.highSpeedAI && !moving))
                    nextAI(app.searchDepth);
                if(!app.highSpeedAI)
                    movingTimer.start();
                else
                    onAnimEnd();*/

                if(aiTimer.running)
                    aiTimer.stop();
                else
                    aiTimer.start();
            }
            else if(move(event.key, false))
            {
                movingTimer.start();
            }
            event.accepted = true;
        }
    }
    Timer
    {
        id: movingTimer
        interval: 100; running: false;
        onTriggered:
        {
            onAnimEnd();
        }
    }


    Timer
    {
        id: aiTimer
        interval: highSpeedAI ? 1 : 100
        running: false;
        repeat: true
        onTriggered:
        {
            if(app.highSpeedAI || (!app.highSpeedAI && !moving))
                nextAI(app.searchDepth);
            if(!app.highSpeedAI)
                movingTimer.start();
            else
                onAnimEnd();
            if(gameOverWindow.visible)
                stop();
        }
    }

    Component.onCompleted:
    {
        //console.log("wh:", grid.width, grid.height)
        init();
    }

    function init()
    {
        for(var i=0;i<rowCount;i++)
        {
            table[i] = [];
            if(blocks[i]===undefined)
                blocks[i] = [];
        }
        cleanCells();
        for(i=0;i<rowCount;i++)
            for(var j=0;j<colCount;j++)
                newBlock(i,j, 0, true);
        newGame();
    }

    function newGame()
    {
        app.score=0;
        for(var i=0;i<rowCount;i++)
            for(var j=0;j<colCount;j++)
                blocks[i][j].value=table[i][j]=0;
        randomBlock(false);
        randomBlock(false);
        moving = false;
        gameOverWindow.opacity = 0.0
        gameOverWindow.visible = false;
    }

    function copyMatrix(matrix)
    {
        var copyTable=[];
        for(var i=0;i<matrix.length;i++)
            copyTable[i]=matrix[i].slice();
        return copyTable;
    }


    function nextAI(depth)
    {
        aldaghiMethod(depth)
        //hamedMassafiMethod();
    }
    function aldaghiMethod(depth)
    {
        //printTable();
        var result=thinking(depth);
        var key=result.key;
        var maxScore=result.maxScore;
        console.log("Thinking Finish. MaxScore:",maxScore);
        moving = false;
        move(key, false);
    }
    function hamedMassafiMethod()
    {
        var keys=[Qt.Key_Down, Qt.Key_Right, Qt.Key_Left, Qt.Key_Up];
        for(var k=0;k<keys.length;k++)
        {
            moving = false;
            if(move(keys[k], false))
                break;
        }
    }

    function thinking(depth)
    {
        if(depth===0)
        {
            /* Table Pattern
              3  2  1  0
              4  5  6  7
              11 10 9  8
              12 13 14 15
             */

            var k=0;
            var numbersIndex = [];
            //console.log("---------------");
            //printTable();
            for (var i = 0; i < rowCount; ++i)
                for (var j = 0; j < colCount; ++j)
                {
                    var jj=j;
                    if(i%2===0)
                        jj=3-j;
                    numbersIndex.push([table[i][jj], k++]);
                }

            numbersIndex.sort(function(left, right)
            {
                return left[0] < right[0] ? -1 : 1;
            });
            var indexes = [];
            numbers = [];
            var w=0;
            for (var a in numbersIndex)
            {
                var value = numbersIndex[a][0];
                var position =numbersIndex[a][1];
                if(value> 0)
                {
                    i=Math.floor(a/colCount);
                    j=a%colCount;
                    if(i%2===0)
                        j=3-j;
                    var ii = Math.floor(position/colCount);
                    var jj = position%colCount;
                    if(ii%2===0)
                        jj=3-jj;
                    //w+=Math.abs(ii-i)+Math.abs(jj-j);
                    w+=(9-Math.sqrt(Math.pow(ii-i, 2)+Math.pow(jj-j,2)))*value;
                }
            }
            /*if(w===0)
                w=1;
            else
                w=1/w;*/
            //console.log("w:", w, "score:", score, " final:", score*w, "\n");
            return {"key": 0, "maxScore":w};
        }
        var copyTable=copyMatrix(table);
        var copyScore=score;
        var maxScore=0;
        var keys=[Qt.Key_Down, Qt.Key_Right, Qt.Key_Left, Qt.Key_Up];
        var key=Qt.Key_Left;
        var bestKeys=[];
        for(var k=0;k<keys.length;k++)
        {
            //console.log("Depth:", depth, " Key:", keyName(keys[k]));
            table=copyMatrix(copyTable);
            score = copyScore;
            moving = false;
            if(move(keys[k], true))
            {
                //console.log("Thinking started---------Score:", score,"-----------------------");
                var newValue=randomBlock(true);
                //printTable(newValue);
                //printTable();
                var resutl = thinking(depth-1);
                score = resutl.maxScore;
                //console.log("Thinking finished Depth:",depth," score", score, " MaxScore:", maxScore);
                if(score>maxScore)
                {
                    maxScore = score;
                    bestKeys.push(keys[k]);
                    key = keys[k];
                }
            }
        }
        table=copyMatrix(copyTable);
        //key = bestKeys[Math.floor(Math.random()*bestKeys.length)];
        score = copyScore;
        //return key;
        return {"key": key, "maxScore":maxScore};
    }

    function thinking2(depth)
    {
        if(depth===0)
            return {"key": 0, "maxScore":score};
        var copyTable=copyMatrix(table);
        var copyScore=score;
        var maxScore=0;
        var keys=[Qt.Key_Down, Qt.Key_Right, Qt.Key_Left, Qt.Key_Up];
        var key=Qt.Key_Left;
        var bestKeys=[];
        for(var k=0;k<keys.length;k++)
        {
            console.log("Thinking... Depth:", depth, " Key:", keyName(keys[k]));
            table=copyMatrix(copyTable);
            score = copyScore;
            moving = false;
            if(move(keys[k], true))
            {
                //randomBlock(true);
                var emptyCells=[];
                var value=0;
                for(var i=0;i<rowCount;i++)
                    for(var j=0;j<colCount;j++)
                        if(!table[i][j])
                        {
                            console.log("--------------------------------");
                            table[i][j] = 2;
                            var newValue={"i":i, "j":j, "value":2};
                            printTable(newValue);
                            var resutl = thinking(depth-1);
                            table[i][j] = 0;
                            score = resutl.maxScore;
                            if(score>=maxScore)
                            {
                                maxScore = score;
                                bestKeys.push(keys[k]);
                                key = keys[k];
                            }
                        }
            }
        }
        table=copyMatrix(copyTable);
        //key = bestKeys[Math.floor(Math.random()*bestKeys.length)];
        score = copyScore;
        //return key;
        return {"key": key, "maxScore":maxScore};
    }

    function keyName(value)
    {
        //var keysName={"???" : Qt.Key_Left, "???" : Qt.Key_Right , "???" : Qt.Key_Up , "???" : Qt.Key_Down };
        var keysName={"Left" : Qt.Key_Left, "Right" : Qt.Key_Right , "Up" : Qt.Key_Up , "Down" : Qt.Key_Down };
        return Object.keys(keysName).find(key => keysName[key] === value);
    }

    function printKey(value)
    {
        if(app.showLogs)
            console.log("key:", keyName(value), "- Score:", score);
    }


    function randomBlock(AImode)
    {
        var emptyCells=[];
        var value=0;
        for(var i=0;i<rowCount;i++)
            for(var j=0;j<colCount;j++)
                if(!table[i][j])
                    emptyCells.push(i*colCount+j);
        if(emptyCells.length)
        {
            var k = Math.floor(Math.random()*emptyCells.length);
            //value=Math.random() < 0.9 ? 2 : 4;
            value=2;
            i = Math.floor(emptyCells[k]/colCount);
            j = emptyCells[k]%colCount;
            table[i][j] = value;
            if(!AImode)
                newBlock(i, j, value, false);
        }
        if (emptyCells.length <= 1)
            if (!isNextStep() && !AImode)
            {
                gameOver();
                return {"i":-1, "j":-1, "value":value}
            }
        return {"i":i, "j":j, "value":value}
    }


    function isNextStep()
    {
        for (var i = 0; i < rowCount; ++i)
            for (var j = 0; j < colCount - 1; ++j)
                if (table[i][j] === table[i][j+1])
                    return true;

        for (i = 0; i < rowCount - 1; ++i)
            for (j = 0; j < colCount; ++j)
                if (table[i][j] === table[i+1][j])
                    return true;

        return false;
    }

    function newBlock(i, j, value, canCreate)
    {
        var block;
        if(canCreate)
            block = Qt.createQmlObject("import QtQuick 2.14;Block{}", grid);
        else
            block = blocks[i][j] ;
        block.value=value;

        block.animResizeEnable = canCreate;
        block.animMoveEnable = false;
        var cell = cells[i][j];
        block.x = Qt.binding(function() { return cell.x });
        block.y = Qt.binding(function() { return cell.y });

        block.radius = cells[i][j].radius;
        if(table[i][j]===0)
            block.width = 0;
        else
            block.width = Qt.binding(function() { return cell.width });
        blocks[i][j] = block;
    }

    function move(direction, AImode)
    {
        var lastScore=score;
        numbers = [];
        if(!AImode)
            if(moving)
                return !moving;
        if (direction === Qt.Key_Left || direction=== Qt.Key_Up)
            for (var i = 0; i < rowCount; ++i)
                for (var j = 0; j < colCount; ++j)
                    for (var f = j+1; f < rowCount; ++f )
                        if (direction === Qt.Key_Left)
                        {
                            if (!moveObj(i, f, i, j, AImode))
                                break;
                        } else {
                            if(!moveObj(f, i, j, i, AImode))
                                break;
                        }

        if (direction === Qt.Key_Right || direction === Qt.Key_Down)
            for (i = 0; i < rowCount; ++i)
                for (j = colCount - 1; j >= 0; --j)
                    for (f = j-1; f >= 0; --f )
                        if (direction === Qt.Key_Right)
                        {
                            if (!moveObj(i, f, i, j, AImode))
                                break;
                        } else {
                            if (!moveObj(f, i, j, i, AImode))
                                break;
                        }
        if(!AImode)
        {
            if(!app.mute)
            {
                audioPlayer.stop();
                var newScore=score - lastScore;
                var value = Math.pow(2, Math.floor(Math.log(newScore)/Math.log(2)));
                value = value>2048 ? 2048 :value;
                console.log(newScore, value );
                audioPlayer.source = "qrc:/audio/"+value+".mp3"
                audioPlayer.play();
            }
            printKey(direction);
        }
        return moving;
    }

    function moveObj(row, col, row2, col2, AImode)
    {
        var cell1 = table[row][col];
        var cell2 = table[row2][col2];
        numbers[row*colCount+col] = table[row][col] ;
        numbers[row2*colCount+col2] = table[row2][col2] ;

        if ((cell1 !== 0 && cell2 !== 0) && cell1 !== cell2)
            return false;

        if(!AImode)
            blocks[row][col].animMoveEnable = true;

        if ( (cell1 !== 0 && cell1 === cell2) ||
                (cell1 !== 0 && cell2 === 0) )
        {
            table[row][col] = 0;
            numbers[row*colCount+col] = 0;
            if(!AImode)
            {
                blocks[row][col].x = cells[row2][col2].x;
                blocks[row][col].y = cells[row2][col2].y;
            }
            moving = true;
        }

        if (cell1 !== 0 && cell1 === cell2)
        {
            table[row2][col2] *= 2;
            numbers[row2*colCount+col2] = table[row2][col2] ;
            app.score += table[row2][col2];
            if(!AImode)
                app.bestScore = Math.max(app.bestScore, app.score);
            return false;
        }

        if (cell1 !== 0 && cell2 === 0)
        {
            table[row2][col2] = cell1;
            numbers[row2*colCount+col2] = table[row2][col2] ;
            return true;
        }
        return true;
    }

    function cleanCells()
    {
        for(var i=0;i<rowCount;i++)
            for(var j=0;j<colCount;j++)
            {
                if(blocks[i][j])
                    blocks[i][j].destroy();
                blocks[i][j] = 0;
            }
    }

    function printTable(newValue)
    {
        if(app.showLogs)
            for (var i = 0; i < rowCount; ++i)
            {
                var log="";
                for (var j = 0; j < colCount; ++j)
                {
                    if(newValue!==undefined && newValue.i===i && newValue.j===j)
                        log+=" "+("("+table[i][j]+")").toString().padStart(4, " ");
                    else
                        log+=" "+table[i][j].toString().padStart(4, " ");
                }
                console.log(log);
            }
    }

    function onAnimEnd()
    {
        for (var i = 0; i < rowCount; ++i)
            for (var j = 0; j < colCount; ++j)
                newBlock(i, j, table[i][j], false);

        moving = false;
        var newValue=randomBlock(false);
        printTable(newValue);
    }
    function gameOver()
    {
        moving = true;
        bestScore = Math.max(score, bestScore);
        gameOverWindow.visible = true;
        gameOverWindow.animateOpacity.start();
        audioPlayer.stop();
        audioPlayer.source = "qrc:/audio/Gameover.mp3"
        audioPlayer.play();
        console.log("game over")
    }
}
