/*
 * SPDX-License-Identifier: GPL-3.0-only
 * Scoria: audio file tracks (MP3 / WAV / FLAC backing tracks that play along with the score)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 */
#include "audiofiletracks.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#include "io/file.h"
#include "engraving/dom/masterscore.h"
#include "translation.h"
#include "log.h"

using namespace muse;
using namespace muse::audio;
using namespace mu::playback;

//! Saved inside the score (.mscz) as a meta tag, a JSON array of { "path": ... }
static const char* SCORE_TAG = "scoriaAudioTracks";

AudioFileTracks::AudioFileTracks(const muse::modularity::ContextPtr& iocCtx)
    : muse::Contextable(iocCtx)
{
}

void AudioFileTracks::init()
{
    // PlaybackController removes every engine track when a score is (re)loaded and then reports
    // "inited"; that's when our tracks have to be added back.
    controller()->playbackInitedChanged().onReceive(this, [this](bool inited) {
        if (!inited) {
            for (const auto& [id, _] : m_tracks) {
                m_trackRemoved.send(id);
            }
            m_tracks.clear();
            m_buffers.clear();
            return;
        }
        loadFromScore();
    });
}

const IAudioFileTracks::TrackMap& AudioFileTracks::tracks() const
{
    return m_tracks;
}

Ret AudioFileTracks::addTrackInteractive()
{
    if (!projectSession()->masterNotation()) {
        return make_ret(Ret::Code::Cancel);
    }

    const std::vector<std::string> filter = {
        muse::trc("playback", "Audio files") + " (*.mp3 *.wav *.flac *.MP3 *.WAV *.FLAC)",
        muse::trc("playback", "All files") + " (*)"
    };

    io::path_t path = interactive()->selectOpeningFileSync(muse::trc("playback", "Add audio track"), "", filter);
    if (path.empty()) {
        return make_ret(Ret::Code::Cancel);
    }

    doAddTrack(path, true);
    return make_ok();
}

void AudioFileTracks::addTrack(const io::path_t& path)
{
    doAddTrack(path, true);
}

void AudioFileTracks::doAddTrack(const io::path_t& path, bool remember)
{
    ByteArray data;
    Ret readRet = io::File::readFile(path, data);
    if (!readRet || data.empty()) {
        LOGE() << "Scoria: can't read audio file: " << path;
        interactive()->error(muse::trc("playback", "Can't add audio track"),
                             muse::qtrc("playback", "Could not read “%1”.").arg(path.toQString()).toStdString());
        return;
    }

    // The engine reads the file through this device on its own thread, so it must outlive the request
    auto buffer = std::make_shared<io::Buffer>(std::move(data));
    buffer->open(io::IODevice::ReadOnly);

    const std::string name = io::completeBasename(path).toStdString();

    playback()->addTrack(name, buffer.get(), audio::TrackParams())
    .onResolve(this, [this, path, name, remember, buffer](TrackId trackId, const audio::TrackParams&) {
        m_buffers[trackId] = buffer;
        m_tracks[trackId] = { path.toStdString(), name };
        if (remember) {
            saveToScore();
        }
        m_trackAdded.send(trackId);
    })
    .onReject(this, [this, path, buffer](int code, const std::string& msg) {
        LOGE() << "Scoria: can't add audio track " << path << ", code: " << code << " " << msg;
        interactive()->error(muse::trc("playback", "Can't add audio track"),
                             muse::qtrc("playback", "“%1” isn't a supported audio file. Scoria can play MP3, WAV and FLAC.")
                             .arg(io::filename(path).toQString()).toStdString());
    });
}

void AudioFileTracks::removeTrack(TrackId trackId)
{
    auto it = m_tracks.find(trackId);
    if (it == m_tracks.end()) {
        return;
    }

    playback()->removeTrack(trackId);
    m_tracks.erase(it);
    m_buffers.erase(trackId);
    saveToScore();
    m_trackRemoved.send(trackId);
}

async::Channel<TrackId> AudioFileTracks::trackAdded() const
{
    return m_trackAdded;
}

async::Channel<TrackId> AudioFileTracks::trackRemoved() const
{
    return m_trackRemoved;
}

void AudioFileTracks::loadFromScore()
{
    auto master = projectSession()->masterNotation();
    if (!master || !master->masterScore()) {
        return;
    }

    const QString json = master->masterScore()->metaTag(String::fromStdString(SCORE_TAG)).toQString();
    if (json.isEmpty()) {
        return;
    }

    const QJsonArray arr = QJsonDocument::fromJson(json.toUtf8()).array();
    for (const QJsonValue& v : arr) {
        const io::path_t path = io::path_t(v.toObject().value("path").toString());
        if (path.empty()) {
            continue;
        }
        if (!io::File::exists(path)) {
            LOGW() << "Scoria: audio track file is missing: " << path;
            continue;
        }
        doAddTrack(path, false);
    }
}

void AudioFileTracks::saveToScore()
{
    auto master = projectSession()->masterNotation();
    if (!master || !master->masterScore()) {
        return;
    }

    QJsonArray arr;
    for (const auto& [id, track] : m_tracks) {
        QJsonObject o;
        o["path"] = QString::fromStdString(track.path);
        arr.append(o);
    }
    const QString json = arr.isEmpty() ? QString() : QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact));
    master->masterScore()->setMetaTag(String::fromStdString(SCORE_TAG), String::fromQString(json));

    if (auto project = projectSession()->project()) {
        project->markAsUnsaved();
    }
}
