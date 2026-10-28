/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// How many slideshow images stay on disk: the one on screen + the previous one
/// as an offline fallback.
const int slideshowMaxCachedFiles = 2;

class UnsplashPhoto {
  final String id;
  final String imageUrl;
  final String author;
  final String downloadLocation;

  const UnsplashPhoto(this.id, this.imageUrl, this.author, this.downloadLocation);

  /// Parses a /photos/random response, asking the CDN for a 1080p JPEG.
  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) => UnsplashPhoto(
        json['id'] as String,
        "${json['urls']['raw']}&w=1920&h=1080&fit=crop&fm=jpg&q=80",
        json['user']['name'] as String,
        json['links']['download_location'] as String,
      );
}

/// A selectable slideshow category, mapped to an Unsplash /photos/random filter.
class SlideshowSource {
  final String key;
  final String label;
  final IconData icon;
  final Map<String, String> filter;

  const SlideshowSource(this.key, this.label, this.icon, this.filter);
}

/// Unsplash editorial topics (curated by Unsplash) plus one space collection,
/// since there is no space topic.
const List<SlideshowSource> slideshowSources = [
  SlideshowSource('wallpapers', 'Wallpapers', Icons.wallpaper, {'topics': 'bo8jQKTaE0Y'}),
  SlideshowSource('nature', 'Nature', Icons.landscape, {'topics': '6sMVjTLSkeQ'}),
  SlideshowSource('travel', 'Travel', Icons.flight, {'topics': 'Fzo3zuOHN6w'}),
  SlideshowSource('architecture', 'Architecture', Icons.apartment, {'topics': 'M8jVbLbTRws'}),
  SlideshowSource('3d-renders', '3D Renders', Icons.view_in_ar, {'topics': 'CDwuwXJAbEw'}),
  SlideshowSource('textures', 'Textures', Icons.texture, {'topics': 'iUIsnVtjB0Y'}),
  SlideshowSource('milkyway', 'Milky Way', Icons.auto_awesome, {'collections': '2286207'}),
];

const List<String> defaultDaySlideshowSources = ['nature', 'wallpapers', '3d-renders'];
const List<String> defaultNightSlideshowSources = ['milkyway'];

/// Picks one of the selected categories at random (equal weight per category);
/// falls back to [defaults] when nothing valid is selected.
Map<String, String> pickSlideshowFilter(List<String> selected, List<String> defaults, Random random) {
  var sources = slideshowSources.where((s) => selected.contains(s.key)).toList();
  if (sources.isEmpty) sources = slideshowSources.where((s) => defaults.contains(s.key)).toList();
  return sources[random.nextInt(sources.length)].filter;
}

class UnsplashSlideshow {
  final Directory cacheDir;
  final http.Client _client;

  UnsplashSlideshow(this.cacheDir, {http.Client? client}) : _client = client ?? http.Client();

  /// Downloads a random landscape photo matching [filter] (see [pickSlideshowFilter])
  /// into [cacheDir] and prunes older files. Returns the saved file and its
  /// author, or null on any failure (the caller keeps the current wallpaper).
  Future<(File, String)?> next(Map<String, String> filter, String accessKey) async {
    if (accessKey.isEmpty) return null;
    try {
      final headers = {'Authorization': 'Client-ID $accessKey', 'Accept-Version': 'v1'};
      final meta = await _client.get(
        Uri.https('api.unsplash.com', '/photos/random', {
          ...filter,
          'orientation': 'landscape',
          'content_filter': 'high',
        }),
        headers: headers,
      );
      if (meta.statusCode != 200) return null;
      final photo = UnsplashPhoto.fromJson(jsonDecode(meta.body) as Map<String, dynamic>);

      final image = await _client.get(Uri.parse(photo.imageUrl));
      if (image.statusCode != 200 || image.bodyBytes.isEmpty) return null;

      await cacheDir.create(recursive: true);
      // Write to a temp name first so a half-written file is never displayed.
      final tmp = File("${cacheDir.path}/${photo.id}.part");
      await tmp.writeAsBytes(image.bodyBytes, flush: true);
      final file = await tmp.rename("${cacheDir.path}/${photo.id}.jpg");
      await pruneCache(cacheDir, keep: slideshowMaxCachedFiles);

      // Required by the Unsplash API guidelines when a photo is used.
      _client.get(Uri.parse(photo.downloadLocation), headers: headers).ignore();
      return (file, photo.author);
    } catch (e) {
      debugPrint("Unsplash slideshow: $e");
      return null;
    }
  }
}

/// Deletes all but the [keep] most recent files in [dir], plus leftover temp files.
Future<void> pruneCache(Directory dir, {required int keep}) async {
  if (!await dir.exists()) return;
  final files = await dir.list().where((e) => e is File).cast<File>().toList();
  for (final f in files.where((f) => f.path.endsWith('.part'))) {
    await f.delete();
  }
  final images = files.where((f) => !f.path.endsWith('.part')).toList()
    ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  for (final f in images.skip(keep)) {
    await f.delete();
  }
}

/// Newest cached image, shown at startup before (or without) network access.
File? newestCachedImage(Directory dir) {
  if (!dir.existsSync()) return null;
  final images = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).toList()
    ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return images.isEmpty ? null : images.first;
}
