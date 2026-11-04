/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: settings for "Audio Track" instruments (file, start offset, volume trim)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include "audiotracksmodel.h"

#include <QVariantMap>

#include "engraving/dom/part.h"
#include "notation/imasternotation.h"
#include "notation/inotationparts.h"
#include "project/inotationproject.h"
#include "project/iprojectaudiosettings.h"
#include "io/path.h"
#include "translation.h"

#include "scoriaaudiotrack.h"

using namespace muse;
using namespace muse::audio;
using namespace mu::playback;
using namespace mu::engraving;
using namespace mu::notation;

AudioTracksModel::AudioTracksModel(QObject* parent)
    : QObject(parent), muse::Contextable(muse::iocCtxForQmlObject(this))
{
}

void AudioTracksModel::load()
{
    m_entries.clear();
    if (controller()) {
        for (const auto& [instrumentTrackId, trackId] : controller()->instrumentTrackIdMap()) {
            if (scoria::isAudioTrack(instrumentTrackId)) {
                m_entries.push_back({ instrumentTrackId, trackId });
            }
        }

        controller()->trackAdded().onReceive(this, [this](TrackId) { load(); }, Asyncable::Mode::SetReplace);
        controller()->trackRemoved().onReceive(this, [this](TrackId) { load(); }, Asyncable::Mode::SetReplace);
    }
    emit tracksChanged();
}

AudioInputParams AudioTracksModel::params(const Entry& e) const
{
    project::INotationProjectPtr project = context()->project();
    return project ? project->audioSettings()->trackInputParams(e.instrumentTrackId) : AudioInputParams();
}

void AudioTracksModel::apply(const Entry& e, const AudioInputParams& params)
{
    playback()->setSourceParams(e.trackId, params);
    if (project::INotationProjectPtr project = context()->project()) {
        project->audioSettings()->setTrackInputParams(e.instrumentTrackId, params);
    }
    emit tracksChanged();
}

QVariantList AudioTracksModel::tracks() const
{
    QVariantList result;
    INotationPartsPtr parts = context()->masterNotation() ? context()->masterNotation()->parts() : nullptr;

    for (const Entry& e : m_entries) {
        const AudioInputParams p = params(e);
        const Part* part = parts ? parts->part(e.instrumentTrackId.partId) : nullptr;
        const std::string file = scoria::filePath(p);

        QVariantMap item;
        item["name"] = part ? part->partName().toQString() : qtrc("playback", "Audio Track");
        item["file"] = file.empty() ? qtrc("playback", "No file chosen") : io::filename(io::path_t(file)).toQString();
        item["offset"] = scoria::attribute(p, scoria::OFFSET_ATTRIBUTE);
        item["gain"] = scoria::attribute(p, scoria::GAIN_ATTRIBUTE);
        result << item;
    }
    return result;
}

void AudioTracksModel::setOffset(int index, double seconds)
{
    if (index < 0 || index >= int(m_entries.size())) {
        return;
    }
    const Entry& e = m_entries[index];
    const AudioInputParams p = params(e);
    apply(e, scoria::makeParams(scoria::filePath(p), seconds, scoria::attribute(p, scoria::GAIN_ATTRIBUTE)));
}

void AudioTracksModel::setGain(int index, double db)
{
    if (index < 0 || index >= int(m_entries.size())) {
        return;
    }
    const Entry& e = m_entries[index];
    const AudioInputParams p = params(e);
    apply(e, scoria::makeParams(scoria::filePath(p), scoria::attribute(p, scoria::OFFSET_ATTRIBUTE), db));
}

void AudioTracksModel::changeFile(int index)
{
    if (index < 0 || index >= int(m_entries.size())) {
        return;
    }
    const Entry e = m_entries[index];

    const std::vector<std::string> filter = {
        muse::trc("playback", "Audio files") + " (*.mp3 *.wav *.flac *.MP3 *.WAV *.FLAC)",
        muse::trc("playback", "All files") + " (*)"
    };

    io::path_t path = interactive()->selectOpeningFileSync(muse::trc("playback", "Choose the audio file for this Audio Track"), "", filter);
    if (path.empty()) {
        return;
    }

    const AudioInputParams p = params(e);
    apply(e, scoria::makeParams(path.toStdString(), scoria::attribute(p, scoria::OFFSET_ATTRIBUTE),
                                scoria::attribute(p, scoria::GAIN_ATTRIBUTE)));

    if (context()->masterNotation()) {
        const InstrumentKey key { e.instrumentTrackId.instrumentId, e.instrumentTrackId.partId, Part::MAIN_INSTRUMENT_TICK };
        context()->masterNotation()->parts()->setInstrumentName(key, io::completeBasename(path).toQString());
    }
}
