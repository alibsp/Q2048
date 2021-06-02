import QtQuick 2.14
import QtQuick.Layouts 1.12

Rectangle
{
    id: gameOverRect
    radius: 3
    visible: false;
    opacity: 0.0
    color: "#bbada0"
    signal tryAgainClicked
    property alias animateOpacity: animateOpacity

    ColumnLayout
    {
        anchors.centerIn: parent
        spacing: 5*mm
        Text {
            id: text1
            color: "#766d65"
            text: qsTr("Game Over!")
            font.bold: true
            font.family: "Verdana"
            font.pixelSize: 13*mm
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle
        {
            id: rectangle2
            width: 40*mm
            height: 10*mm
            color: "#8c7963"
            radius: 3
            clip: false
            Layout.alignment: Qt.AlignHCenter
            Text
            {
                color: "#e2e1d6"
                text: qsTr("Try again")
                font.bold: true
                font.family: "Verdana"
                anchors.centerIn: parent
                font.pixelSize: 5*mm
            }
            MouseArea {
                anchors.fill: parent;
                onClicked: tryAgainClicked();// newGame();
            }
        }
    }
    NumberAnimation {
        id: animateOpacity
        target: gameOverRect
        properties: "opacity"
        from: 0.00
        to: 0.80
        duration: 1000
    }
}
