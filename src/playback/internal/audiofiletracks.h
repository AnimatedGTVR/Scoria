/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: audio file tracks (MP3 / WAV / FLAC backing tracks that play along with the score)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#pragma once

#include <memory>

#include "modularity/ioc.h"
#include "async/asyncable.h"
#include "interactive/iinteractive.h"
#include "project/iprojectsession.h"
#include "audio/main/iplayback.h"
#include "io/buffer.h"

#include "../iaudiofiletracks.h"
#include "../iplaybackcontroller.h"

namespace mu::playback {
class AudioFileTracks : public IAudioFileTracks, public muse::async::Asyncable, public muse::Contextable
{
    muse::ContextInject<muse::audio::IPlayback> playback = { this };
    muse::ContextInject<project::IProjectSession> projectSession = { this };
    muse::ContextInject<IPlaybackController> controller = { this };
    muse::ContextInject<muse::IInteractive> interactive = { this };

public:
    explicit AudioFileTracks(const muse::modularity::ContextPtr& iocCtx);

    void init();

    const TrackMap& tracks() const override;

    muse::Ret addTrackInteractive() override;
    void addTrack(const muse::io::path_t& path) override;
    void removeTrack(muse::audio::TrackId trackId) override;

    muse::async::Channel<muse::audio::TrackId> trackAdded() const override;
    muse::async::Channel<muse::audio::TrackId> trackRemoved() const override;

private:
    //! Add to the engine without touching the saved list (used when loading a score)
    void doAddTrack(const muse::io::path_t& path, bool remember);

    void loadFromScore();
    void saveToScore();

    TrackMap m_tracks;
    //! The engine reads the file through this device, keep it alive while the track exists
    std::map<muse::audio::TrackId, std::shared_ptr<muse::io::Buffer> > m_buffers;

    muse::async::Channel<muse::audio::TrackId> m_trackAdded;
    muse::async::Channel<muse::audio::TrackId> m_trackRemoved;
};
}
