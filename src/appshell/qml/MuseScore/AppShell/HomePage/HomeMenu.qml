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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Muse.Ui
import Muse.UiComponents
import Muse.Cloud

Item {
    id: root

    property string currentPageName: ""
    property bool iconsOnly: false

    signal selected(string name)

    NavigationSection {
        id: navSec
        name: "HomeMenuSection"
        enabled: root.enabled && root.visible
        order: 2
    }

    NavigationPanel {
        id: navPanel
        name: "HomeMenuPanel"
        enabled: root.enabled && root.visible
        section: navSec
        order: 1
        direction: NavigationPanel.Vertical

        accessible.name: qsTrc("appshell", "Home menu") + " " + navPanel.directionInfo
    }

    ColumnLayout {
        anchors.fill: parent

        spacing: 0

        // Scoria brand header
        Item {
            id: brand

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.topMargin: 20

            Rectangle {
                id: brandBadge

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: root.iconsOnly ? (brand.width - width) / 2 : 24

                width: 36
                height: 36
                radius: 10

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: ui.theme.accentColor }
                    GradientStop { position: 1.0; color: ui.theme.focusColor }
                }

                StyledTextLabel {
                    anchors.centerIn: parent
                    text: "S"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#FFFFFF"
                }
            }

            StyledTextLabel {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: brandBadge.right
                anchors.leftMargin: 12

                visible: !root.iconsOnly
                text: "Scoria"
                font.pixelSize: 24
                font.bold: true
                font.letterSpacing: 0.5
            }
        }

        AccountInfoButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.topMargin: 8

            navigation.name: "AccountInfo"
            navigation.panel: navPanel
            navigation.row: 1

            checked: root.currentPageName === "account"
            iconOnly: root.iconsOnly

            onToggled: {
                root.selected("account")
            }
        }

        RadioButtonGroup {
            id: radioButtonList

            Layout.fillHeight: true
            Layout.fillWidth: true

            orientation: ListView.Vertical
            spacing: 0

            model: [
                { "name": "scores", "title": qsTrc("appshell", "Scores"), "iconCode": IconCode.MUSIC_NOTES },
                { "name": "extensions", "title": qsTrc("appshell", "Plugins"), "iconCode":  IconCode.PLUGIN },
                { "name": "musesounds", "title": qsTrc("appshell", "MuseSounds"), "iconCode": IconCode.PLAY },
                { "name": "learn", "title": qsTrc("appshell", "Learn"), "iconCode":  IconCode.MORTAR_BOARD }
            ]

            currentIndex: 0

            delegate: PageTabButton {
                id: radioButtonDelegate

                required title
                required property int iconCode
                required property string name
                required property int index

                width: radioButtonList.width

                navigation.name: title
                navigation.panel: navPanel
                navigation.row: 2 + index

                spacing: 30
                leftPadding: spacing

                ButtonGroup.group: radioButtonList.radioButtonGroup
                orientation: Qt.Horizontal
                checked: name === root.currentPageName

                iconOnly: root.iconsOnly

                iconComponent: StyledIconLabel {
                    iconCode: radioButtonDelegate.iconCode
                }

                onToggled: {
                    radioButtonList.currentIndex = index
                    root.selected(name)
                }
            }
        }
    }
}
