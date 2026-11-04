/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: audio file tracks (MP3 / WAV / FLAC backing tracks that play along with the score)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#pragma once

#include <map>
#include <string>

#include "modularity/imoduleinterface.h"
#include "async/channel.h"
#include "types/ret.h"
#include "io/path.h"
#include "audio/common/audiotypes.h"

namespace mu::playback {
class IAudioFileTracks : MODULE_CONTEXT_INTERFACE
{
    INTERFACE_ID(IAudioFileTracks)

public:
    virtual ~IAudioFileTracks() = default;

    struct Track {
        std::string path;   // absolute path of the audio file
        std::string name;   // shown in the mixer
    };
    using TrackMap = std::map<muse::audio::TrackId, Track>;

    //! Tracks of the current score, keyed by engine track id
    virtual const TrackMap& tracks() const = 0;

    //! Ask the user for a file, then add it as a track and remember it in the score
    virtual muse::Ret addTrackInteractive() = 0;
    virtual void addTrack(const muse::io::path_t& path) = 0;
    virtual void removeTrack(muse::audio::TrackId trackId) = 0;

    virtual muse::async::Channel<muse::audio::TrackId> trackAdded() const = 0;
    virtual muse::async::Channel<muse::audio::TrackId> trackRemoved() const = 0;
};
}
