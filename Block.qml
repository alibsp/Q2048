import QtQuick 2.0
import QtQuick.Layouts 1.12

Rectangle
{
    property var value  : 0
    property bool animMoveEnable: false;
    property bool animResizeEnable: false
    width : 0
    height: width
    visible: value>0
    QtObject
    {
        id: privates
        property var colors : ["#eee4da", "#ece0c8", "#f2b179", "#f59563",
            "#FF5722", "#FF9800", "#FFC107", "#FFEB3B",
            "#CDDC39", "#8BC34A" , "#4CAF50", "#009688",
            "#00BCD4", "#03A9F4", "#2196F3", "#9C27B0"]
        property bool isFirst :true

    }

    color: "transparent"
    Rectangle
    {
        color: value?privates.colors[Math.log(value)/Math.log(2)-1] : "#ccc0b2"
        radius : parent.radius
        anchors.centerIn: parent
        width : parent.width
        height: width
        Text {
            visible: value>0
            text: value
            color: value <=4 ? "#786f66" : "#f7f8f0"
            anchors.centerIn: parent
            style: Text.Normal
            font.family: "Tahoma"
            font.bold: true
            font.pixelSize: (10-text.length)*parent.width/20
        }
        Behavior on width
        {
            enabled:animResizeEnable
            NumberAnimation
            {
                duration: 100;
                onRunningChanged:
                {
                    if(!running)
                        privates.isFirst = false;
                }
            }

        }
    }
    Behavior on x
    {
        //enabled: !privates.isFirst
        enabled: animMoveEnable
        NumberAnimation
        {
            duration: 100;
        }
    }

    Behavior on y
    {
        //enabled: !privates.isFirst
        enabled: animMoveEnable
        NumberAnimation {
            duration: 100;
        }
    }
    radius:2
}
