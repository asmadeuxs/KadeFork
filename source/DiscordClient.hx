package;

#if hxdiscord_rpc
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

using StringTools;
#end

class DiscordClient {
	// change this to what ever the fuck you want lol
	static final defaultIconName:String = 'default'; // Large Icon image on Discord
	static final defaultLargeImageText:String = "(Temporary) Art by @raincolor__ on Twitter/X";
	static final appID:String = "1494062168033984583"; // ClientID/AppID on Discord Developer Portal

	public static function initialize() {
		#if hxdiscord_rpc
		trace("Discord Client starting...");
		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(appID, cpp.RawPointer.addressOf(handlers), false, null);
		trace("Discord Client started.");
		sys.thread.Thread.create(function():Void {
			while (true) {
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();
				Sys.sleep(2);
			}
			shutdown();
		});
		#end
	}

	public static function shutdown() {
		#if hxdiscord_rpc Discord.Shutdown(); #end
	}

	public static function changePresence(details:String, ?state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
		#if hxdiscord_rpc
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;
		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		final discordPresence:DiscordRichPresence = new DiscordRichPresence();
		discordPresence.type = DiscordActivityType_Playing;
		discordPresence.state = state;
		discordPresence.details = details;
		discordPresence.smallImageKey = smallImageKey;
		discordPresence.largeImageText = defaultLargeImageText;
		discordPresence.largeImageKey = defaultIconName;

		discordPresence.startTimestamp = Std.int(startTimestamp * 0.001);
		discordPresence.endTimestamp = Std.int(endTimestamp * 0.001);

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
		#end
	}

	#if hxdiscord_rpc
	static function onReady(request:cpp.RawConstPointer<DiscordUser>) {
		final username:String = request[0].username;
		final globalName:String = request[0].username;
		final discriminator:Int = Std.parseInt(request[0].discriminator);
		if (discriminator != 0)
			Sys.println('Discord: Connected to user ${username}#${discriminator} ($globalName)');
		else
			Sys.println('Discord: Connected to user @${username} ($globalName)');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
		trace('Error! $errorCode : $message');

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
		trace('Disconnected! $errorCode : $message');
	#end
}
