/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: settings for "Audio Track" instruments (file, start offset, volume trim)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Muse.Ui
import Muse.UiComponents
import MuseScore.Playback

StyledDialogView {
    id: root

    title: qsTrc("playback", "Audio tracks")

    contentWidth: 640
    contentHeight: Math.max(220, contentColumn.implicitHeight + 48)

    AudioTracksModel {
        id: tracksModel
    }

    Component.onCompleted: {
        tracksModel.load()
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        StyledTextLabel {
            Layout.fillWidth: true
            text: qsTrc("playback", "Line your song up with the score. Write notes on an Audio Track where it should play and rests where it should be silent; dynamics set its volume. An empty Audio Track plays the whole song.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
            opacity: 0.8
        }

        StyledTextLabel {
            Layout.fillWidth: true
            visible: tracksModel.tracks.length === 0
            text: qsTrc("playback", "This score has no Audio Track yet. Press I (Add instruments) and add “Audio Track” from the Audio group.")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignLeft
        }

        Repeater {
            model: tracksModel.tracks

            delegate: Rectangle {
                id: trackItem

                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: trackColumn.implicitHeight + 24
                radius: 8
                color: ui.theme.backgroundSecondaryColor
                border.color: ui.theme.strokeColor
                border.width: 1

                ColumnLayout {
                    id: trackColumn

                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StyledTextLabel {
                            Layout.fillWidth: true
                            text: trackItem.modelData.name
                            font: ui.theme.bodyBoldFont
                            horizontalAlignment: Text.AlignLeft
                        }

                        StyledTextLabel {
                            text: trackItem.modelData.file
                            opacity: 0.7
                        }

                        FlatButton {
                            text: qsTrc("playback", "Change file…")
                            onClicked: tracksModel.changeFile(trackItem.index)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        ColumnLayout {
                            spacing: 4

                            StyledTextLabel {
                                text: qsTrc("playback", "Start offset")
                                horizontalAlignment: Text.AlignLeft
                            }

                            IncrementalPropertyControl {
                                implicitWidth: 140
                                currentValue: trackItem.modelData.offset
                                step: 0.05
                                decimals: 2
                                minValue: -600
                                maxValue: 3600
                                measureUnitsSymbol: qsTrc("global", "s")

                                onValueEditingFinished: function(newValue) {
                                    tracksModel.setOffset(trackItem.index, newValue)
                                }
                            }

                            StyledTextLabel {
                                text: qsTrc("playback", "Song time at the start of the score (negative = wait)")
                                font.pixelSize: 11
                                opacity: 0.6
                                horizontalAlignment: Text.AlignLeft
                            }
                        }

                        ColumnLayout {
                            spacing: 4

                            StyledTextLabel {
                                text: qsTrc("playback", "Volume trim")
                                horizontalAlignment: Text.AlignLeft
                            }

                            IncrementalPropertyControl {
                                implicitWidth: 140
                                currentValue: trackItem.modelData.gain
                                step: 0.5
                                decimals: 1
                                minValue: -60
                                maxValue: 24
                                measureUnitsSymbol: qsTrc("global", "dB")

                                onValueEditingFinished: function(newValue) {
                                    tracksModel.setGain(trackItem.index, newValue)
                                }
                            }

                            StyledTextLabel {
                                text: qsTrc("playback", "On top of the score’s dynamics")
                                font.pixelSize: 11
                                opacity: 0.6
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignRight

            FlatButton {
                text: qsTrc("global", "Close")
                accentButton: true
                onClicked: root.hide()
            }
        }
    }
}
