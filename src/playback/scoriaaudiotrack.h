/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: helpers for the "Audio Track" instrument
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#pragma once

#include <string>

#include "audio/common/audiotypes.h"
#include "engraving/types/types.h"

namespace mu::playback::scoria {
//! Must match the instrument id in share/instruments/instruments.xml
inline const muse::String AUDIO_TRACK_INSTRUMENT_ID = u"scoria-audio-track";

//! Must match AudioFileSynth in the muse framework (patches/muse/0002)
inline const std::string AUDIO_RESOURCE_PREFIX = "scoria-audio:";
inline const muse::String OFFSET_ATTRIBUTE = u"scoriaOffset";
inline const muse::String GAIN_ATTRIBUTE = u"scoriaGain";

inline bool isAudioTrack(const engraving::InstrumentTrackId& id)
{
    return id.instrumentId == AUDIO_TRACK_INSTRUMENT_ID;
}

inline bool isAudioResource(const muse::audio::AudioInputParams& params)
{
    return params.resourceMeta.id.rfind(AUDIO_RESOURCE_PREFIX, 0) == 0;
}

inline std::string filePath(const muse::audio::AudioInputParams& params)
{
    return isAudioResource(params) ? params.resourceMeta.id.substr(AUDIO_RESOURCE_PREFIX.size()) : std::string();
}

inline double attribute(const muse::audio::AudioInputParams& params, const muse::String& key)
{
    const muse::String& v = params.resourceMeta.attributeVal(key);
    bool ok = false;
    const double d = v.empty() ? 0.0 : v.toDouble(&ok);
    return ok ? d : 0.0;
}

//! offsetSecs: which second of the file lines up with the start of the score; gainDb: volume trim
inline muse::audio::AudioInputParams makeParams(const std::string& path, double offsetSecs = 0.0, double gainDb = 0.0)
{
    muse::audio::AudioInputParams params;
    params.resourceMeta.id = AUDIO_RESOURCE_PREFIX + path;
    params.resourceMeta.vendor = "Scoria";
    params.resourceMeta.type = std::string(muse::audio::FLUID_SOUNDFONT_TYPE_NAME);
    params.resourceMeta.attributes[OFFSET_ATTRIBUTE] = muse::String::number(offsetSecs);
    params.resourceMeta.attributes[GAIN_ATTRIBUTE] = muse::String::number(gainDb);
    return params;
}
}
