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
import MuseScore.Preferences

import "internal"

PreferencesPage {
    id: root

    Component.onCompleted: {
        preferencesModel.load()
    }

    GeneralPreferencesModel {
        id: preferencesModel

        onReceivingUpdateForCurrentLanguage: function(current, total, status) {
            languagesSection.setUpdateProgress(current, total, status)
        }
    }

    Column {
        width: parent.width
        spacing: root.sectionsSpacing

        LanguagesSection {
            id: languagesSection

            languages: preferencesModel.languages
            currentLanguageCode: preferencesModel.currentLanguageCode
            restartRequired: preferencesModel.restartRequired

            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 1

            onLanguageSelected: function(languageCode) {
                preferencesModel.currentLanguageCode = languageCode
            }

            onCheckForUpdateRequested: {
                preferencesModel.checkUpdateForCurrentLanguage()
            }
        }

        SeparatorLine { }

        // Scoria: pick X11 or Wayland (applies after restart)
        BaseSection {
            id: displayServerSection

            title: qsTrc("preferences", "Display server")
            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 50
            navigation.direction: NavigationPanel.Horizontal

            StyledDropdown {
                id: displayServerDropdown

                width: displayServerSection.columnWidth

                model: [
                    { text: qsTrc("preferences", "X11 (recommended)"), value: "x11" },
                    { text: qsTrc("preferences", "Wayland (experimental)"), value: "wayland" },
                    { text: qsTrc("preferences", "Automatic"), value: "auto" }
                ]

                currentIndex: displayServerDropdown.indexOfValue(preferencesModel.displayServer)

                navigation.name: "DisplayServerBox"
                navigation.panel: displayServerSection.navigation
                navigation.order: 1

                onActivated: function(index, value) {
                    preferencesModel.displayServer = value
                }
            }

            StyledTextLabel {
                width: displayServerSection.columnWidth
                visible: preferencesModel.restartRequired
                text: qsTrc("preferences", "Restart Scoria to apply.")
                horizontalAlignment: Text.AlignLeft
                opacity: 0.7
            }
        }

        SeparatorLine { }

        ProgramStartSection {
            model: preferencesModel

            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 2
        }

        SeparatorLine { }

        WelcomeDialogSection {
            model: preferencesModel

            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 3
        }

        /*
         * TODO: https://github.com/musescore/MuseScore/issues/9807
        KeyboardLayoutsSection {
            keyboardLayouts: preferencesModel.keyboardLayouts
            currentKeyboardLayout: preferencesModel.currentKeyboardLayout

            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 2

            onKeyboardLayoutSelected: function(keyboardLayout) {
                preferencesModel.currentKeyboardLayout = keyboardLayout
            }
        }

        SeparatorLine { }
        */

        /*
         * TODO: https://github.com/musescore/MuseScore/issues/9807
        SeparatorLine { }

        RemoteControlSection {
            isOSCRemoteControl: preferencesModel.isOSCRemoteControl
            oscPort: preferencesModel.oscPort

            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 4

            onRemoteControlChanged: function(control) {
                preferencesModel.isOSCRemoteControl = control
            }

            onPortChanged: function(port) {
                preferencesModel.oscPort = port
            }
        }*/

        SeparatorLine { }

        AutomaticUpdateSection {
            isAppUpdatable: preferencesModel.isAppUpdatable()
            needCheckForNewAppVersion: preferencesModel.needCheckForNewAppVersion
            autoUpdateNewAppVersion: preferencesModel.autoUpdateNewAppVersion
            museScorePrivacyPolicyUrl: preferencesModel.museScorePrivacyPolicyUrl()

            navigation.section: root.navigationSection
            navigation.order: root.navigationOrderStart + 4

            onNeedCheckForNewAppVersionChangeRequested: function(check) {
                preferencesModel.needCheckForNewAppVersion = check
            }

            onAutoUpdateNewAppVersionChangeRequested: function(enabled) {
                preferencesModel.autoUpdateNewAppVersion = enabled
            }
        }
    }
}
