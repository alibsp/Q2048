import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.1
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Universal 2.12
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
    property int score : 0
    property int bestScore

    property var moving : false

    property var mm:Screen.pixelDensity

    property var cellWidth: (Math.min(width, (height-scoreBoard.height)))/colCount*.7
    property var cells : []
    property var blocks : []

    Item{
        focus: true
        Keys.onPressed:
        {
            console.log("Keys.onPressed:", event.key);
            if(move(event.key))
            {
                movingTimer.start();
            }
            event.accepted = true;
        }
    }
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
                    /*Block
                    {
                        width: 23*mm//grid.cellWidth//grid.width/root.count
                        height: width
                        value:Math.pow(2, index+1)
                        //color: "#ccc0b2"
                        radius: 1*mm
                    }*/
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



    Timer
    {
        id: movingTimer
        interval: 100; running: false;
        onTriggered:
        {
            onAnimEnd();
        }
    }


    Component.onCompleted:
    {
        console.log("wh:", grid.width, grid.height)
        init();
    }

    function init()
    {
        for(var i=0;i<rowCount;i++)
        {
            table[i] = [];
            blocks[i] = [];
            //cells[i] = [];
        }
        newGame();
    }

    function newGame()
    {
        app.score=0;
        for(var i=0;i<rowCount;i++)
            for(var j=0;j<colCount;j++)
                table[i][j]=0;
        cleanCells();
        randomBlock();
        randomBlock();
        moving = false;
        gameOverWindow.opacity = 0.0
        gameOverWindow.visible = false;
        //gameOverWindow.visible = true;
        //gameOverWindow.animateOpacity.start();
    }

    function randomBlock()
    {
        var emptyCells=[];
        for(var i=0;i<rowCount;i++)
            for(var j=0;j<colCount;j++)
                if(!table[i][j])
                    emptyCells.push(i*colCount+j);
        if(emptyCells.length)
        {
            var k = Math.floor(Math.random()*emptyCells.length);
            var value=Math.random() < 0.9 ? 2 : 4;
            i = Math.floor(emptyCells[k]/colCount);
            j = emptyCells[k]%colCount;
            newBlock(i, j, value, true);
        }
        if (emptyCells.length <= 1)
            if (!isNextStep())
                gameOver();
    }

    function isNextStep()
    {
        for (var i = 0; i < rowCount; ++i)
            for (var j = 0; j < colCount - 1; ++j)
                if (table[i][j] === table[i][j+1])
                    return true;

        for (var i = 0; i < rowCount - 1; ++i)
            for (var j = 0; j < colCount; ++j)
                if (table[i][j] === table[i+1][j])
                    return true;

        return false;
    }

    function newBlock(i, j, value, respaun)
    {
        var block = Qt.createQmlObject("import QtQuick 2.14;Block{}", grid);
        block.value=value;
        block.animResizeEnable = respaun;
        block.x = cells[i][j].x;
        block.y = cells[i][j].y;
        block.radius = cells[i][j].radius;
        block.width = cells[i][j].width;
        blocks[i][j] = block;
        table[i][j] = value;
    }



    function move(direction)
    {
        if(moving)
            return !moving;
        if (direction === Qt.Key_Left || direction=== Qt.Key_Up)
            for (var i = 0; i < rowCount; ++i)
                for (var j = 0; j < colCount; ++j)
                    for (var f = j+1; f < rowCount; ++f )
                        if (direction === Qt.Key_Left)
                        {
                            if (!moveObj(i, f, i, j))
                                break;
                        } else {
                            if(!moveObj(f, i, j, i))
                                break;
                        }

        if (direction === Qt.Key_Right || direction === Qt.Key_Down)
            for (i = 0; i < rowCount; ++i)
                for (j = colCount - 1; j >= 0; --j)
                    for (f = j-1; f >= 0; --f )
                        if (direction === Qt.Key_Right)
                        {
                            if (!moveObj(i, f, i, j))
                                break;
                        } else {
                            if (!moveObj(f, i, j, i))
                                break;
                        }
        return moving;
    }
    function moveObj(row, col, row2, col2)
    {
        var cell1 = table[row][col];
        var cell2 = table[row2][col2];

        if ((cell1 !== 0 && cell2 !== 0) && cell1 !== cell2)
            return false;

        blocks[row][col].animMoveEnable = true;

        if ( (cell1 !== 0 && cell1 === cell2) ||
                (cell1 !== 0 && cell2 === 0) )
        {
            table[row][col] = 0;
            blocks[row][col].x = cells[row2][col2].x;
            blocks[row][col].y = cells[row2][col2].y;
            moving = true;
        }

        if (cell1 !== 0 && cell1 === cell2)
        {
            table[row2][col2] *= 2;
            app.score += table[row2][col2];
            if(app.score>app.bestScore)
                app.bestScore = app.score;
            return false;
        }

        if (cell1 !== 0 && cell2 === 0)
        {
            table[row2][col2] = cell1;
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
    function onAnimEnd()
    {
        cleanCells();

        for (var i = 0; i < rowCount; ++i)
        {
            for (var j = 0; j < colCount; ++j)
            {
                if (table[i][j]!== 0)
                    newBlock(i, j, table[i][j], false);
            }
        }
        moving = false;
        randomBlock();

        for (var i = 0; i < rowCount; ++i)
        {
            var log="";
            for (var j = 0; j < colCount; ++j)
                log+=" "+table[i][j].toString().padStart(3, " ");
            console.log(log);
        }
    }
    function gameOver()
    {
        moving = true;
        bestScore = Math.max(score, bestScore);
        gameOverWindow.visible = true;
        gameOverWindow.animateOpacity.start();
        console.log("game over")
    }

}
