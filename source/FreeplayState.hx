package;

import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.util.FlxStringUtil;
import lime.utils.Assets;
#if desktop
import Discord.DiscordClient;
#end
using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('backgrounds/SUSSUS AMOGUS'));

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	private var curChar:String = "unknown";

	private var inMainFreeplayState:Bool = false;

	private var currentSongIcon:FlxSprite;

	private var allPossibleSongs:Array<String> = ["Foig", 'Base']; //dfsfsdsfddfssdf

	private var currentPack:Int = 0;

	private var nameAlpha:Alphabet;

	var loadingPack:Bool = false;

	var songColors:Array<FlxColor> = [
    	0xFFca1f6f, // GF
		0xFF4965FF, // DAVE
		0xFF00B515, // MISTER BAMBI RETARD
		0xFF00FFFF //SPLIT THE THONNNNN
    ];

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end
		
		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		bg.loadGraphic(MainMenuState.randomizeBG());
		bg.color = 0xFF4965FF;
		add(bg);

		currentSongIcon = new FlxSprite(0,0).loadGraphic(Paths.image('week_icons_' + (allPossibleSongs[currentPack].toLowerCase())));

		currentSongIcon.centerOffsets(false);
		currentSongIcon.x = (FlxG.width / 2) - 256;
		currentSongIcon.y = (FlxG.height / 2) - 256;
		currentSongIcon.antialiasing = true;

		nameAlpha = new Alphabet(40,(FlxG.height / 2) - 282,allPossibleSongs[currentPack],true,false);
		nameAlpha.screenCenter(X);
		Highscore.load();
		add(nameAlpha);

		add(currentSongIcon);

		super.create();
	}

	public function LoadProperPack()
	{
		switch (allPossibleSongs[currentPack].toLowerCase())
		{
			case 'base':
				addWeek(['Tutorial'], 0, ['gf']);
			case 'foig':
				addWeek(['Overdose'], 1, ['foig']);
				addWeek(['Unfinished-Bantrex-Song'], 1,['bantrex']);
		}
	}

	public function goToActualFreeplay()
	{
		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.itemType = 'D-Shape';
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.y = -200;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		scoreBG.y = -200;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.y = -200;

		add(diffText);

		add(scoreText);

		FlxTween.tween(scoreBG,{y: 0},0.5,{ease: FlxEase.expoInOut});
		FlxTween.tween(scoreText,{y: 5},0.5,{ease: FlxEase.expoInOut});
		FlxTween.tween(diffText,{y: 40},0.5,{ease: FlxEase.expoInOut});

		changeSelection();
		changeDiff();

	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function UpdatePackSelection(change:Int)
	{
		currentPack += change;
		if (currentPack == -1)
		{
			currentPack = allPossibleSongs.length - 1;
		}
		if (currentPack == allPossibleSongs.length)
		{
			currentPack = 0;
		}
		nameAlpha.destroy();
		nameAlpha = new Alphabet(40,(FlxG.height / 2) - 282,allPossibleSongs[currentPack],true,false);
		nameAlpha.screenCenter(X);
		add(nameAlpha);
		currentSongIcon.loadGraphic(Paths.image('week_icons_' + (allPossibleSongs[currentPack].toLowerCase())));
	}

	override function beatHit()
	{
		super.beatHit();
		FlxTween.tween(FlxG.camera, {zoom:1.05}, 0.3, {ease: FlxEase.quadOut, type: BACKWARD});
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	private static var vocals:FlxSound = null;
	override function update(elapsed:Float)
	{
		super.update(elapsed);


		if (!inMainFreeplayState) 
		{
			if (controls.UI_LEFT_P)
			{
				UpdatePackSelection(-1);
			}
			if (controls.UI_RIGHT_P)
			{
				UpdatePackSelection(1);
			}
			if (controls.ACCEPT && !loadingPack)
			{
				loadingPack = true;
				LoadProperPack();
				FlxTween.tween(currentSongIcon, {alpha: 0}, 0.3);
				FlxTween.tween(nameAlpha, {alpha: 0}, 0.3);
				new FlxTimer().start(0.5, function(Dumbshit:FlxTimer)
				{
					currentSongIcon.visible = false;
					nameAlpha.visible = false;
					goToActualFreeplay();
					inMainFreeplayState = true;
					loadingPack = false;
				});
			}
			if (controls.BACK)
			{
				FlxG.switchState(new MainMenuState());
			}	
		
			return;
		}

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}
		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.switchState(new FreeplayState());
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			destroyFreeplayVocals();

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			PlayState.storyWeek = songs[curSelected].week;
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end
		updateDifficultyText();
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function updateDifficultyText()
	{
		switch (songs[curSelected].week)
		{
			default:
				switch (curDifficulty)
				{
					case 0:
						diffText.text = "EASY";
					case 1:
						diffText.text = 'NORMAL';
					case 2:
						diffText.text = "HARD";
					case 3:
						diffText.text = "LEGACY";
				}
		}
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;

		if (curSelected >= songs.length)
			curSelected = 0;

		if (curDifficulty < 0)
			curDifficulty = 2;

		if (curDifficulty > 2)
			curDifficulty = 0;

		if (songs[curSelected].week == 3)
		{
			curDifficulty = 1;
		}

		updateDifficultyText();

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		#if PRELOAD_ALL
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
		FlxTween.color(bg, 0.25, bg.color, songColors[songs[curSelected].week]);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
