/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-Studio-CLA-applies
 *
 * MuseScore Studio
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore Limited and others
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
 
import QtQuick

import Muse.Ui
import Muse.UiComponents
import MuseScore.Playback

import "internal"

Item {
    id: root

    property alias floating: thePlaybackModel.isToolbarFloating

    property NavigationPanel navigationPanel: NavigationPanel {
        id: navPanel
        name: "PlaybackToolBar"
        enabled: root.enabled && root.visible
        accessible.name: qsTrc("playback", "Playback toolbar")
    }

    property alias navigationPanelSection: navPanel.section
    property alias navigationPanelOrder: navPanel.order

    PlaybackToolBarModel {
        id: thePlaybackModel
    }

    width: content.width + (root.floating ? 12 : 0)
    height: content.height

    Component.onCompleted: {
        thePlaybackModel.load()
    }

    // Scoria: a Grid so the docked toolbar can grow sideways (seek + speed chips)
    // while the floating toolbar keeps stacking vertically as before.
    Grid {
        id: content

        columns: root.floating ? 1 : 3
        spacing: 8
        verticalItemAlignment: Grid.AlignVCenter

        width: childrenRect.width

        enabled: thePlaybackModel.isPlayAllowed

        PlaybackToolBarActions {
            id: playbackActions

            playbackModel: thePlaybackModel
            floating: root.floating

            navPanel: root.navigationPanel
        }

        Loader {
            active: root.floating

            width: childrenRect.width

            sourceComponent: Column {
                spacing: 8

                width: childrenRect.width

                StyledSlider {
                    id: playPositionSlider

                    width: playbackActions.width

                    value: thePlaybackModel.playPosition
                    stepSize: 0.05

                    navigation.panel: navPanel
                    navigation.order: playbackActions.navigationOrderEnd + 1

                    onMoved: {
                        thePlaybackModel.playPosition = value
                    }
                }

                PlaybackSpeedSlider {
                    width: playbackActions.width

                    playbackModel: thePlaybackModel

                    navigationPanel: navPanel
                    navigationOrderStart: playPositionSlider.navigation.order + 1
                }
            }
        }

        // Scoria: docked extras (upstream only shows seek/speed when floating)
        Loader {
            active: !root.floating
            visible: active

            sourceComponent: Row {
                spacing: 6

                StyledSlider {
                    id: dockedSeek

                    anchors.verticalCenter: parent.verticalCenter
                    width: 160

                    value: thePlaybackModel.playPosition
                    stepSize: 0.01

                    navigation.panel: navPanel
                    navigation.order: playbackActions.navigationOrderEnd + 1
                    navigation.accessible.name: qsTrc("playback", "Playback position")

                    onMoved: {
                        thePlaybackModel.playPosition = value
                    }
                }

                Repeater {
                    model: [0.5, 0.75, 1.0, 1.25]

                    FlatButton {
                        required property real modelData
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        minWidth: 40
                        height: 26

                        text: Math.round(modelData * 100) + "%"
                        accentButton: Math.abs(thePlaybackModel.tempoMultiplier - modelData) < 0.001
                        transparent: !accentButton

                        navigation.panel: navPanel
                        navigation.order: dockedSeek.navigation.order + 1 + index
                        toolTipTitle: qsTrc("playback", "Playback speed %1").arg(text)

                        onClicked: {
                            thePlaybackModel.tempoMultiplier = modelData
                        }
                    }
                }
            }
        }
    }
}
