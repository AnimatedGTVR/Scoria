/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: settings for "Audio Track" instruments (file, start offset, volume trim)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#pragma once

#include <QObject>
#include <QVariantList>
#include <qqmlintegration.h>

#include "modularity/ioc.h"
#include "async/asyncable.h"
#include "audio/main/iplayback.h"
#include "interactive/iinteractive.h"
#include "project/iprojectsession.h"

#include "iplaybackcontroller.h"

namespace mu::playback {
class AudioTracksModel : public QObject, public muse::Contextable, public muse::async::Asyncable
{
    Q_OBJECT
    QML_ELEMENT

    //! [{ name, file, offset, gain }]
    Q_PROPERTY(QVariantList tracks READ tracks NOTIFY tracksChanged)

    muse::ContextInject<muse::audio::IPlayback> playback = { this };
    muse::ContextInject<IPlaybackController> controller = { this };
    muse::ContextInject<project::IProjectSession> context = { this };
    muse::ContextInject<muse::IInteractive> interactive = { this };

public:
    explicit AudioTracksModel(QObject* parent = nullptr);

    QVariantList tracks() const;

    Q_INVOKABLE void load();
    Q_INVOKABLE void setOffset(int index, double seconds);
    Q_INVOKABLE void setGain(int index, double db);
    Q_INVOKABLE void changeFile(int index);

signals:
    void tracksChanged();

private:
    struct Entry {
        engraving::InstrumentTrackId instrumentTrackId;
        muse::audio::TrackId trackId = -1;
    };

    muse::audio::AudioInputParams params(const Entry& e) const;
    void apply(const Entry& e, const muse::audio::AudioInputParams& params);

    std::vector<Entry> m_entries;
};
}
