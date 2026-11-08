package backend;

import haxe.Json;
import openfl.utils.Assets;

typedef VsSongInfo = {
	var name:String;
	var artist:String;
	var album:String;
	var albumKind:String;
	var year:Int;
}

class VsSongCatalog
{
	static var loaded:Bool = false;
	static var songs:Map<String, VsSongInfo> = new Map<String, VsSongInfo>();

	public static function findSong(name:String):Null<VsSongInfo>
	{
		if (!loaded) load();
		return songs.get(normalize(name));
	}

	static function load():Void
	{
		loaded = true;
		for (path in Assets.list())
		{
			var lowerPath:String = path.toLowerCase();
			if (!lowerPath.startsWith("vs_songs/") || !lowerPath.endsWith(".json"))
				continue;

			try
			{
				var document:Dynamic = Json.parse(Assets.getText(path));
				for (artistKey in Reflect.fields(document))
				{
					var artistData:Dynamic = Reflect.field(document, artistKey);
					var albumData:Dynamic = Reflect.field(artistData, "albums");
					if (albumData == null) continue;

					var artistName:String = stringValue(Reflect.field(artistData, "name"), artistKey);
					for (albumKey in Reflect.fields(albumData))
					{
						var album:Dynamic = Reflect.field(albumData, albumKey);
						var trackData:Dynamic = Reflect.field(album, "songs");
						if (trackData == null) continue;

						var albumName:String = stringValue(Reflect.field(album, "title"), albumKey);
					var albumKind:String = stringValue(Reflect.field(album, "kind"), "");
					var albumYear:Int = Std.parseInt(Std.string(Reflect.field(album, "year")));
					if (albumYear == null) albumYear = 0;

					for (trackKey in Reflect.fields(trackData))
					{
						var track:Dynamic = Reflect.field(trackData, trackKey);
						var songInfo:VsSongInfo = {
							name: stringValue(Reflect.field(track, "name"), trackKey),
							artist: artistName,
							album: albumName,
							albumKind: albumKind,
							year: albumYear
						};

						addAlias(Reflect.field(track, "ID"), songInfo);
						addAlias(Reflect.field(track, "SortAs"), songInfo);
						addAlias(albumName + " " + songInfo.name, songInfo);
						addAlias(songInfo.name, songInfo);
						addAlias(trackKey, songInfo);
					}
				}
			}
			catch (error:Dynamic)
			{
				trace('Could not load VS song catalog "$path": $error');
			}
		}
	}

	static function addAlias(alias:Dynamic, songInfo:VsSongInfo):Void
	{
		if (alias == null) return;
		var key:String = normalize(Std.string(alias));
		if (key.length > 0 && !songs.exists(key)) songs.set(key, songInfo);
	}

	static function stringValue(value:Dynamic, fallback:String):String
	{
		return value == null || Std.string(value).length == 0 ? fallback : Std.string(value);
	}

	static function normalize(value:String):String
	{
		return value == null ? "" : ~/[^a-z0-9]/g.replace(value.toLowerCase(), "");
	}
}